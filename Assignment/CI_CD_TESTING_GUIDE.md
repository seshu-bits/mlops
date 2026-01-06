# CI/CD Testing Guide

This guide covers how to run tests locally, use pre-commit hooks, and understand the CI/CD pipeline.

---

## Table of Contents
1. [Quick Start](#quick-start)
2. [Running Tests Locally](#running-tests-locally)
3. [Pre-commit Hooks](#pre-commit-hooks)
4. [Coverage Requirements](#coverage-requirements)
5. [Test Organization](#test-organization)
6. [CI/CD Pipeline](#cicd-pipeline)
7. [Troubleshooting](#troubleshooting)

---

## Quick Start

```bash
# Install dependencies
pip install -r requirements.txt

# Run all tests
pytest tests/ -v

# Run tests with coverage
pytest tests/ -v --cov

# Install pre-commit hooks
pip install pre-commit
pre-commit install
```

---

## Running Tests Locally

### Run All Tests
```bash
# Basic run
pytest tests/ -v

# With coverage
pytest tests/ -v --cov

# With HTML coverage report
pytest tests/ -v --cov --cov-report=html
open htmlcov/index.html
```

### Run Specific Tests
```bash
# Single test file
pytest tests/test_api_server.py -v

# Single test function
pytest tests/test_api_server.py::test_root_endpoint -v

# By marker
pytest -m api -v           # Only API tests
pytest -m data -v          # Only data processing tests
pytest -m "not slow" -v    # Skip slow tests
```

### Test Options
```bash
# Stop after first failure
pytest tests/ -x

# Stop after N failures
pytest tests/ --maxfail=3

# Show slowest tests
pytest tests/ --durations=10

# Verbose output
pytest tests/ -vv

# Quiet output (only show failures)
pytest tests/ -q
```

---

## Pre-commit Hooks

Pre-commit hooks automatically check your code **before** you commit, catching issues early.

### Installation
```bash
# Install pre-commit
pip install pre-commit

# Install the git hooks
pre-commit install
```

### Usage
```bash
# Manual run on all files
pre-commit run --all-files

# Manual run on specific files
pre-commit run --files tests/*.py

# Automatic run (happens on git commit)
git add .
git commit -m "Your message"  # Hooks run automatically
```

### Configured Hooks
1. **Trailing whitespace removal**
2. **End-of-file fixer**
3. **YAML/JSON validation**
4. **Black** - Python code formatting
5. **isort** - Import sorting
6. **Flake8** - Linting
7. **Bandit** - Security scanning
8. **nbstripout** - Notebook output removal
9. **hadolint** - Dockerfile linting

### Bypassing Hooks (NOT RECOMMENDED)
```bash
# Skip pre-commit checks (emergency only)
git commit --no-verify -m "Emergency fix"
```

---

## Coverage Requirements

### Minimum Coverage: 80%

The CI pipeline **will fail** if code coverage is below 80%.

### Check Current Coverage
```bash
# Run with coverage
pytest tests/ --cov

# Generate HTML report
pytest tests/ --cov --cov-report=html
open htmlcov/index.html

# Check specific module
pytest tests/ --cov=MLOps_Assignment --cov-report=term-missing
```

### Coverage Report Formats
- **Terminal:** `--cov-report=term` (default)
- **HTML:** `--cov-report=html` → `htmlcov/index.html`
- **XML:** `--cov-report=xml` → `coverage.xml` (for CI)
- **Missing lines:** `--cov-report=term-missing` (shows uncovered lines)

### Improving Coverage
1. Identify untested code: `pytest --cov --cov-report=term-missing`
2. Write tests for uncovered functions
3. Focus on critical paths first
4. Use `pytest --cov --cov-report=html` to visualize gaps

---

## Test Organization

### Test Structure
```
tests/
├── test_data_pipeline.py      # Data loading/preprocessing (3 tests)
├── test_models.py              # Model training/evaluation (2 tests)
├── test_api_server.py          # API endpoint testing (22 tests)
└── test_mlops_functions.py     # Validation, EDA, tuning (17 tests)

integration_tests/
└── test_api.py                 # Integration tests (not run in CI)
```

### Test Categories (Markers)

#### Unit Tests
```python
@pytest.mark.unit
def test_my_function():
    pass
```

#### API Tests
```python
@pytest.mark.api
def test_api_endpoint():
    pass
```

#### Data Processing Tests
```python
@pytest.mark.data
def test_data_cleaning():
    pass
```

#### Model Tests
```python
@pytest.mark.model
def test_model_training():
    pass
```

#### Slow Tests
```python
@pytest.mark.slow
def test_expensive_operation():
    pass
```

### Running by Category
```bash
# Only API tests
pytest -m api -v

# Only fast tests (skip slow)
pytest -m "not slow" -v

# Multiple markers
pytest -m "api or data" -v
```

---

## CI/CD Pipeline

### Pipeline Stages

```
┌─────────────────────────────────────────────────┐
│ 1. Trigger (push/PR to main)                    │
└─────────────────────┬───────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────┐
│ 2. Setup (checkout code, Python 3.11, deps)     │
└─────────────────────┬───────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────┐
│ 3. Lint - Critical (FAILS on E9,F63,F7,F82)     │
└─────────────────────┬───────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────┐
│ 4. Lint - Style (warnings only)                 │
└─────────────────────┬───────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────┐
│ 5. Unit Tests (pytest with 80% coverage min)    │
└─────────────────────┬───────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────┐
│ 6. Model Training (ci_train.py + MLflow)        │
└─────────────────────┬───────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────┐
│ 7. Upload Artifacts (test reports, coverage,    │
│    training logs, MLflow runs)                   │
└──────────────────────────────────────────────────┘
```

### Artifacts Generated

1. **test-reports**
   - HTML test report
   - Location: `htmlcov/`

2. **coverage-reports**
   - Code coverage HTML
   - Location: `htmlcov/`

3. **lint-logs**
   - Flake8 critical errors
   - Flake8 style warnings
   - Location: `flake8-*.log`

4. **training-logs**
   - Model training output
   - MLflow experiment runs
   - Location: `mlruns/`, `artifacts_ci/`

### Viewing Artifacts

```bash
# On GitHub
1. Go to Actions tab
2. Click on workflow run
3. Scroll to "Artifacts" section
4. Download and extract
```

### Local CI Simulation

```bash
# Run the same checks as CI
# 1. Linting
flake8 . --count --select=E9,F63,F7,F82 --show-source

# 2. Unit tests with coverage
pytest tests/ -v \
  --cov=MLOps_Assignment \
  --cov=api_server \
  --cov=ci_train \
  --cov-report=html \
  --cov-fail-under=80

# 3. Model training
python ci_train.py

# OR use pre-commit to catch most issues
pre-commit run --all-files
```

---

## Troubleshooting

### Tests Fail Locally

```bash
# Check for missing dependencies
pip install -r requirements.txt

# Check Python version (must be 3.11+)
python --version

# Run single test for debugging
pytest tests/test_api_server.py::test_root_endpoint -vv

# Show full error traceback
pytest tests/ -vv --tb=long
```

### Coverage Below 80%

```bash
# Find untested code
pytest --cov --cov-report=term-missing

# Generate HTML report for detailed view
pytest --cov --cov-report=html
open htmlcov/index.html

# Focus on specific module
pytest --cov=MLOps_Assignment --cov-report=term-missing
```

### Pre-commit Hooks Fail

```bash
# Run hooks manually to see errors
pre-commit run --all-files

# Update hooks
pre-commit autoupdate

# Skip specific hook (debugging)
SKIP=black git commit -m "message"

# Uninstall hooks (if needed)
pre-commit uninstall
```

### Linting Errors

```bash
# Check critical errors only
flake8 . --select=E9,F63,F7,F82

# Auto-fix with black
black .

# Fix imports with isort
isort .

# Ignore specific lines (use sparingly)
# Add # noqa: E501 at end of line
```

### Import Errors in Tests

```bash
# Ensure PYTHONPATH includes current directory
export PYTHONPATH="${PYTHONPATH}:$(pwd)"

# Or run from project root
cd /path/to/Assignment
pytest tests/
```

### CI Fails but Local Works

```bash
# Check Python version matches CI (3.11)
python --version

# Check dependencies match
pip list

# Run exact CI commands locally
pytest tests/ -v --cov=MLOps_Assignment --cov=api_server --cov=ci_train
```

---

## Best Practices

### Writing Tests
- ✅ Use descriptive names: `test_predict_with_invalid_data()`
- ✅ One assertion per test (when possible)
- ✅ Use fixtures for common setup
- ✅ Mock external dependencies
- ✅ Test edge cases and errors
- ❌ Don't test implementation details
- ❌ Don't make tests depend on each other

### Code Coverage
- ✅ Focus on critical business logic
- ✅ Test error paths
- ✅ Aim for 80%+ coverage
- ❌ Don't chase 100% coverage blindly
- ❌ Don't test third-party libraries

### Pre-commit Hooks
- ✅ Run `pre-commit run --all-files` before PRs
- ✅ Fix formatting automatically (black, isort)
- ✅ Address linting issues promptly
- ❌ Don't commit with `--no-verify` unless emergency
- ❌ Don't ignore security warnings from bandit

### CI/CD
- ✅ Keep builds fast (<5 minutes)
- ✅ Fail fast on critical errors
- ✅ Generate comprehensive artifacts
- ✅ Monitor build trends
- ❌ Don't disable tests to pass CI
- ❌ Don't commit broken code

---

## Summary

- **44+ tests** ensuring code quality
- **80% minimum coverage** enforced
- **Pre-commit hooks** catch issues early
- **Automated CI/CD** pipeline on every push
- **Comprehensive artifacts** for debugging

**Need help?** Check `CI_CD_OPTIMIZATION_REPORT.md` for detailed information.
