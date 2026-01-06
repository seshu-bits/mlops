"""
FastAPI server for heart disease prediction model.

This API exposes a /predict endpoint that accepts patient data and returns
heart disease predictions with confidence scores.

Includes Prometheus metrics for monitoring and observability.
"""
from __future__ import annotations

import logging
import pickle
import time
from pathlib import Path
from typing import List, Optional

import numpy as np
import pandas as pd
from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel, Field
from prometheus_client import Counter, Histogram, Gauge, Info, generate_latest, CONTENT_TYPE_LATEST
from starlette.responses import Response
from starlette.middleware.base import BaseHTTPMiddleware

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Prometheus Metrics
# Counter for total requests
request_count = Counter(
    'api_requests_total',
    'Total number of API requests',
    ['method', 'endpoint', 'status_code']
)

# Counter for predictions
prediction_count = Counter(
    'predictions_total',
    'Total number of predictions made',
    ['prediction_result', 'model_name']
)

# Histogram for request duration
request_duration = Histogram(
    'api_request_duration_seconds',
    'Request duration in seconds',
    ['method', 'endpoint']
)

# Histogram for prediction latency
prediction_latency = Histogram(
    'prediction_duration_seconds',
    'Prediction processing time in seconds',
    ['endpoint']
)

# Histogram for confidence scores
confidence_scores = Histogram(
    'prediction_confidence_score',
    'Confidence scores of predictions',
    ['prediction_result'],
    buckets=[0.5, 0.6, 0.7, 0.8, 0.9, 0.95, 0.99, 1.0]
)

# Gauge for model health
model_loaded = Gauge('model_loaded', 'Whether the model is loaded (1) or not (0)')

# Gauge for active requests
active_requests = Gauge('active_requests', 'Number of requests currently being processed')

# Info metric for model information
model_info_metric = Info('model_info', 'Information about the loaded model')

# Counter for errors
error_count = Counter(
    'api_errors_total',
    'Total number of errors',
    ['error_type', 'endpoint']
)

# Middleware for Prometheus metrics
class PrometheusMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        # Skip metrics endpoint to avoid circular tracking
        if request.url.path == "/metrics":
            return await call_next(request)
        
        # Track active requests
        active_requests.inc()
        
        # Record start time
        start_time = time.time()
        
        # Get method and path
        method = request.method
        path = request.url.path
        
        try:
            # Process request
            response = await call_next(request)
            
            # Record metrics
            duration = time.time() - start_time
            status_code = response.status_code
            
            request_count.labels(method=method, endpoint=path, status_code=status_code).inc()
            request_duration.labels(method=method, endpoint=path).observe(duration)
            
            # Log request
            logger.info(f"{method} {path} - Status: {status_code} - Duration: {duration:.3f}s")
            
            return response
            
        except Exception as e:
            # Record error
            duration = time.time() - start_time
            error_count.labels(error_type=type(e).__name__, endpoint=path).inc()
            request_count.labels(method=method, endpoint=path, status_code=500).inc()
            request_duration.labels(method=method, endpoint=path).observe(duration)
            
            logger.error(f"{method} {path} - Error: {str(e)} - Duration: {duration:.3f}s")
            raise
        
        finally:
            # Decrease active requests
            active_requests.dec()


# Initialize FastAPI app
app = FastAPI(
    title="Heart Disease Prediction API",
    description="API for predicting heart disease using machine learning. Includes Prometheus metrics for monitoring.",
    version="1.0.0",
)

# Add Prometheus middleware
app.add_middleware(PrometheusMiddleware)

# Global variable to store the loaded model
model = None
model_name = None
scaler = None  # Preprocessing scaler for reproducibility


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
    global model, model_name, scaler
    
    model_file = Path(model_path)
    if not model_file.exists():
        logger.error(f"Model file not found: {model_path}")
        model_loaded.set(0)
        raise FileNotFoundError(f"Model file not found: {model_path}")
    
    with open(model_file, "rb") as f:
        model = pickle.load(f)
    
    model_name = model_file.stem
    logger.info(f"Model loaded successfully: {model_name}")
    
    # Load preprocessing scaler for reproducibility
    scaler_path = model_file.parent / f"{model_file.stem}_scaler.pkl"
    if scaler_path.exists():
        with open(scaler_path, "rb") as f:
            scaler = pickle.load(f)
        logger.info(f"Scaler loaded successfully: {scaler_path.name}")
    else:
        logger.warning(f"No scaler found at {scaler_path} - predictions may be incorrect without preprocessing!")
        scaler = None
    
    # Update Prometheus metrics
    model_loaded.set(1)
    model_info_metric.info({
        'model_name': model_name,
        'model_type': type(model).__name__,
        'model_path': str(model_path)
    })


