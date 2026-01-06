#!/bin/bash
# Script to run integration tests with proper setup

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║     Integration Tests - API Server Required           ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Check if API is already running
echo "🔍 Checking if API server is running at http://localhost:8000..."
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "✅ API server is already running!"
    echo ""
    echo "Running integration tests..."
    echo ""
    python integration_tests/test_api.py
    exit 0
fi

echo "❌ API server is not running at http://localhost:8000"
echo ""
echo "You need to start the API server first. Choose one option:"
echo ""
echo "Option 1: Run locally with uvicorn"
echo "  uvicorn api_server:app --host 0.0.0.0 --port 8000"
echo ""
echo "Option 2: Run with Docker"
echo "  docker build -t heart-disease-api:latest ."
echo "  docker run -d -p 8000:8000 --name heart-api heart-disease-api:latest"
echo ""
echo "Option 3: Port forward from Kubernetes"
echo "  kubectl port-forward -n mlops service/heart-disease-api 8000:80"
echo ""
echo "After starting the server, run this script again or:"
echo "  python integration_tests/test_api.py"
echo ""

exit 1
