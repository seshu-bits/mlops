# 🐳 Heart Disease Prediction API - Docker Deployment Guide

## 📋 Complete Setup Instructions

This guide provides step-by-step instructions to build, run, and test the Heart Disease Prediction API Docker container.

---

## ✅ Prerequisites

1. **Docker Desktop** installed and running
   - Download from: https://www.docker.com/products/docker-desktop
   - Verify installation: `docker --version`

2. **Python 3.8+** (for testing the API)
   - Verify: `python --version`

3. **Trained Model** 
   - Should exist at: `Assignment/artifacts/logistic_regression.pkl`
   - If not, run the training first: `cd Assignment && python MLOps_Assignment.py`

---

## 🚀 Quick Start (3 Steps)

### Step 1: Build the Docker Image

```bash
cd Assignment
docker build -t heart-disease-api:latest .
```

**Expected output:**
```
[+] Building 45.2s (12/12) FINISHED
 => [internal] load build definition from Dockerfile
 => => transferring dockerfile: 537B
 => [internal] load .dockerignore
 ...
 => => naming to docker.io/library/heart-disease-api:latest
```

**Verify the image was created:**
```bash
docker images | grep heart-disease-api
```

### Step 2: Run the Container

```bash
docker run -d -p 8000:8000 --name heart-api heart-disease-api:latest
```

**Alternative: Run with logs visible**
```bash
docker run -p 8000:8000 --name heart-api heart-disease-api:latest
```

**Verify the container is running:**
```bash
docker ps | grep heart-api
```

### Step 3: Test the API

**Option A: Using the automated test script**
```bash
# Make sure the API server is running first!
pip install requests
python integration_tests/test_api.py
```

**Option B: Using cURL**
```bash
# Health check
curl http://localhost:8000/health

# Single prediction
curl -X POST "http://localhost:8000/predict" \
  -H "Content-Type: application/json" \
  -d @sample_input.json
```

**Option C: Using a web browser**
- Interactive API docs: http://localhost:8000/docs
- Alternative docs: http://localhost:8000/redoc

---

## 📡 API Endpoints Reference

### 1. Root Endpoint
```bash
curl http://localhost:8000/
```
**Response:**
```json
{
  "message": "Heart Disease Prediction API",
  "version": "1.0.0",
  "model_loaded": true,
  "model_name": "logistic_regression",
  "endpoints": {
    "/predict": "POST - Single prediction",
    "/predict/batch": "POST - Batch predictions",
    "/health": "GET - Health check",
    "/model/info": "GET - Model information"
  }
}
```

### 2. Health Check
```bash
curl http://localhost:8000/health
```
**Response:**
```json
{
  "status": "healthy",
  "model_loaded": true,
  "model_name": "logistic_regression"
}
```

### 3. Model Information
```bash
curl http://localhost:8000/model/info
```
**Response:**
```json
{
  "model_name": "logistic_regression",
  "model_type": "LogisticRegression",
  "features": ["age", "sex", "cp", "trestbps", ...]
}
```

### 4. Single Prediction ⭐
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
**Response:**
```json
{
  "prediction": 0,
  "confidence": 0.8523,
  "model_name": "logistic_regression"
}
```

- **prediction**: 0 = No Heart Disease, 1 = Heart Disease
- **confidence**: Probability score (0.0 to 1.0)

### 5. Batch Prediction
```bash
curl -X POST "http://localhost:8000/predict/batch" \
  -H "Content-Type: application/json" \
  -d @sample_batch_input.json
```
**Response:**
```json
{
  "predictions": [
    {
      "prediction": 0,
      "confidence": 0.8523,
      "model_name": "logistic_regression"
    },
    {
      "prediction": 1,
      "confidence": 0.7891,
      "model_name": "logistic_regression"
    }
  ],
  "count": 2
}
```

---

## 🧪 Complete Testing Examples

### Test 1: Automated Test Script
```bash
# Make sure the container is running first
python integration_tests/test_api.py
```
**Output:**
```
🚀🚀🚀...
Starting API Tests
...
Testing Single Prediction Endpoint
...
🏥 Prediction: No Heart Disease
📊 Confidence: 85.23%
🤖 Model: logistic_regression

Test Summary
✅ PASS - Root Endpoint
✅ PASS - Health Check
✅ PASS - Model Info
✅ PASS - Single Prediction
✅ PASS - Batch Prediction

Total: 5/5 tests passed
```

### Test 2: Sample Input File
```bash
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d @sample_input.json
```

### Test 3: Interactive Documentation
1. Open browser: http://localhost:8000/docs
2. Click on `/predict` endpoint
3. Click "Try it out"
4. Enter sample data
5. Click "Execute"
6. View response

---

## 🔧 Docker Management Commands

### Container Management
```bash
# View running containers
docker ps

# View all containers (including stopped)
docker ps -a

# View container logs
docker logs heart-api

# Follow logs in real-time
docker logs -f heart-api

# Stop the container
docker stop heart-api

# Start a stopped container
docker start heart-api

# Restart the container
docker restart heart-api

# Remove the container
docker rm heart-api

# Force remove a running container
docker rm -f heart-api
```

