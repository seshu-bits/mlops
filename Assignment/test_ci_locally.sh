#!/bin/bash
# Local CI/CD simulation script
# Run this to test what CI/CD will do before pushing

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║          Local CI/CD Simulation                       ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Change to Assignment directory
cd "$(dirname "$0")"

echo "📁 Current directory: $(pwd)"
echo ""

# Step 1: Check dependencies
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1: Checking Python and dependencies"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
python --version
pip --version
echo ""

# Step 2: Install dependencies
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2: Installing dependencies"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
python -m pip install --upgrade pip
python -m pip install pytest flake8 pytest-html pytest-cov
if [ -f requirements.txt ]; then
    echo "Installing from requirements.txt..."
    python -m pip install -r requirements.txt
else
    echo "requirements.txt not found, installing defaults..."
    python -m pip install mlflow pandas numpy scikit-learn matplotlib seaborn requests
fi
python -m pip install matplotlib seaborn
echo "✅ Dependencies installed"
echo ""

# Step 3: Linting
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3: Linting with flake8"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics --exclude=mlruns,artifacts,data,__pycache__,.git || {
    echo "❌ Critical linting errors found"
    exit 1
}
echo "✅ Linting passed"
echo ""

# Step 4: Unit tests
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 4: Running unit tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -d tests ]; then
    python -m pytest tests/ -vv \
        --html=test-report.html \
        --self-contained-html \
        --cov=. \
        --cov-report=html \
        --cov-report=term \
        --junitxml=test-results.xml || {
        echo "❌ Unit tests failed"
        exit 1
    }
    echo "✅ Unit tests passed"
else
    echo "⚠️  No tests/ directory found, skipping unit tests"
fi
echo ""

# Step 5: Model training
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 5: Training model (CI mode)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f ci_train.py ]; then
    python ci_train.py 2>&1 | tee training.log || {
        echo "❌ Model training failed"
        exit 1
    }
    echo "✅ Model training completed"
else
    echo "⚠️  ci_train.py not found, skipping training"
fi
echo ""

# Summary
echo "╔════════════════════════════════════════════════════════╗"
echo "║          ✅ All CI/CD Steps Passed!                   ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "Generated artifacts:"
if [ -f test-report.html ]; then
    echo "  ✓ test-report.html"
fi
if [ -f test-results.xml ]; then
    echo "  ✓ test-results.xml"
fi
if [ -d htmlcov ]; then
    echo "  ✓ htmlcov/ (coverage report)"
fi
if [ -d artifacts_ci ]; then
    echo "  ✓ artifacts_ci/ (model artifacts)"
fi
if [ -d mlruns ]; then
    echo "  ✓ mlruns/ (MLflow tracking)"
fi
if [ -f training.log ]; then
    echo "  ✓ training.log"
fi
echo ""
echo "You can now safely push to trigger CI/CD!"
