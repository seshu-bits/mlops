# Heart Disease Prediction API - Docker Deployment

This directory contains a FastAPI-based REST API for heart disease prediction, packaged as a Docker container.

## 🚀 Quick Start

### Prerequisites
- Docker installed on your machine
- A trained model file in `artifacts/logistic_regression.pkl`

### Step 1: Build the Docker Image

```bash
cd Assignment
docker build -t heart-disease-api:latest .
```

### Step 2: Run the Container

```bash
docker run -d -p 8000:8000 --name heart-api heart-disease-api:latest
```

### Step 3: Test the API

Open your browser and go to:
- API Documentation: http://localhost:8000/docs
- Alternative Docs: http://localhost:8000/redoc
- Health Check: http://localhost:8000/health

Or run the test script:
```bash
pip install requests
python integration_tests/test_api.py
```

## 📡 API Endpoints

### 1. Root Endpoint
- **URL**: `GET /`
- **Description**: API information and available endpoints

### 2. Health Check
- **URL**: `GET /health`
- **Description**: Check if the API is running and model is loaded

### 3. Model Information
- **URL**: `GET /model/info`
- **Description**: Get information about the loaded model

### 4. Single Prediction
- **URL**: `POST /predict`
- **Description**: Predict heart disease for a single patient
- **Request Body**:
```json
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
  "thal": 6
}
```
- **Response**:
```json
{
  "prediction": 0,
  "confidence": 0.85,
  "model_name": "logistic_regression"
}
```

### 5. Batch Prediction
- **URL**: `POST /predict/batch`
- **Description**: Predict heart disease for multiple patients
- **Request Body**:
```json
{
  "patients": [
    {
      "age": 63,
      "sex": 1,
      "cp": 1,
      ...
    },
    {
      "age": 67,
      "sex": 1,
      "cp": 4,
      ...
    }
  ]
}
```

## 🧪 Testing with cURL

### Single Prediction
```bash
curl -X POST "http://localhost:8000/predict" \
  -H "Content-Type: application/json" \
  -d '{
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
  }'
```

### Health Check
```bash
curl http://localhost:8000/health
```

## 🐳 Docker Commands

### Build the image
```bash
docker build -t heart-disease-api:latest .
```

### Run the container
```bash
# Run in background
docker run -d -p 8000:8000 --name heart-api heart-disease-api:latest

# Run with logs visible
docker run -p 8000:8000 --name heart-api heart-disease-api:latest
```

### View logs
```bash
docker logs heart-api
```

### Stop the container
```bash
docker stop heart-api
```

### Remove the container
```bash
docker rm heart-api
```

### Access container shell
```bash
docker exec -it heart-api /bin/bash
```

## 📊 Feature Descriptions

| Feature | Description | Range |
|---------|-------------|-------|
| age | Age in years | 0-120 |
| sex | Sex (1 = male, 0 = female) | 0-1 |
| cp | Chest pain type | 1-4 |
| trestbps | Resting blood pressure (mm Hg) | 0+ |
| chol | Serum cholesterol (mg/dl) | 0+ |
| fbs | Fasting blood sugar > 120 mg/dl | 0-1 |
| restecg | Resting ECG results | 0-2 |
| thalach | Maximum heart rate achieved | 0+ |
| exang | Exercise induced angina | 0-1 |
| oldpeak | ST depression induced by exercise | 0+ |
| slope | Slope of peak exercise ST segment | 1-3 |
| ca | Number of major vessels (0-3) | 0-3 |
| thal | Thalassemia | 3, 6, 7 |

## 🔧 Troubleshooting

### Port already in use
```bash
# Find and kill process using port 8000
lsof -ti:8000 | xargs kill -9

# Or use a different port
docker run -p 8080:8000 --name heart-api heart-disease-api:latest
```

### Model not found
Make sure you have a trained model in `artifacts/logistic_regression.pkl` before building the Docker image.

### Container won't start
Check the logs:
```bash
docker logs heart-api
```

## 🎯 Response Codes

- `200`: Success
- `422`: Validation Error (invalid input)
- `500`: Server Error (prediction failed)
- `503`: Service Unavailable (model not loaded)

## 📦 Dependencies

The API uses:
- **FastAPI**: Modern web framework
- **Uvicorn**: ASGI server
- **Pydantic**: Data validation
- **scikit-learn**: Machine learning model
- **pandas**: Data manipulation
- **numpy**: Numerical operations