### Image Management
```bash
# List all images
docker images

# Remove the image
docker rmi heart-disease-api:latest

# View image details
docker inspect heart-disease-api:latest

# View image history
docker history heart-disease-api:latest
```

### Debugging
```bash
# Access container shell
docker exec -it heart-api /bin/bash

# View container resource usage
docker stats heart-api

# View container processes
docker top heart-api

# Check container health
docker inspect --format='{{.State.Health.Status}}' heart-api
```

---

## 📊 Input Feature Reference

| Feature | Description | Type | Range | Example |
|---------|-------------|------|-------|---------|
| age | Age in years | int | 0-120 | 63 |
| sex | Sex | int | 0-1 | 1 (male) |
| cp | Chest pain type | int | 1-4 | 1 |
| trestbps | Resting blood pressure (mm Hg) | int | 0+ | 145 |
| chol | Serum cholesterol (mg/dl) | int | 0+ | 233 |
| fbs | Fasting blood sugar > 120 mg/dl | int | 0-1 | 1 (true) |
| restecg | Resting ECG results | int | 0-2 | 2 |
| thalach | Maximum heart rate achieved | int | 0+ | 150 |
| exang | Exercise induced angina | int | 0-1 | 0 (no) |
| oldpeak | ST depression | float | 0+ | 2.3 |
| slope | Slope of peak exercise ST | int | 1-3 | 3 |
| ca | Number of major vessels | int | 0-3 | 0 |
| thal | Thalassemia | int | 3,6,7 | 6 |

---

## 🐛 Troubleshooting

### Problem: Port 8000 already in use
```bash
# Option 1: Use a different port
docker run -d -p 8080:8000 --name heart-api heart-disease-api:latest

# Option 2: Find and kill process using port 8000
lsof -ti:8000 | xargs kill -9
```

### Problem: Container exits immediately
```bash
# Check logs for errors
docker logs heart-api

# Run with logs visible
docker run -p 8000:8000 --name heart-api heart-disease-api:latest
```

### Problem: Model not found error
```bash
# Verify model exists before building
ls -la artifacts/*.pkl

# If missing, train the model first
cd Assignment
python MLOps_Assignment.py
```

### Problem: Connection refused
```bash
# Check if container is running
docker ps | grep heart-api

# Check container health
curl http://localhost:8000/health

# Restart container
docker restart heart-api
```

### Problem: 422 Validation Error
- Check that all required fields are provided
- Verify data types match the schema
- Check value ranges are valid
- Use the sample_input.json as reference

---

## 🎯 Response Codes

| Code | Meaning | Description |
|------|---------|-------------|
| 200 | Success | Prediction completed successfully |
| 422 | Validation Error | Invalid input data format or values |
| 500 | Server Error | Internal error during prediction |
| 503 | Service Unavailable | Model not loaded |

---

## 📦 Project Structure

```
Assignment/
├── api_server.py              # FastAPI application
├── Dockerfile                 # Docker image definition
├── .dockerignore             # Files to exclude from image
├── requirements.txt          # Python dependencies
├── run_docker.sh             # Build and run script
├── test_api.py               # Automated test script
├── sample_input.json         # Single prediction example
├── sample_batch_input.json   # Batch prediction example
├── README_API.md             # API documentation
└── artifacts/
    └── logistic_regression.pkl  # Trained model
```

---

## 🚀 Advanced Usage

### Running with Custom Model
```bash
# Build with a different model
docker build --build-arg MODEL=random_forest -t heart-disease-api:rf .

# Or mount the artifacts directory
docker run -d -p 8000:8000 \
  -v $(pwd)/artifacts:/app/artifacts \
  --name heart-api heart-disease-api:latest
```

### Running with Environment Variables
```bash
docker run -d -p 8000:8000 \
  -e MODEL_PATH=artifacts/random_forest.pkl \
  -e LOG_LEVEL=debug \
  --name heart-api heart-disease-api:latest
```

### Scaling with Docker Compose
Create `docker-compose.yml`:
```yaml
version: '3.8'
services:
  api:
    build: .
    ports:
      - "8000:8000"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

Run with:
```bash
docker-compose up -d
```

---

## 📝 Notes

- The API uses the logistic regression model by default
- All predictions include confidence scores
- Input validation is handled automatically by FastAPI
- The container includes health checks for monitoring
- Logs are available via `docker logs heart-api`

---

## 🎉 Success Checklist

- [ ] Docker image builds successfully
- [ ] Container starts and runs without errors
- [ ] Health check endpoint returns "healthy"
- [ ] Single prediction endpoint works with sample data
- [ ] Batch prediction endpoint handles multiple inputs
- [ ] API documentation is accessible at /docs
- [ ] Test script passes all tests
- [ ] Can view logs with `docker logs`
- [ ] Can stop and restart container

---

## 📚 Additional Resources

- FastAPI Documentation: https://fastapi.tiangolo.com/
- Docker Documentation: https://docs.docker.com/
- API Testing Guide: See `test_api.py`
- Model Training: See `MLOps_Assignment.py`

---

**Need help?** Check the troubleshooting section or examine the container logs with `docker logs heart-api`
