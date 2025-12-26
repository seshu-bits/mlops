"""
FastAPI server for heart disease prediction model.

This API exposes a /predict endpoint that accepts patient data and returns
heart disease predictions with confidence scores.
"""
from __future__ import annotations

import pickle
from pathlib import Path
from typing import List, Optional

import numpy as np
import pandas as pd
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

# Initialize FastAPI app
app = FastAPI(
    title="Heart Disease Prediction API",
    description="API for predicting heart disease using machine learning",
    version="1.0.0",
)

# Global variable to store the loaded model
model = None
model_name = None


class PatientData(BaseModel):
    """Input schema for patient data."""
    age: int = Field(..., ge=0, le=120, description="Age in years")
    sex: int = Field(..., ge=0, le=1, description="Sex (1 = male, 0 = female)")
    cp: int = Field(..., ge=1, le=4, description="Chest pain type (1-4)")
    trestbps: int = Field(..., ge=0, description="Resting blood pressure (mm Hg)")
    chol: int = Field(..., ge=0, description="Serum cholesterol (mg/dl)")
    fbs: int = Field(..., ge=0, le=1, description="Fasting blood sugar > 120 mg/dl (1 = true, 0 = false)")
    restecg: int = Field(..., ge=0, le=2, description="Resting ECG results (0-2)")
    thalach: int = Field(..., ge=0, description="Maximum heart rate achieved")
    exang: int = Field(..., ge=0, le=1, description="Exercise induced angina (1 = yes, 0 = no)")
    oldpeak: float = Field(..., ge=0, description="ST depression induced by exercise")
    slope: int = Field(..., ge=1, le=3, description="Slope of peak exercise ST segment (1-3)")
    ca: int = Field(..., ge=0, le=3, description="Number of major vessels colored by fluoroscopy (0-3)")
    thal: int = Field(..., ge=3, le=7, description="Thalassemia (3 = normal, 6 = fixed defect, 7 = reversible defect)")

    class Config:
        schema_extra = {
            "example": {
                "age": 63,
                "sex": 1,
                "cp": 1,
                "trestbps": 145,
                "chol": 233,
                "fbs": 1,
                "restecg": 2,
                "thalach": 150,
                "exang": 0,
                "oldpeak": 2.3,
                "slope": 3,
                "ca": 0,
                "thal": 6
            }
        }


class BatchPatientData(BaseModel):
    """Input schema for batch predictions."""
    patients: List[PatientData]


class PredictionResponse(BaseModel):
    """Output schema for prediction."""
    prediction: int = Field(..., description="Predicted class (0 = no disease, 1 = disease)")
    confidence: float = Field(..., description="Confidence score (probability)")
    model_name: str = Field(..., description="Name of the model used")


class BatchPredictionResponse(BaseModel):
    """Output schema for batch predictions."""
    predictions: List[PredictionResponse]
    count: int


def load_model(model_path: str = "artifacts/logistic_regression.pkl"):
    """Load the trained model from disk."""
    global model, model_name
    
    model_file = Path(model_path)
    if not model_file.exists():
        raise FileNotFoundError(f"Model file not found: {model_path}")
    
    with open(model_file, "rb") as f:
        model = pickle.load(f)
    
    model_name = model_file.stem
    print(f"Model loaded successfully: {model_name}")


@app.on_event("startup")
async def startup_event():
    """Load model on startup."""
    try:
        load_model()
    except Exception as e:
        print(f"Warning: Could not load model on startup: {e}")
        print("Model will need to be loaded manually or predictions will fail.")


@app.get("/")
async def root():
    """Root endpoint with API information."""
    return {
        "message": "Heart Disease Prediction API",
        "version": "1.0.0",
        "model_loaded": model is not None,
        "model_name": model_name if model else None,
        "endpoints": {
            "/predict": "POST - Single prediction",
            "/predict/batch": "POST - Batch predictions",
            "/health": "GET - Health check",
            "/model/info": "GET - Model information"
        }
    }


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "model_loaded": model is not None,
        "model_name": model_name if model else None
    }


@app.get("/model/info")
async def model_info():
    """Get information about the loaded model."""
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    return {
        "model_name": model_name,
        "model_type": type(model).__name__,
        "features": [
            "age", "sex", "cp", "trestbps", "chol", "fbs", "restecg",
            "thalach", "exang", "oldpeak", "slope", "ca", "thal"
        ]
    }


@app.post("/predict", response_model=PredictionResponse)
async def predict(patient: PatientData):
    """
    Predict heart disease for a single patient.
    
    Returns prediction (0 or 1) and confidence score.
    """
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    try:
        # Convert input to DataFrame
        input_data = pd.DataFrame([patient.dict()])
        
        # Make prediction
        prediction = model.predict(input_data)[0]
        
        # Get probability/confidence
        if hasattr(model, "predict_proba"):
            probabilities = model.predict_proba(input_data)[0]
            confidence = float(probabilities[prediction])
        else:
            # For models without predict_proba, use decision function
            if hasattr(model, "decision_function"):
                decision = model.decision_function(input_data)[0]
                confidence = float(1 / (1 + np.exp(-decision)))  # sigmoid
            else:
                confidence = 1.0  # Default if no confidence available
        
        return PredictionResponse(
            prediction=int(prediction),
            confidence=confidence,
            model_name=model_name
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction error: {str(e)}")


@app.post("/predict/batch", response_model=BatchPredictionResponse)
async def predict_batch(batch: BatchPatientData):
    """
    Predict heart disease for multiple patients.
    
    Returns predictions and confidence scores for all patients.
    """
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    try:
        predictions = []
        
        for patient in batch.patients:
            # Convert input to DataFrame
            input_data = pd.DataFrame([patient.dict()])
            
            # Make prediction
            prediction = model.predict(input_data)[0]
            
            # Get probability/confidence
            if hasattr(model, "predict_proba"):
                probabilities = model.predict_proba(input_data)[0]
                confidence = float(probabilities[prediction])
            else:
                if hasattr(model, "decision_function"):
                    decision = model.decision_function(input_data)[0]
                    confidence = float(1 / (1 + np.exp(-decision)))
                else:
                    confidence = 1.0
            
            predictions.append(
                PredictionResponse(
                    prediction=int(prediction),
                    confidence=confidence,
                    model_name=model_name
                )
            )
        
        return BatchPredictionResponse(
            predictions=predictions,
            count=len(predictions)
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Batch prediction error: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
