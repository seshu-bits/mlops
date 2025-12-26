#!/bin/bash

# Script to build and run the Heart Disease Prediction API Docker container

set -e

echo "🐳 Building Heart Disease Prediction API Docker Image..."
docker build -t heart-disease-api:latest .

echo ""
echo "✅ Docker image built successfully!"
echo ""
echo "🚀 Starting the API container..."

# Stop and remove existing container if it exists
docker stop heart-api 2>/dev/null || true
docker rm heart-api 2>/dev/null || true

# Run the container
docker run -d -p 8000:8000 --name heart-api heart-disease-api:latest

echo ""
echo "✅ API container is running!"
echo ""
echo "📡 API is available at:"
echo "   - Health Check: http://localhost:8000/health"
echo "   - API Docs: http://localhost:8000/docs"
echo "   - Alternative Docs: http://localhost:8000/redoc"
echo ""
echo "🧪 To test the API, run:"
echo "   python test_api.py"
echo ""
echo "📋 Useful Docker commands:"
echo "   - View logs: docker logs heart-api"
echo "   - Stop container: docker stop heart-api"
echo "   - Remove container: docker rm heart-api"
echo "   - Access shell: docker exec -it heart-api /bin/bash"
echo ""
