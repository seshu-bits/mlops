#!/bin/bash

# Test script for Heart Disease API deployed on Minikube
# Tests all endpoints and validates responses

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

NAMESPACE="mlops"
SERVICE_NAME="heart-disease-api"

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Get service URL
get_service_url() {
    SERVICE_URL=$(minikube service $SERVICE_NAME -n $NAMESPACE --url 2>/dev/null)
    if [ -z "$SERVICE_URL" ]; then
        print_error "Could not get service URL. Is the service running?"
        exit 1
    fi
    echo $SERVICE_URL
}

# Test health endpoint
test_health() {
    print_header "Testing Health Endpoint"
    
    echo "Endpoint: GET $SERVICE_URL/health"
    echo ""
    
    response=$(curl -s -w "\n%{http_code}" "$SERVICE_URL/health")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" -eq 200 ]; then
        print_success "Health check passed (HTTP $http_code)"
        echo "Response:"
        echo "$body" | jq '.' 2>/dev/null || echo "$body"
    else
        print_error "Health check failed (HTTP $http_code)"
        echo "$body"
        return 1
    fi
    echo ""
}

# Test root endpoint
test_root() {
    print_header "Testing Root Endpoint"
    
    echo "Endpoint: GET $SERVICE_URL/"
    echo ""
    
    response=$(curl -s -w "\n%{http_code}" "$SERVICE_URL/")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" -eq 200 ]; then
        print_success "Root endpoint passed (HTTP $http_code)"
        echo "Response:"
        echo "$body" | jq '.' 2>/dev/null || echo "$body"
    else
        print_error "Root endpoint failed (HTTP $http_code)"
        echo "$body"
        return 1
    fi
    echo ""
}

# Test single prediction
test_single_prediction() {
    print_header "Testing Single Prediction"
    
    echo "Endpoint: POST $SERVICE_URL/predict"
    echo ""
    
    payload='{
      "age": 63,
      "sex": 1,
      "cp": 3,
      "trestbps": 145,
      "chol": 233,
      "fbs": 1,
      "restecg": 0,
      "thalach": 150,
      "exang": 0,
      "oldpeak": 2.3,
      "slope": 0,
      "ca": 0,
      "thal": 1
    }'
    
    echo "Payload:"
    echo "$payload" | jq '.'
    echo ""
    
    response=$(curl -s -w "\n%{http_code}" -X POST "$SERVICE_URL/predict" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" -eq 200 ]; then
        print_success "Single prediction passed (HTTP $http_code)"
        echo "Response:"
        echo "$body" | jq '.' 2>/dev/null || echo "$body"
    else
        print_error "Single prediction failed (HTTP $http_code)"
        echo "$body"
        return 1
    fi
    echo ""
}

# Test batch prediction
test_batch_prediction() {
    print_header "Testing Batch Prediction"
    
    echo "Endpoint: POST $SERVICE_URL/predict/batch"
    echo ""
    
    payload='{
      "patients": [
        {
          "age": 63, "sex": 1, "cp": 3, "trestbps": 145, "chol": 233,
          "fbs": 1, "restecg": 0, "thalach": 150, "exang": 0,
          "oldpeak": 2.3, "slope": 0, "ca": 0, "thal": 1
        },
        {
          "age": 67, "sex": 1, "cp": 4, "trestbps": 160, "chol": 286,
          "fbs": 0, "restecg": 2, "thalach": 108, "exang": 1,
          "oldpeak": 1.5, "slope": 2, "ca": 3, "thal": 3
        }
      ]
    }'
    
    echo "Payload: 2 patients"
    echo ""
    
    response=$(curl -s -w "\n%{http_code}" -X POST "$SERVICE_URL/predict/batch" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" -eq 200 ]; then
        print_success "Batch prediction passed (HTTP $http_code)"
        echo "Response:"
        echo "$body" | jq '.' 2>/dev/null || echo "$body"
    else
        print_error "Batch prediction failed (HTTP $http_code)"
        echo "$body"
        return 1
    fi
    echo ""
}

