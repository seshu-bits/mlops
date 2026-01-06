"""
Unit tests for api_server.py

These tests mock the model and scaler to test API endpoints without
requiring actual trained models.
"""

import os
import sys
from pathlib import Path
from unittest.mock import Mock, mock_open, patch

import numpy as np
import pandas as pd
import pytest

# Add parent directory to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

# Set environment variable to disable model loading during tests
os.environ["TESTING"] = "1"

from fastapi.testclient import TestClient

# Now we can safely import api_server
import api_server


@pytest.fixture
def mock_model():
    """Create a mock model for testing."""
    model = Mock()
    model.predict = Mock(return_value=np.array([1]))
    model.predict_proba = Mock(return_value=np.array([[0.3, 0.7]]))
    model.__class__.__name__ = "LogisticRegression"
    return model


@pytest.fixture
def mock_scaler():
    """Create a mock scaler for testing."""
    scaler = Mock()
    scaler.transform = Mock(side_effect=lambda x: x)  # Identity transform
    scaler.mean_ = np.array([0.0] * 13)  # 13 features
    return scaler


@pytest.fixture
def client(mock_model, mock_scaler):
    """Create a test client with mocked model."""
    # Set the mock model and scaler directly on the api_server module
    api_server.model = mock_model
    api_server.scaler = mock_scaler
    api_server.model_name = "test_model"
    
    return TestClient(api_server.app)


def test_root_endpoint(client):
    """Test root endpoint returns correct information."""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
    assert "version" in data
    assert "endpoints" in data
    assert data["model_loaded"] is True


def test_health_check(client):
    """Test health check endpoint."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["model_loaded"] is True


def test_model_info(client):
    """Test model info endpoint."""
    response = client.get("/model/info")
    assert response.status_code == 200
    data = response.json()
    assert "model_name" in data
    assert "model_type" in data
    assert "features" in data
    assert len(data["features"]) == 13


def test_model_info_no_model():
    """Test model info when model is not loaded."""
    with patch("api_server.model", None):
        from api_server import app

        client = TestClient(app)
        response = client.get("/model/info")
        assert response.status_code == 503


def test_predict_single_patient(client, mock_model):
    """Test single patient prediction."""
    patient_data = {
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
        "thal": 6,
    }

    response = client.post("/predict", json=patient_data)
    assert response.status_code == 200
    data = response.json()
    assert "prediction" in data
    assert "confidence" in data
    assert "model_name" in data
    assert data["prediction"] in [0, 1]
    assert 0 <= data["confidence"] <= 1

    # Verify model was called
    assert mock_model.predict.called


def test_predict_with_preprocessing(client, mock_scaler):
    """Test that preprocessing is applied before prediction."""
    patient_data = {
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
        "thal": 6,
    }

    response = client.post("/predict", json=patient_data)
    assert response.status_code == 200

    # Verify scaler was called
    assert mock_scaler.transform.called


def test_predict_invalid_data(client):
    """Test prediction with invalid data."""
    invalid_data = {
        "age": -5,  # Invalid age
        "sex": 1,
    }

    response = client.post("/predict", json=invalid_data)
    assert response.status_code == 422  # Validation error


def test_predict_missing_fields(client):
    """Test prediction with missing required fields."""
    incomplete_data = {
        "age": 63,
        "sex": 1,
        # Missing other required fields
    }

    response = client.post("/predict", json=incomplete_data)
    assert response.status_code == 422


def test_predict_no_model():
    """Test prediction when model is not loaded."""
    with patch("api_server.model", None):
        from api_server import app

        client = TestClient(app)
        patient_data = {
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
            "thal": 6,
        }
        response = client.post("/predict", json=patient_data)
        assert response.status_code == 503


def test_batch_predict(client, mock_model):
    """Test batch prediction endpoint."""
    batch_data = {
        "patients": [
            {
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
                "thal": 6,
            },
            {
                "age": 67,
                "sex": 1,
                "cp": 4,
                "trestbps": 160,
                "chol": 286,
                "fbs": 0,
                "restecg": 2,
                "thalach": 108,
                "exang": 1,
                "oldpeak": 1.5,
                "slope": 2,
                "ca": 3,
                "thal": 3,
            },
        ]
    }

    response = client.post("/predict/batch", json=batch_data)
    assert response.status_code == 200
    data = response.json()
    assert "predictions" in data
    assert "count" in data
    assert data["count"] == 2
    assert len(data["predictions"]) == 2


def test_batch_predict_empty_list(client):
    """Test batch prediction with empty patient list."""
    batch_data = {"patients": []}

    response = client.post("/predict/batch", json=batch_data)
    assert response.status_code == 200
    data = response.json()
    assert data["count"] == 0


def test_model_loading():
    """Test model loading function."""
    mock_model_data = b"mock_model_data"
    mock_scaler_data = b"mock_scaler_data"

    with patch("builtins.open", mock_open(read_data=mock_model_data)), patch(
        "pickle.load", side_effect=[Mock(), Mock()]
    ), patch("pathlib.Path.exists", return_value=True):

        from api_server import load_model

        # Should not raise exception
        load_model("test_model.pkl")


def test_model_loading_missing_file():
    """Test model loading with missing model file."""
    with patch("pathlib.Path.exists", return_value=False):
        from api_server import load_model

        with pytest.raises(FileNotFoundError):
            load_model("nonexistent_model.pkl")


def test_model_loading_missing_scaler():
    """Test model loading when scaler file is missing."""
    mock_model_data = b"mock_model_data"

    def side_effect_exists(path):
        # Model file exists, scaler doesn't
        if "scaler" in str(path):
            return False
        return True

    with patch("builtins.open", mock_open(read_data=mock_model_data)), patch(
        "pickle.load", return_value=Mock()
    ), patch("pathlib.Path.exists", side_effect=side_effect_exists):

        from api_server import load_model

        # Should not raise exception, just log warning
        load_model("test_model.pkl")


def test_predict_model_without_predict_proba(client):
    """Test prediction with model that doesn't have predict_proba."""
    mock_model_no_proba = Mock()
    mock_model_no_proba.predict = Mock(return_value=np.array([1]))
    del mock_model_no_proba.predict_proba  # Remove attribute
    mock_model_no_proba.decision_function = Mock(return_value=np.array([0.5]))

    with patch("api_server.model", mock_model_no_proba):
        patient_data = {
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
            "thal": 6,
        }
        from api_server import app

        client = TestClient(app)
        response = client.post("/predict", json=patient_data)
        assert response.status_code == 200