@app.on_event("startup")
async def startup_event():
    """Load model on startup."""
    try:
        load_model()
        logger.info("API startup complete - model loaded successfully")
    except Exception as e:
        logger.warning(f"Could not load model on startup: {e}")
        logger.warning("Model will need to be loaded manually or predictions will fail.")
        error_count.labels(error_type="ModelLoadError", endpoint="/startup").inc()


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
            "/model/info": "GET - Model information",
            "/metrics": "GET - Prometheus metrics"
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


@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint."""
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.post("/predict", response_model=PredictionResponse)
async def predict(patient: PatientData):
    """
    Predict heart disease for a single patient.
    
    Returns prediction (0 or 1) and confidence score.
    """
    if model is None:
        logger.error("Prediction attempted with no model loaded")
        error_count.labels(error_type="ModelNotLoaded", endpoint="/predict").inc()
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    # Track prediction latency
    start_time = time.time()
    
    try:
        # Convert input to DataFrame
        input_data = pd.DataFrame([patient.dict()])
        
        # Apply preprocessing for reproducibility (CRITICAL for correct predictions)
        if scaler is not None:
            numeric_cols = input_data.select_dtypes(include=['int64', 'float64', 'Int64', 'Float64']).columns
            if len(numeric_cols) > 0:
                input_data[numeric_cols] = scaler.transform(input_data[numeric_cols])
        
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
        
        # Record prediction metrics
        prediction_result = "disease" if prediction == 1 else "no_disease"
        prediction_count.labels(prediction_result=prediction_result, model_name=model_name).inc()
        confidence_scores.labels(prediction_result=prediction_result).observe(confidence)
        
        # Record latency
        duration = time.time() - start_time
        prediction_latency.labels(endpoint="/predict").observe(duration)
        
        logger.info(f"Prediction made: {prediction_result}, confidence: {confidence:.3f}, duration: {duration:.3f}s")
        
        return PredictionResponse(
            prediction=int(prediction),
            confidence=confidence,
            model_name=model_name
        )
    
    except Exception as e:
        duration = time.time() - start_time
        prediction_latency.labels(endpoint="/predict").observe(duration)
        error_count.labels(error_type=type(e).__name__, endpoint="/predict").inc()
        logger.error(f"Prediction error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Prediction error: {str(e)}")


@app.post("/predict/batch", response_model=BatchPredictionResponse)
async def predict_batch(batch: BatchPatientData):
    """
    Predict heart disease for multiple patients.
    
    Returns predictions and confidence scores for all patients.
    """
    if model is None:
        logger.error("Batch prediction attempted with no model loaded")
        error_count.labels(error_type="ModelNotLoaded", endpoint="/predict/batch").inc()
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    # Track prediction latency
    start_time = time.time()
    batch_size = len(batch.patients)
    
    try:
        predictions = []
        
        for patient in batch.patients:
            # Convert input to DataFrame
            input_data = pd.DataFrame([patient.dict()])
            
            # Apply preprocessing for reproducibility (CRITICAL for correct predictions)
            if scaler is not None:
                numeric_cols = input_data.select_dtypes(include=['int64', 'float64', 'Int64', 'Float64']).columns
                if len(numeric_cols) > 0:
                    input_data[numeric_cols] = scaler.transform(input_data[numeric_cols])
            
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
            
            # Record metrics for each prediction
            prediction_result = "disease" if prediction == 1 else "no_disease"
            prediction_count.labels(prediction_result=prediction_result, model_name=model_name).inc()
            confidence_scores.labels(prediction_result=prediction_result).observe(confidence)
            
            predictions.append(
                PredictionResponse(
                    prediction=int(prediction),
                    confidence=confidence,
                    model_name=model_name
                )
            )
        
        # Record batch latency
        duration = time.time() - start_time
        prediction_latency.labels(endpoint="/predict/batch").observe(duration)
        
        logger.info(f"Batch prediction complete: {batch_size} patients, duration: {duration:.3f}s")
        
        return BatchPredictionResponse(
            predictions=predictions,
            count=len(predictions)
        )
    
    except Exception as e:
        duration = time.time() - start_time
        prediction_latency.labels(endpoint="/predict/batch").observe(duration)
        error_count.labels(error_type=type(e).__name__, endpoint="/predict/batch").inc()
        logger.error(f"Batch prediction error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Batch prediction error: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
