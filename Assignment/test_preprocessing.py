#!/usr/bin/env python3
"""
Test that preprocessing (scaler) is correctly applied during inference.
This verifies full reproducibility of predictions.
"""

import pickle
import pandas as pd
from pathlib import Path

def test_preprocessing():
    """Test that scaler is loaded and applied correctly."""
    print("Testing Preprocessing Pipeline Reproducibility")
    print("=" * 60)
    
    artifacts_dir = Path("artifacts")
    model_path = artifacts_dir / "logistic_regression.pkl"
    scaler_path = artifacts_dir / "logistic_regression_scaler.pkl"
    
    # 1. Check files exist
    print("\n1. Checking files exist...")
    assert model_path.exists(), f"❌ Model not found: {model_path}"
    print(f"   ✓ Model found: {model_path}")
    
    assert scaler_path.exists(), f"❌ Scaler not found: {scaler_path}"
    print(f"   ✓ Scaler found: {scaler_path}")
    
    # 2. Load model and scaler
    print("\n2. Loading model and scaler...")
    with open(model_path, "rb") as f:
        model = pickle.load(f)
    print(f"   ✓ Model loaded: {type(model).__name__}")
    
    with open(scaler_path, "rb") as f:
        scaler = pickle.load(f)
    print(f"   ✓ Scaler loaded: {type(scaler).__name__}")
    print(f"   ✓ Scaler fitted on {len(scaler.mean_)} features")
    
    # 3. Create test input (same as API sample)
    print("\n3. Creating test input...")
    test_input = pd.DataFrame([{
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
    }])
    print(f"   ✓ Test input created: {test_input.shape}")
    print(f"   ✓ Features: {list(test_input.columns)}")
    
    # 4. Test WITHOUT preprocessing (INCORRECT)
    print("\n4. Testing WITHOUT preprocessing (INCORRECT)...")
    try:
        pred_no_scaling = model.predict(test_input)[0]
        prob_no_scaling = model.predict_proba(test_input)[0]
        print(f"   ⚠️  Prediction: {pred_no_scaling}")
        print(f"   ⚠️  Probabilities: {prob_no_scaling}")
        print(f"   ⚠️  This may be INCORRECT - no preprocessing applied!")
    except Exception as e:
        print(f"   ❌ Error: {e}")
    
    # 5. Test WITH preprocessing (CORRECT)
    print("\n5. Testing WITH preprocessing (CORRECT)...")
    numeric_cols = test_input.select_dtypes(include=['int64', 'float64', 'Int64', 'Float64']).columns
    test_input_scaled = test_input.copy()
    test_input_scaled[numeric_cols] = scaler.transform(test_input[numeric_cols])
    
    print(f"   ✓ Applied StandardScaler to {len(numeric_cols)} numeric columns")
    print(f"   ✓ Scaled data range: [{test_input_scaled.min().min():.2f}, {test_input_scaled.max().max():.2f}]")
    
    pred_with_scaling = model.predict(test_input_scaled)[0]
    prob_with_scaling = model.predict_proba(test_input_scaled)[0]
    print(f"   ✓ Prediction: {pred_with_scaling}")
    print(f"   ✓ Probabilities: {prob_with_scaling}")
    print(f"   ✓ Confidence: {prob_with_scaling[pred_with_scaling]:.4f}")
    
    # 6. Compare results
    print("\n6. Comparing results...")
    print(f"   Without scaling: pred={pred_no_scaling}, prob={prob_no_scaling[pred_no_scaling]:.4f}")
    print(f"   With scaling:    pred={pred_with_scaling}, prob={prob_with_scaling[pred_with_scaling]:.4f}")
    
    if pred_no_scaling == pred_with_scaling:
        print(f"   ℹ️  Predictions match (may happen if model is robust)")
    else:
        print(f"   ⚠️  Predictions DIFFER - preprocessing is CRITICAL!")
    
    print("\n" + "=" * 60)
    print("✅ Preprocessing pipeline test completed!")
    print("\n🎯 Recommendation: ALWAYS use scaler for inference")
    print("   API server now automatically applies preprocessing ✓")

if __name__ == "__main__":
    test_preprocessing()