def test_metrics_endpoint(client):
    """Test Prometheus metrics endpoint."""
    response = client.get("/metrics")
    assert response.status_code == 200
    assert "text/plain" in response.headers["content-type"]


def test_prediction_confidence_range(client, mock_model):
    """Test that confidence scores are in valid range [0, 1]."""
    # Test with various probability values
    for prob in [0.1, 0.5, 0.9, 0.99]:
        mock_model.predict_proba = Mock(return_value=np.array([[1 - prob, prob]]))
        mock_model.predict = Mock(return_value=np.array([1]))

        patient_data = {
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
            "thal": 6,
        }

        response = client.post("/predict", json=patient_data)
        assert response.status_code == 200
        data = response.json()
        assert 0 <= data["confidence"] <= 1


def test_edge_case_boundary_values(client):
    """Test prediction with boundary values."""
    # Test with maximum valid values
    patient_data = {
        "age": 120,  # Max age
        "sex": 1,
        "cp": 4,  # Max cp
        "trestbps": 300,  # High bp
        "chol": 600,  # High cholesterol
        "fbs": 1,
        "restecg": 2,
        "thalach": 250,  # Max heart rate
        "exang": 1,
        "oldpeak": 10.0,  # Max oldpeak
        "slope": 3,
        "ca": 3,  # Max ca
        "thal": 7,  # Max thal
    }

    response = client.post("/predict", json=patient_data)
    assert response.status_code == 200


def test_edge_case_minimum_values(client):
    """Test prediction with minimum valid values."""
    patient_data = {
        "age": 0,  # Min age
        "sex": 0,
        "cp": 1,  # Min cp
        "trestbps": 0,
        "chol": 0,
        "fbs": 0,
        "restecg": 0,
        "thalach": 0,
        "exang": 0,
        "oldpeak": 0.0,
        "slope": 1,
        "ca": 0,
        "thal": 3,  # Min thal
    }

    response = client.post("/predict", json=patient_data)
    assert response.status_code == 200
