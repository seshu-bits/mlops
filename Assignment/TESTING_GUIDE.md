# Testing Guide

## Overview

This project has two types of tests:

### 1. Unit Tests (tests/ directory)
- **Run automatically** by pytest
- **No external dependencies** required
- Test individual functions and classes
- Fast execution

### 2. Integration Tests (integration_tests/ directory)  
- **Require running API server**
- Test actual HTTP endpoints
- **Excluded from regular pytest runs**
- Must be run manually when needed

---

## Running Unit Tests ✅

Unit tests run without any setup:

```bash
cd Assignment

# Run all unit tests
pytest

# Run with verbose output
pytest -v

# Run specific test file
pytest tests/test_models.py

# Run with coverage
pytest --cov=. --cov-report=html
```

**Expected result:** All unit tests should pass without requiring any services.

---

## Running Integration Tests 🔌

Integration tests require the API server to be running.

### Step 1: Start the API Server

Choose one option:

**Option A: Local Development**
```bash
cd Assignment
uvicorn api_server:app --host 0.0.0.0 --port 8000
```

**Option B: Docker**
```bash
cd Assignment
docker build -t heart-disease-api:latest .
docker run -d -p 8000:8000 --name heart-api heart-disease-api:latest
```

**Option C: Kubernetes Port Forward**
```bash
kubectl port-forward -n mlops service/heart-disease-api 8000:80
```

### Step 2: Run Integration Tests

**Method 1: Using the helper script (Recommended)**
```bash
cd Assignment
./run_integration_tests.sh
```
This script checks if the server is running and gives helpful error messages.

**Method 2: Direct Python execution**
```bash
cd Assignment
python integration_tests/test_api.py
```

**Method 3: Using pytest**
```bash
cd Assignment
pytest integration_tests/ -v
```
Note: Tests will be automatically skipped if server is not running.

---

## Understanding Test Failures

### "Connection refused" errors
❌ **Error:**
```
requests.exceptions.ConnectionError: HTTPConnectionPool(host='localhost', port=8000): 
Max retries exceeded with url: / (Caused by NewConnectionError(...Connection refused))
```

✅ **Solution:** The API server is not running. Start it first (see above).

### Tests are skipped
```
SKIPPED [1] integration_tests/conftest.py:19: API server is not running
```

✅ **This is expected!** Integration tests are automatically skipped when the API isn't available. This prevents CI/CD failures.

---

## CI/CD Considerations

### Regular pytest (Unit Tests Only)
```bash
# This runs ONLY unit tests
pytest

# Output: Tests in tests/ directory run, integration_tests/ is ignored
```

### Full Integration Testing
For CI/CD pipelines that want to test the API:

```bash
# 1. Start API in background
uvicorn api_server:app --host 0.0.0.0 --port 8000 &
SERVER_PID=$!

# 2. Wait for server to start
sleep 5

# 3. Run integration tests
pytest integration_tests/ -v

# 4. Stop server
kill $SERVER_PID
```

Or use Docker Compose for a complete setup.

---

## Quick Reference

| Command | What it tests | Requirements |
|---------|---------------|--------------|
| `pytest` | Unit tests only | None |
| `pytest tests/` | Unit tests only | None |
| `pytest integration_tests/` | API endpoints | Server must be running at :8000 |
| `python integration_tests/test_api.py` | API endpoints | Server must be running at :8000 |
| `./run_integration_tests.sh` | API endpoints with checks | Server must be running at :8000 |

---

## Test Structure

```
Assignment/
├── tests/                    # Unit tests (run by default)
│   ├── test_models.py       # ✅ Runs without server
│   └── test_data_pipeline.py # ✅ Runs without server
│
├── integration_tests/        # Integration tests (requires server)
│   ├── conftest.py          # Skips tests if server not available
│   ├── test_api.py          # ❌ Needs server at :8000
│   └── README.md            # Detailed instructions
│
├── pytest.ini               # Excludes integration_tests/
└── run_integration_tests.sh # Helper script
```

---

## Troubleshooting

### Issue: pytest tries to run integration tests
**Symptom:** Getting connection errors when running `pytest`

**Solution:** Make sure `pytest.ini` has this line:
```ini
norecursedirs = ... integration_tests
```

### Issue: Integration tests still fail even with server running
**Check:**
1. Server is at the correct URL: `curl http://localhost:8000/health`
2. No firewall blocking port 8000
3. Using correct Python environment with requests installed

### Issue: Want to run both unit and integration tests
```bash
# Run unit tests
pytest

# Start server (in another terminal or background)
uvicorn api_server:app --host 0.0.0.0 --port 8000 &

# Run integration tests
pytest integration_tests/ -v

# Or use the script
./run_integration_tests.sh
```

---

## Best Practices

1. ✅ **Run unit tests frequently** during development (`pytest`)
2. ✅ **Run integration tests** before committing API changes
3. ✅ **Keep integration tests in separate directory** (already done)
4. ✅ **Use conftest.py** to skip tests gracefully when server unavailable
5. ✅ **Document which tests need external services** (this file!)

---

## Summary

- **Regular development:** Just run `pytest` (unit tests only)
- **API changes:** Start server, then run integration tests
- **CI/CD:** Configure pipeline to start server before integration tests
- **Connection errors:** These are EXPECTED if server isn't running - that's by design!

The integration test "failures" you saw are actually the system working correctly - it's preventing tests from running when the required service isn't available. 🎉
