#!/bin/bash

# Deploy Prometheus and Grafana for monitoring Heart Disease API
# This script sets up complete monitoring infrastructure

set -e

echo "=========================================="
echo "Deploying Prometheus + Grafana Monitoring"
echo "=========================================="
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl not found. Please install kubectl first."
    exit 1
fi

# Check if namespace exists
echo "Step 1: Checking namespace..."
if ! kubectl get namespace mlops &> /dev/null; then
    echo "Creating mlops namespace..."
    kubectl create namespace mlops
fi
echo "✓ Namespace ready"
echo ""

# Deploy Prometheus
echo "Step 2: Deploying Prometheus..."
kubectl apply -f prometheus-config.yaml
kubectl apply -f prometheus-deployment.yaml
echo "✓ Prometheus deployed"
echo ""

# Wait for Prometheus to be ready
echo "Step 3: Waiting for Prometheus to be ready..."
kubectl wait --for=condition=ready pod -l app=prometheus -n mlops --timeout=120s
echo "✓ Prometheus is ready"
echo ""

# Deploy Grafana
echo "Step 4: Deploying Grafana..."
kubectl apply -f grafana-deployment.yaml
echo "✓ Grafana deployed"
echo ""

# Wait for Grafana to be ready
echo "Step 5: Waiting for Grafana to be ready..."
kubectl wait --for=condition=ready pod -l app=grafana -n mlops --timeout=120s
echo "✓ Grafana is ready"
echo ""

# Get access information
echo "Step 6: Getting access information..."
PROMETHEUS_PORT=$(kubectl get svc prometheus -n mlops -o jsonpath='{.spec.ports[0].nodePort}')
GRAFANA_PORT=$(kubectl get svc grafana -n mlops -o jsonpath='{.spec.ports[0].nodePort}')
MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "localhost")

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "Access URLs:"
echo "  Prometheus: http://$MINIKUBE_IP:$PROMETHEUS_PORT"
echo "  Grafana:    http://$MINIKUBE_IP:$GRAFANA_PORT"
echo ""
echo "Grafana Credentials:"
echo "  Username: admin"
echo "  Password: admin"
echo ""
echo "Next Steps:"
echo "1. Access Grafana at the URL above"
echo "2. Login with admin/admin"
echo "3. Import the dashboard from grafana-dashboard.json"
echo "4. Start making API requests to see metrics"
echo ""
echo "To configure firewall for remote access:"
echo "  sudo firewall-cmd --permanent --add-port=$PROMETHEUS_PORT/tcp"
echo "  sudo firewall-cmd --permanent --add-port=$GRAFANA_PORT/tcp"
echo "  sudo firewall-cmd --reload"
echo ""
echo "To check status:"
echo "  kubectl get pods -n mlops"
echo "  kubectl logs -n mlops -l app=prometheus"
echo "  kubectl logs -n mlops -l app=grafana"
echo ""