# Test invalid input
test_invalid_input() {
    print_header "Testing Invalid Input Validation"
    
    echo "Endpoint: POST $SERVICE_URL/predict"
    echo "Testing with invalid age (-5)"
    echo ""
    
    payload='{
      "age": -5,
      "sex": 1,
      "cp": 3,
      "trestbps": 145,
      "chol": 233,
      "fbs": 1,
      "restecg": 0,
      "thalach": 150,
      "exang": 0,
      "oldpeak": 2.3,
      "slope": 0,
      "ca": 0,
      "thal": 1
    }'
    
    response=$(curl -s -w "\n%{http_code}" -X POST "$SERVICE_URL/predict" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" -eq 422 ]; then
        print_success "Input validation working correctly (HTTP $http_code)"
        echo "Response:"
        echo "$body" | jq '.' 2>/dev/null || echo "$body"
    else
        print_error "Expected HTTP 422, got HTTP $http_code"
        echo "$body"
    fi
    echo ""
}

# Test docs endpoint
test_docs() {
    print_header "Testing Documentation Endpoints"
    
    # Test /docs
    echo "Testing: GET $SERVICE_URL/docs"
    response=$(curl -s -w "%{http_code}" "$SERVICE_URL/docs" -o /dev/null)
    if [ "$response" -eq 200 ]; then
        print_success "API Docs available at $SERVICE_URL/docs"
    else
        print_error "API Docs endpoint failed (HTTP $response)"
    fi
    
    # Test /redoc
    echo "Testing: GET $SERVICE_URL/redoc"
    response=$(curl -s -w "%{http_code}" "$SERVICE_URL/redoc" -o /dev/null)
    if [ "$response" -eq 200 ]; then
        print_success "ReDoc available at $SERVICE_URL/redoc"
    else
        print_error "ReDoc endpoint failed (HTTP $response)"
    fi
    echo ""
}

# Performance test
test_performance() {
    print_header "Running Performance Test"
    
    echo "Sending 10 requests to measure response time..."
    echo ""
    
    total_time=0
    success_count=0
    
    for i in {1..10}; do
        start_time=$(date +%s%3N)
        
        response=$(curl -s -w "%{http_code}" -X POST "$SERVICE_URL/predict" \
            -H "Content-Type: application/json" \
            -d '{
              "age": 63, "sex": 1, "cp": 3, "trestbps": 145, "chol": 233,
              "fbs": 1, "restecg": 0, "thalach": 150, "exang": 0,
              "oldpeak": 2.3, "slope": 0, "ca": 0, "thal": 1
            }' -o /dev/null)
        
        end_time=$(date +%s%3N)
        duration=$((end_time - start_time))
        total_time=$((total_time + duration))
        
        if [ "$response" -eq 200 ]; then
            success_count=$((success_count + 1))
            echo "Request $i: ${duration}ms ✓"
        else
            echo "Request $i: Failed (HTTP $response) ✗"
        fi
    done
    
    avg_time=$((total_time / 10))
    
    echo ""
    echo "Performance Summary:"
    echo "  • Total requests: 10"
    echo "  • Successful: $success_count"
    echo "  • Failed: $((10 - success_count))"
    echo "  • Average response time: ${avg_time}ms"
    echo ""
}

# Main execution
main() {
    print_header "Heart Disease API - Test Suite"
    
    echo "Getting service URL..."
    SERVICE_URL=$(get_service_url)
    echo "Service URL: $SERVICE_URL"
    echo ""
    
    # Run tests
    test_health
    test_root
    test_single_prediction
    test_batch_prediction
    test_invalid_input
    test_docs
    test_performance
    
    print_header "Test Suite Complete!"
    print_success "All tests completed! 🎉"
}

# Check dependencies
if ! command -v curl &> /dev/null; then
    print_error "curl is not installed"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Warning: jq is not installed. JSON output will not be formatted."
    echo "Install jq for better output: brew install jq (macOS) or sudo dnf install jq (AlmaLinux)"
fi

# Run main
main
