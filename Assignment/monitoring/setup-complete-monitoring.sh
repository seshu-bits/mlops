#!/bin/bash

# Complete Monitoring Setup - All-in-One Script
# This script handles the entire monitoring setup from scratch

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   Heart Disease API - Prometheus + Grafana Monitoring Setup   ║"
echo "║                    Complete Installation                       ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "📂 Directories:"
echo "   Script: $SCRIPT_DIR"
echo "   Project: $PROJECT_ROOT"
echo ""

# Step 1: Check prerequisites
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1: Checking Prerequisites"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check Minikube
if ! command -v minikube &> /dev/null; then
    echo "❌ Minikube not found. Please install Minikube first."
    exit 1
fi
echo "✓ Minikube found"

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install kubectl first."
    exit 1
fi
echo "✓ kubectl found"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker first."
    exit 1
fi
echo "✓ Docker found"

# Check Helm
if ! command -v helm &> /dev/null; then
    echo "❌ Helm not found. Please install Helm first."
    exit 1
fi
echo "✓ Helm found"

# Check if Minikube is running
if ! minikube status &> /dev/null; then
    echo "❌ Minikube is not running. Starting Minikube..."
    minikube start --driver=docker --cpus=2 --memory=4096
else
    echo "✓ Minikube is running"
fi

echo ""

# Step 2: Rebuild API with monitoring support
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2: Rebuilding API with Monitoring Support"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd "$PROJECT_ROOT"

# Use Minikube's Docker daemon
echo "Configuring Docker to use Minikube..."
eval $(minikube docker-env)

# Build Docker image
echo "Building Docker image..."
docker build -t heart-disease-api:latest .
echo "✓ Docker image built"

echo ""

# Step 3: Deploy monitoring stack
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3: Deploying Monitoring Stack"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd "$SCRIPT_DIR"

# Create namespace if it doesn't exist
if ! kubectl get namespace mlops &> /dev/null; then
    echo "Creating mlops namespace..."
    kubectl create namespace mlops
fi
echo "✓ Namespace ready"

# Deploy Prometheus
echo "Deploying Prometheus..."
kubectl apply -f prometheus-config.yaml
kubectl apply -f prometheus-deployment.yaml
echo "✓ Prometheus deployed"

# Wait for Prometheus
echo "Waiting for Prometheus to be ready..."
kubectl wait --for=condition=ready pod -l app=prometheus -n mlops --timeout=120s
echo "✓ Prometheus is ready"

# Deploy Grafana
echo "Deploying Grafana..."
kubectl apply -f grafana-deployment.yaml
echo "✓ Grafana deployed"

# Wait for Grafana
echo "Waiting for Grafana to be ready..."
kubectl wait --for=condition=ready pod -l app=grafana -n mlops --timeout=120s
echo "✓ Grafana is ready"

echo ""

# Step 4: Upgrade API deployment
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 4: Upgrading API Deployment"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd "$PROJECT_ROOT/helm-charts"

# Check if API is already deployed
if helm list -n mlops | grep -q heart-disease-api; then
    echo "Upgrading existing deployment..."
    helm upgrade heart-disease-api ./heart-disease-api \
        --namespace mlops \
        --set image.pullPolicy=Never
else
    echo "Installing new deployment..."
    helm install heart-disease-api ./heart-disease-api \
        --namespace mlops \
        --set image.pullPolicy=Never
fi

# Wait for rollout
echo "Waiting for API rollout to complete..."
kubectl rollout status deployment/heart-disease-api -n mlops --timeout=120s
echo "✓ API deployment updated"

echo ""

# Step 5: Verify deployment
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 5: Verifying Deployment"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "Checking all pods..."
kubectl get pods -n mlops

echo ""
echo "Checking services..."
kubectl get svc -n mlops

echo ""
echo "Testing metrics endpoint..."
MINIKUBE_IP=$(minikube ip)
if curl -s http://$MINIKUBE_IP:30080/metrics | head -5; then
    echo "✓ Metrics endpoint is working"
else
    echo "⚠ Warning: Could not access metrics endpoint"
fi

echo ""

# Step 6: Get access information
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 6: Access Information"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

PROMETHEUS_PORT=$(kubectl get svc prometheus -n mlops -o jsonpath='{.spec.ports[0].nodePort}')
GRAFANA_PORT=$(kubectl get svc grafana -n mlops -o jsonpath='{.spec.ports[0].nodePort}')
API_PORT=$(kubectl get svc heart-disease-api -n mlops -o jsonpath='{.spec.ports[0].nodePort}')

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    🎉 Setup Complete! 🎉                       ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "📊 Access URLs:"
echo "   API:        http://$MINIKUBE_IP:$API_PORT"
echo "   Prometheus: http://$MINIKUBE_IP:$PROMETHEUS_PORT"
echo "   Grafana:    http://$MINIKUBE_IP:$GRAFANA_PORT"
echo ""
echo "🔐 Grafana Credentials:"
echo "   Username: admin"
echo "   Password: admin"
echo ""
echo "📈 Next Steps:"
echo "   1. Access Grafana at http://$MINIKUBE_IP:$GRAFANA_PORT"
echo "   2. Login with admin/admin"
echo "   3. Import dashboard: Click '+' → 'Import' → Upload 'grafana-dashboard.json'"
echo "   4. Generate test traffic: cd $SCRIPT_DIR && ./test-metrics.sh"
echo ""
echo "🧪 Test the API:"
echo "   curl http://$MINIKUBE_IP:$API_PORT/health"
echo "   curl http://$MINIKUBE_IP:$API_PORT/metrics"
echo ""
echo "📚 Documentation:"
echo "   Quick Start: $SCRIPT_DIR/QUICKSTART.md"
echo "   Full Guide:  $SCRIPT_DIR/README.md"
echo "   Summary:     $SCRIPT_DIR/IMPLEMENTATION_SUMMARY.md"
echo ""
echo "🔧 Useful Commands:"
echo "   Check pods:  kubectl get pods -n mlops"
echo "   View logs:   kubectl logs -n mlops -l app.kubernetes.io/name=heart-disease-api"
echo "   Test API:    cd $SCRIPT_DIR && ./test-metrics.sh"
echo "   Cleanup:     cd $SCRIPT_DIR && ./cleanup-monitoring.sh"
echo ""
echo "🌐 For remote access (AlmaLinux), configure firewall:"
echo "   sudo firewall-cmd --permanent --add-port=$API_PORT/tcp"
echo "   sudo firewall-cmd --permanent --add-port=$PROMETHEUS_PORT/tcp"
echo "   sudo firewall-cmd --permanent --add-port=$GRAFANA_PORT/tcp"
echo "   sudo firewall-cmd --reload"
echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "✨ Your monitoring stack is ready! Start making predictions and"
echo "   watch the metrics flow in real-time on Grafana! ✨"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
