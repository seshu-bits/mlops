#!/bin/bash

# Test MLOps Deployment Script
# Tests all deployed services to verify they are working correctly

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SERVER_IP="72.163.219.91"
MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "")

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              MLOps Deployment Test Suite                      ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

test_passed=0
test_failed=0

# Function to test endpoint
test_endpoint() {
    local name=$1
    local url=$2
    local host_header=$3

    echo -ne "Testing $name... "

    if [ -n "$host_header" ]; then
        response=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: $host_header" "$url" --max-time 10)
    else
        response=$(curl -s -o /dev/null -w "%{http_code}" "$url" --max-time 10)
    fi

    if [ "$response" = "200" ] || [ "$response" = "302" ]; then
        echo -e "${GREEN}✓ PASS${NC} (HTTP $response)"
        ((test_passed++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC} (HTTP $response)"
        ((test_failed++))
        return 1
    fi
}

# Test Kubernetes resources
echo -e "${YELLOW}Testing Kubernetes Resources...${NC}\n"

echo "Checking namespace..."
if kubectl get namespace mlops &> /dev/null; then
    echo -e "${GREEN}✓ Namespace mlops exists${NC}"
    ((test_passed++))
else
    echo -e "${RED}✗ Namespace mlops not found${NC}"
    ((test_failed++))
fi

echo -e "\nChecking pods..."
pod_count=$(kubectl get pods -n mlops --no-headers 2>/dev/null | wc -l)
running_pods=$(kubectl get pods -n mlops --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
echo "Total pods: $pod_count, Running: $running_pods"

if [ "$running_pods" -ge 5 ]; then
    echo -e "${GREEN}✓ All expected pods are running${NC}"
    ((test_passed++))
else
    echo -e "${YELLOW}⚠ Some pods may not be running${NC}"
    kubectl get pods -n mlops
fi

# Test services
echo -e "\n${YELLOW}Testing Services...${NC}\n"

services=("heart-disease-api" "prometheus" "grafana" "mlflow")
for svc in "${services[@]}"; do
    echo -ne "Service $svc... "
    if kubectl get svc "$svc" -n mlops &> /dev/null; then
        echo -e "${GREEN}✓ EXISTS${NC}"
        ((test_passed++))
    else
        echo -e "${RED}✗ NOT FOUND${NC}"
        ((test_failed++))
    fi
done

# Test ingress
echo -e "\n${YELLOW}Testing Ingress...${NC}\n"

echo -ne "Ingress mlops-ingress... "
if kubectl get ingress mlops-ingress -n mlops &> /dev/null; then
    echo -e "${GREEN}✓ EXISTS${NC}"
    ((test_passed++))
else
    echo -e "${RED}✗ NOT FOUND${NC}"
    ((test_failed++))
fi

echo -ne "Ingress mlops-ingress-ip... "
if kubectl get ingress mlops-ingress-ip -n mlops &> /dev/null; then
    echo -e "${GREEN}✓ EXISTS${NC}"
    ((test_passed++))
else
    echo -e "${RED}✗ NOT FOUND${NC}"
    ((test_failed++))
fi

# Test local endpoints (Minikube IP)
if [ -n "$MINIKUBE_IP" ]; then
    echo -e "\n${YELLOW}Testing Local Endpoints (Minikube IP: $MINIKUBE_IP)...${NC}\n"

    test_endpoint "API Health" "http://$MINIKUBE_IP/health" "api.mlops.local"
    test_endpoint "API Docs" "http://$MINIKUBE_IP/docs" "api.mlops.local"
    test_endpoint "API Metrics" "http://$MINIKUBE_IP/metrics" "api.mlops.local"
    test_endpoint "Prometheus" "http://$MINIKUBE_IP/" "prometheus.mlops.local"
    test_endpoint "Grafana" "http://$MINIKUBE_IP/" "grafana.mlops.local"
    test_endpoint "MLflow" "http://$MINIKUBE_IP/" "mlflow.mlops.local"
else
    echo -e "${YELLOW}⚠ Minikube IP not available, skipping local tests${NC}"
fi

# Test remote endpoints (Server IP)
echo -e "\n${YELLOW}Testing Remote Endpoints (Server IP: $SERVER_IP)...${NC}\n"

test_endpoint "API Health (Remote)" "http://$SERVER_IP/health"
test_endpoint "API Docs (Remote)" "http://$SERVER_IP/docs"
test_endpoint "Prometheus (Remote)" "http://$SERVER_IP:9090/"
test_endpoint "Grafana (Remote)" "http://$SERVER_IP:3000/"
test_endpoint "MLflow (Remote)" "http://$SERVER_IP:5000/"

# Test API functionality
echo -e "\n${YELLOW}Testing API Functionality...${NC}\n"

# Test prediction endpoint
echo -ne "Testing prediction endpoint... "
prediction_response=$(curl -s -X POST "http://$SERVER_IP/predict" \
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
    }' --max-time 10 2>/dev/null)

if echo "$prediction_response" | grep -q "prediction"; then
    echo -e "${GREEN}✓ PASS${NC}"
    echo "Response: $prediction_response"
    ((test_passed++))
else
    echo -e "${RED}✗ FAIL${NC}"
    ((test_failed++))
fi

# Test batch prediction
echo -ne "Testing batch prediction endpoint... "
batch_response=$(curl -s -X POST "http://$SERVER_IP/predict/batch" \
    -H "Content-Type: application/json" \
    -d '{
        "instances": [
            {
                "age": 63, "sex": 1, "cp": 3, "trestbps": 145, "chol": 233,
                "fbs": 1, "restecg": 0, "thalach": 150, "exang": 0,
                "oldpeak": 2.3, "slope": 0, "ca": 0, "thal": 1
            }
        ]
    }' --max-time 10 2>/dev/null)

if echo "$batch_response" | grep -q "predictions"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((test_passed++))
else
    echo -e "${RED}✗ FAIL${NC}"
    ((test_failed++))
fi

# Check Prometheus metrics
echo -e "\n${YELLOW}Checking Prometheus Metrics...${NC}\n"

echo -ne "Fetching metrics... "
metrics=$(curl -s "http://$SERVER_IP/metrics" --max-time 10)

if echo "$metrics" | grep -q "api_requests_total"; then
    echo -e "${GREEN}✓ Metrics available${NC}"
    ((test_passed++))

    # Show some key metrics
    echo ""
    echo "Sample metrics:"
    echo "$metrics" | grep -E "api_requests_total|predictions_total|model_loaded" | head -5
else
    echo -e "${RED}✗ Metrics not available${NC}"
    ((test_failed++))
fi

# Check Minikube tunnel
echo -e "\n${YELLOW}Checking Minikube Tunnel...${NC}\n"

if pgrep -f "minikube tunnel" > /dev/null; then
    echo -e "${GREEN}✓ Minikube tunnel is running${NC}"
    ((test_passed++))
else
    echo -e "${RED}✗ Minikube tunnel is not running${NC}"
    echo "  Run: minikube tunnel"
    ((test_failed++))
fi

# Check Nginx
echo -e "\n${YELLOW}Checking Nginx...${NC}\n"

if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✓ Nginx is running${NC}"
    ((test_passed++))
else
    echo -e "${RED}✗ Nginx is not running${NC}"
    ((test_failed++))
fi

# Summary
echo -e "\n${BLUE}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                       Test Summary                             ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${GREEN}Passed: $test_passed${NC}"
echo -e "${RED}Failed: $test_failed${NC}"
echo ""

if [ $test_failed -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed! Deployment is working correctly.${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠ Some tests failed. Check the output above for details.${NC}"
    echo ""
    echo "Common issues:"
    echo "  1. Services still starting up (wait a few minutes)"
    echo "  2. Minikube tunnel not running (run: minikube tunnel)"
    echo "  3. Nginx not configured (run deploy-complete-almalinux.sh)"
    echo "  4. Firewall blocking ports (check: sudo firewall-cmd --list-all)"
    exit 1
fi
