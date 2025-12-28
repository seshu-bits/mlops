# MLOps Heart Disease Prediction - Complete Setup Guide

This guide provides step-by-step instructions to run the entire MLOps project from scratch.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Project Setup](#project-setup)
3. [Running Model Training](#running-model-training)
4. [Running Tests](#running-tests)
5. [Deploying the API](#deploying-the-api)
6. [Testing the API](#testing-the-api)
7. [CI/CD Pipeline](#cicd-pipeline)
8. [Troubleshooting](#troubleshooting)

---

## 1️⃣ Prerequisites

### Required Software

- **Python 3.11+**
  ```bash
  python --version  # Should show 3.11 or higher
  ```

- **Git**
  ```bash
  git --version
  ```

- **Docker Desktop** (for API deployment)
  ```bash
  docker --version
  ```

### Clone the Repository

```bash
git clone https://github.com/seshu-bits/mlops.git
cd mlops/Assignment
```

---

## 2️⃣ Project Setup

### Step 1: Create a Virtual Environment (Recommended)

```bash
# Create virtual environment
python -m venv venv

# Activate it
# On macOS/Linux:
source venv/bin/activate
# On Windows:
venv\Scripts\activate
```

### Step 2: Install Dependencies

```bash
# Install all required packages
pip install -r requirements.txt

# Install additional testing tools
pip install pytest pytest-html pytest-cov flake8
```

### Step 3: Verify Installation

```bash
# Check installed packages
pip list

# Should see: pandas, numpy, scikit-learn, mlflow, matplotlib, seaborn, etc.
```

---

## 3️⃣ Running Model Training

### Option A: Full Training Script

**Run the complete training pipeline:**

```bash
cd Assignment
python MLOps_Assignment.py
```

**What this does:**
- ✅ Loads the heart disease dataset
- ✅ Cleans and preprocesses data
- ✅ Trains 3 models (Logistic Regression, Random Forest, Decision Tree)
- ✅ Performs cross-validation
- ✅ Generates evaluation metrics
- ✅ Creates confusion matrix plots
- ✅ Saves models to `artifacts/`
- ✅ Logs experiments to MLflow

**Expected output:**
```
=== Loading Raw Data ===
Loaded 303 rows, 14 columns

=== Cleaning Data ===
...

=== Training Logistic Regression ===
Train Accuracy: 0.85
Test Accuracy: 0.82
...

Models saved to: artifacts/
```

### Option B: CI Training Script (Minimal)

**For CI/CD pipeline:**

```bash
cd Assignment
python ci_train.py
```

This runs a minimal training for faster CI builds.

### Step 4: Verify Model Files

```bash
ls -lh artifacts/
```

**You should see:**
- `logistic_regression.pkl` (~1 KB)
- `random_forest.pkl` (~1.4 MB)
- `decision_tree.pkl` (~7 KB)

### Step 5: View MLflow Experiments

```bash
# Start MLflow UI
mlflow ui

# Open browser to: http://localhost:5000
```

---

## 4️⃣ Running Tests

### Unit Tests

**Run all unit tests:**

```bash
cd Assignment
pytest -v
```

**Expected output:**
```
tests/test_data_pipeline.py::test_load_raw_heart_data PASSED
tests/test_data_pipeline.py::test_clean_and_preprocess_heart_data PASSED
tests/test_models.py::test_train_and_evaluate_models PASSED
...

====== 7 passed in 2.5s ======
```

### Generate Test Report

```bash
# HTML report with coverage
pytest --html=test-report.html --self-contained-html --cov=. --cov-report=html

# View report
open test-report.html        # macOS
xdg-open test-report.html    # Linux
start test-report.html       # Windows
```

### Code Linting

```bash
# Check for critical errors
flake8 Assignment/ --count --select=E9,F63,F7,F82 --show-source --statistics

# Full style check
flake8 Assignment/ --count --exit-zero --max-complexity=10 --max-line-length=120 --statistics
```

---

## 5️⃣ Deploying the API

### Method 1: Docker Deployment (Recommended)

#### Step 1: Build Docker Image

```bash
cd Assignment
docker build -t heart-disease-api:latest .
```

**Expected output:**
```
[+] Building 45.2s (12/12) FINISHED
 => => naming to docker.io/library/heart-disease-api:latest
```

#### Step 2: Run the Container

```bash
# Run in background
docker run -d -p 8000:8000 --name heart-api heart-disease-api:latest

# Or run with logs visible
docker run -p 8000:8000 --name heart-api heart-disease-api:latest
```

#### Step 3: Verify Container is Running

```bash
docker ps | grep heart-api
```

**Expected output:**
```
CONTAINER ID   IMAGE                        STATUS          PORTS
abc123def456   heart-disease-api:latest    Up 10 seconds   0.0.0.0:8000->8000/tcp
```

#### Quick Start Script

```bash
# All-in-one: build and run
./run_docker.sh
```

### Method 2: Local Deployment

**Without Docker:**

```bash
cd Assignment

# Install FastAPI and Uvicorn
pip install fastapi uvicorn[standard]

# Run the server
uvicorn api_server:app --host 0.0.0.0 --port 8000
```

**Expected output:**
```
INFO:     Started server process [12345]
INFO:     Waiting for application startup.
Model loaded successfully: logistic_regression
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000
```

---

## 6️⃣ Testing the API

### Verify API is Running

**Health check:**
```bash
curl http://localhost:8000/health
```

**Expected response:**
```json
{
  "status": "healthy",
  "model_loaded": true,
  "model_name": "logistic_regression"
}
```

### Interactive Documentation

Open in browser:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

### Test with Sample Data

#### Single Prediction

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

**Or use the sample file:**
```bash
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d @sample_input.json
```

**Expected response:**
```json
{
  "prediction": 0,
  "confidence": 0.8523,
  "model_name": "logistic_regression"
}
```

- `prediction`: 0 = No Heart Disease, 1 = Heart Disease
- `confidence`: Probability (0.0 to 1.0)

#### Batch Prediction

```bash
curl -X POST http://localhost:8000/predict/batch \
  -H "Content-Type: application/json" \
  -d @sample_batch_input.json
```

### Automated Integration Tests

**Run the test suite:**

```bash
# Make sure API is running first!
python integration_tests/test_api.py
```

**Expected output:**
```
🚀🚀🚀 Starting API Tests

============================================================
Testing Root Endpoint
============================================================
Status Code: 200
✅ PASS - Root Endpoint

============================================================
Testing Single Prediction Endpoint
============================================================
🏥 Prediction: No Heart Disease
📊 Confidence: 85.23%
🤖 Model: logistic_regression
✅ PASS - Single Prediction

Test Summary
============================================================
✅ PASS - Root Endpoint
✅ PASS - Health Check
✅ PASS - Model Info
✅ PASS - Single Prediction
✅ PASS - Batch Prediction

Total: 5/5 tests passed
```

---

## 7️⃣ CI/CD Pipeline

### Automated Testing on GitHub

The project uses GitHub Actions for CI/CD. Every push triggers:

1. **Linting** with flake8
2. **Unit tests** with pytest
3. **Model training** (minimal)
4. **Artifact upload** (test reports, coverage, models)

### View CI/CD Status

- Visit: https://github.com/seshu-bits/mlops/actions
- Check workflow runs
- Download artifacts from completed runs

### Local CI Simulation

```bash
# Run the same checks as CI
cd Assignment

# 1. Lint
flake8 Assignment/ --count --select=E9,F63,F7,F82 --show-source --statistics

# 2. Test
pytest -vv --html=test-report.html --self-contained-html --cov=. --cov-report=html

# 3. Train
python ci_train.py
```

---

## 8️⃣ Troubleshooting

### Problem: Module Not Found

```bash
# Solution: Install dependencies
pip install -r requirements.txt

# Or install missing package
pip install <package-name>
```

### Problem: Model File Not Found

```bash
# Solution: Train the models first
cd Assignment
python MLOps_Assignment.py

# Verify models exist
ls -la artifacts/*.pkl
```

### Problem: API Port Already in Use

```bash
# Solution 1: Use different port
docker run -d -p 8080:8000 --name heart-api heart-disease-api:latest

# Solution 2: Stop existing container
docker stop heart-api
docker rm heart-api

# Solution 3: Kill process on port 8000
lsof -ti:8000 | xargs kill -9
```

### Problem: Docker Command Not Found

```bash
# Solution: Install Docker Desktop
# Download from: https://www.docker.com/products/docker-desktop

# After installation, verify:
docker --version
```

### Problem: Permission Denied (Linux/Mac)

```bash
# Solution: Add execute permission
chmod +x run_docker.sh

# Or run with sudo (not recommended)
sudo docker run ...
```

### Problem: Tests Failing

```bash
# Check Python version
python --version  # Must be 3.11+

# Reinstall dependencies
pip install --upgrade -r requirements.txt

# Run tests with verbose output
pytest -vv -s
```

### Problem: MLflow UI Not Starting

```bash
# Check if another process is using port 5000
lsof -ti:5000 | xargs kill -9

# Start on different port
mlflow ui --port 5001

# Open: http://localhost:5001
```

---

## 📊 Complete Workflow Summary

### Quick Start (All Steps)

```bash
# 1. Clone and setup
git clone https://github.com/seshu-bits/mlops.git
cd mlops/Assignment
python -m venv venv
source venv/bin/activate  # or venv\Scripts\activate on Windows
pip install -r requirements.txt

# 2. Train models
python MLOps_Assignment.py

# 3. Run tests
pytest -v

# 4. Deploy API
docker build -t heart-disease-api:latest .
docker run -d -p 8000:8000 --name heart-api heart-disease-api:latest

# 5. Test API
curl http://localhost:8000/health
python integration_tests/test_api.py

# 6. View MLflow
mlflow ui
# Open: http://localhost:5000

# 7. View API docs
# Open: http://localhost:8000/docs
```

---

## 📁 Project Structure

```
mlops/
├── Assignment/
│   ├── MLOps_Assignment.py         # Main training script
│   ├── ci_train.py                 # CI training script
│   ├── api_server.py               # FastAPI server
│   ├── requirements.txt            # Python dependencies
│   ├── Dockerfile                  # Docker configuration
│   ├── pytest.ini                  # Pytest configuration
│   │
│   ├── data/                       # Dataset
│   │   └── processed.cleveland.data
│   │
│   ├── artifacts/                  # Trained models (generated)
│   │   ├── logistic_regression.pkl
│   │   ├── random_forest.pkl
│   │   └── decision_tree.pkl
│   │
│   ├── mlruns/                     # MLflow experiments (generated)
│   │
│   ├── tests/                      # Unit tests
│   │   ├── test_data_pipeline.py
│   │   └── test_models.py
│   │
│   ├── integration_tests/          # Integration tests
│   │   └── test_api.py
│   │
│   ├── sample_input.json           # API test data
│   ├── sample_batch_input.json     # Batch test data
│   │
│   ├── DOCKER_GUIDE.md            # Docker deployment guide
│   ├── README_API.md              # API documentation
│   └── run_docker.sh              # Docker build script
│
├── .github/workflows/
│   └── ci.yml                      # CI/CD pipeline
│
├── .gitignore                      # Git ignore rules
└── README.md                       # This file
```

---

## 🎯 Success Checklist

- [ ] Repository cloned
- [ ] Virtual environment created and activated
- [ ] Dependencies installed
- [ ] Models trained successfully
- [ ] Unit tests passing
- [ ] Docker image built
- [ ] API container running
- [ ] Health check returns "healthy"
- [ ] Single prediction works
- [ ] Batch prediction works
- [ ] Integration tests pass
- [ ] MLflow UI accessible
- [ ] API documentation accessible

---

## 📚 Additional Resources

- **Docker Guide**: `Assignment/DOCKER_GUIDE.md`
- **API Documentation**: `Assignment/README_API.md`
- **Integration Tests**: `Assignment/integration_tests/README.md`
- **GitHub Actions**: https://github.com/seshu-bits/mlops/actions
- **MLflow Documentation**: https://mlflow.org/docs/latest/index.html
- **FastAPI Documentation**: https://fastapi.tiangolo.com/

---

## 💡 Tips

1. **Always activate virtual environment** before running Python commands
2. **Train models before** trying to run the API
3. **Check logs** if something fails: `docker logs heart-api`
4. **Use interactive docs** at `/docs` for easy API testing
5. **View test reports** in HTML for detailed coverage
6. **Monitor MLflow** to track experiment metrics

---

## 🆘 Getting Help

If you encounter issues:

1. Check the [Troubleshooting](#troubleshooting) section
2. Review logs: `docker logs heart-api` or pytest output
3. Verify all prerequisites are installed
4. Check GitHub Actions for CI/CD issues
5. Ensure all dependencies are up to date

---

**Last Updated**: December 27, 2025
