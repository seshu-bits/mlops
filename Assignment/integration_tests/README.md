# Integration Tests

⚠️ **These are NOT unit tests!**

This directory contains integration tests that require external services to be running.

## API Integration Tests

The `test_api.py` script tests the FastAPI server endpoints.

### Prerequisites

The API server must be running at `http://localhost:8000`

### Running the API Server

**Option 1: Using Docker (Recommended)**
```bash
cd Assignment
docker build -t heart-disease-api:latest .
docker run -d -p 8000:8000 --name heart-api heart-disease-api:latest
```

**Option 2: Running Locally**
```bash
cd Assignment
pip install fastapi uvicorn[standard]
uvicorn api_server:app --host 0.0.0.0 --port 8000
```

### Running the Integration Tests

Once the server is running:

```bash
cd Assignment
python integration_tests/test_api.py
```

### Expected Output

```
🚀🚀🚀...
Starting API Tests
...
✅ PASS - Root Endpoint
✅ PASS - Health Check
✅ PASS - Model Info
✅ PASS - Single Prediction
✅ PASS - Batch Prediction

Total: 5/5 tests passed
```

## Note for CI/CD

These integration tests are **excluded** from the CI/CD pipeline because they require:
- A running API server
- Network connectivity
- Docker or uvicorn setup

The CI/CD pipeline only runs unit tests from the `tests/` directory.

To run integration tests in CI/CD, you would need to:
1. Start the API server in the background
2. Wait for it to be ready
3. Run the integration tests
4. Stop the server

This is typically done in a separate workflow or pipeline stage.
