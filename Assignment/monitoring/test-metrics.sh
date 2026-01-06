#!/bin/bash

# Test script to generate API traffic and verify metrics

set -e

# Configuration
API_URL="${API_URL:-http://$(minikube ip):30080}"
NUM_REQUESTS="${NUM_REQUESTS:-50}"

echo "=========================================="
echo "API Traffic Generator and Metrics Tester"
echo "=========================================="
echo ""
echo "Configuration:"
echo "  API URL: $API_URL"
echo "  Number of requests: $NUM_REQUESTS"
echo ""

# Test 1: Health check
echo "Test 1: Health Check"
echo "---------------------"
response=$(curl -s "$API_URL/health")
echo "$response" | python3 -m json.tool
echo "✓ Health check passed"
echo ""

# Test 2: Single prediction
echo "Test 2: Single Prediction"
echo "-------------------------"
response=$(curl -s -X POST "$API_URL/predict" \
  -H "Content-Type: application/json" \
  -d '{
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
  }')
echo "$response" | python3 -m json.tool
echo "✓ Single prediction passed"
echo ""

# Test 3: Batch prediction
echo "Test 3: Batch Prediction"
echo "------------------------"
response=$(curl -s -X POST "$API_URL/predict/batch" \
  -H "Content-Type: application/json" \
  -d '{
    "patients": [
      {
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
      },
      {
        "age": 50,
        "sex": 0,
        "cp": 2,
        "trestbps": 120,
        "chol": 200,
        "fbs": 0,
        "restecg": 1,
        "thalach": 160,
        "exang": 0,
        "oldpeak": 1.0,
        "slope": 1,
        "ca": 0,
        "thal": 3
      }
    ]
  }')
echo "$response" | python3 -m json.tool
echo "✓ Batch prediction passed"
echo ""

# Test 4: Generate load
echo "Test 4: Generating Load ($NUM_REQUESTS requests)"
echo "----------------------------------"
echo "Sending requests..."

success=0
failed=0

for i in $(seq 1 $NUM_REQUESTS); do
  # Alternate between different patient profiles
  if [ $((i % 2)) -eq 0 ]; then
    patient_data='{
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
  else
    patient_data='{
      "age": 50,
      "sex": 0,
      "cp": 2,
      "trestbps": 120,
      "chol": 200,
      "fbs": 0,
      "restecg": 1,
      "thalach": 160,
      "exang": 0,
      "oldpeak": 1.0,
      "slope": 1,
      "ca": 0,
      "thal": 3
    }'
  fi

  status_code=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$API_URL/predict" \
    -H "Content-Type: application/json" \
    -d "$patient_data")

  if [ "$status_code" -eq 200 ]; then
    ((success++))
  else
    ((failed++))
  fi

  # Progress indicator
  if [ $((i % 10)) -eq 0 ]; then
    echo "  Progress: $i/$NUM_REQUESTS requests sent (Success: $success, Failed: $failed)"
  fi
done

echo ""
echo "Load generation complete!"
echo "  Total:   $NUM_REQUESTS"
echo "  Success: $success"
echo "  Failed:  $failed"
echo ""

# Test 5: Check metrics endpoint
echo "Test 5: Metrics Endpoint"
echo "------------------------"
echo "Fetching metrics from $API_URL/metrics..."
metrics=$(curl -s "$API_URL/metrics")

# Parse and display key metrics
echo ""
echo "Key Metrics:"
echo ""

# API Requests
echo "API Requests:"
echo "$metrics" | grep "^api_requests_total" | head -5
echo ""

# Predictions
echo "Predictions:"
echo "$metrics" | grep "^predictions_total"
echo ""

# Request Duration
echo "Request Duration (buckets):"
echo "$metrics" | grep "^api_request_duration_seconds_bucket" | head -5
echo ""

# Prediction Latency
echo "Prediction Latency (buckets):"
echo "$metrics" | grep "^prediction_duration_seconds_bucket" | head -5
echo ""

# Model Status
echo "Model Status:"
echo "$metrics" | grep "^model_loaded"
echo ""

# Active Requests
echo "Active Requests:"
echo "$metrics" | grep "^active_requests"
echo ""

# Errors
echo "Errors:"
error_count=$(echo "$metrics" | grep "^api_errors_total" | wc -l)
if [ "$error_count" -gt 0 ]; then
  echo "$metrics" | grep "^api_errors_total"
else
  echo "  No errors recorded ✓"
fi
echo ""

echo "=========================================="
echo "All Tests Complete!"
echo "=========================================="
echo ""
echo "Next Steps:"
echo "1. View metrics in Prometheus:"
echo "   http://$(minikube ip):30090"
echo ""
echo "2. View dashboard in Grafana:"
echo "   http://$(minikube ip):30030"
echo "   Username: admin"
echo "   Password: admin"
echo ""
echo "3. Try these PromQL queries in Prometheus:"
echo "   - rate(api_requests_total[5m])"
echo "   - rate(predictions_total[5m])"
echo "   - histogram_quantile(0.95, rate(api_request_duration_seconds_bucket[5m]))"
echo ""
