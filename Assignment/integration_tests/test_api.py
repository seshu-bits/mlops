"""
Integration test script for the Heart Disease Prediction API.

⚠️ IMPORTANT: This is NOT a unit test!
This script requires a running API server at http://localhost:8000

To use this script:
1. First, start the API server:
   - Using Docker: docker run -d -p 8000:8000 --name heart-api heart-disease-api:latest
   - Or locally: cd Assignment && uvicorn api_server:app --host 0.0.0.0 --port 8000

2. Then run this script:
   python integration_tests/test_api.py

This script tests the API endpoints with sample data and is meant for
manual integration testing, not automated CI/CD pipelines.
"""
import requests
import json
import sys

# API base URL
BASE_URL = "http://localhost:8000"

# Sample patient data
sample_patient = {
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

# Sample batch data
batch_patients = {
    "patients": [
        sample_patient,
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
            "thal": 3
        }
    ]
}


def test_root():
    """Test root endpoint."""
    print("\n" + "="*60)
    print("Testing Root Endpoint")
    print("="*60)
    
    response = requests.get(f"{BASE_URL}/")
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 200


def test_health():
    """Test health check endpoint."""
    print("\n" + "="*60)
    print("Testing Health Check Endpoint")
    print("="*60)
    
    response = requests.get(f"{BASE_URL}/health")
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 200


def test_model_info():
    """Test model info endpoint."""
    print("\n" + "="*60)
    print("Testing Model Info Endpoint")
    print("="*60)
    
    response = requests.get(f"{BASE_URL}/model/info")
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 200


def test_single_prediction():
    """Test single prediction endpoint."""
    print("\n" + "="*60)
    print("Testing Single Prediction Endpoint")
    print("="*60)
    print(f"Input: {json.dumps(sample_patient, indent=2)}")
    
    response = requests.post(
        f"{BASE_URL}/predict",
        json=sample_patient,
        headers={"Content-Type": "application/json"}
    )
    
    print(f"\nStatus Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    
    if response.status_code == 200:
        result = response.json()
        print(f"\n🏥 Prediction: {'Heart Disease' if result['prediction'] == 1 else 'No Heart Disease'}")
        print(f"📊 Confidence: {result['confidence']:.2%}")
        print(f"🤖 Model: {result['model_name']}")
    
    return response.status_code == 200


def test_batch_prediction():
    """Test batch prediction endpoint."""
    print("\n" + "="*60)
    print("Testing Batch Prediction Endpoint")
    print("="*60)
    print(f"Number of patients: {len(batch_patients['patients'])}")
    
    response = requests.post(
        f"{BASE_URL}/predict/batch",
        json=batch_patients,
        headers={"Content-Type": "application/json"}
    )
    
    print(f"\nStatus Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    
    if response.status_code == 200:
        result = response.json()
        print(f"\n📊 Batch Results (Total: {result['count']})")
        for i, pred in enumerate(result['predictions'], 1):
            disease_status = 'Heart Disease' if pred['prediction'] == 1 else 'No Heart Disease'
            print(f"  Patient {i}: {disease_status} (Confidence: {pred['confidence']:.2%})")
    
    return response.status_code == 200


def main():
    """Run all API tests."""
    print("\n" + "🚀"*30)
    print("Starting API Tests")
    print("🚀"*30)
    
    tests = [
        ("Root Endpoint", test_root),
        ("Health Check", test_health),
        ("Model Info", test_model_info),
        ("Single Prediction", test_single_prediction),
        ("Batch Prediction", test_batch_prediction),
    ]
    
    results = {}
    for test_name, test_func in tests:
        try:
            results[test_name] = test_func()
        except Exception as e:
            print(f"\n❌ Error in {test_name}: {str(e)}")
            results[test_name] = False
    
    # Summary
    print("\n" + "="*60)
    print("Test Summary")
    print("="*60)
    for test_name, passed in results.items():
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{status} - {test_name}")
    
    total = len(results)
    passed = sum(results.values())
    print(f"\nTotal: {passed}/{total} tests passed")
    
    return all(results.values())


if __name__ == "__main__":
    try:
        success = main()
        exit(0 if success else 1)
    except requests.exceptions.ConnectionError:
        print("\n❌ Error: Could not connect to API server.")
        print("Make sure the server is running at", BASE_URL)
        exit(1)
