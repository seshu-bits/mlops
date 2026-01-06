# 🚀 Running Updated API with Monitoring on AlmaLinux Docker

## Complete Deployment Guide for Monitoring-Enhanced API

This guide shows how to deploy the updated Heart Disease API with Prometheus and Grafana monitoring on AlmaLinux using Minikube with Docker driver.

---

## 📋 Prerequisites

- AlmaLinux 8 server
- Docker installed and running
- Minikube installed
- kubectl installed
- Helm installed
- Internet connection

---

## 🔄 Quick Deployment (Automated)

### Option 1: All-in-One Script

```bash
# SSH to your AlmaLinux server
ssh user@<almalinux-ip>

# Navigate to project
cd ~/workspace/mlops/Assignment

# Pull latest changes
git pull origin main

# Run complete setup
cd monitoring
chmod +x setup-complete-monitoring.sh
./setup-complete-monitoring.sh
```

**This single script will:**
1. ✅ Rebuild Docker image with monitoring support
2. ✅ Deploy Prometheus
3. ✅ Deploy Grafana
4. ✅ Upgrade API deployment
5. ✅ Configure everything automatically

**Time:** ~3-5 minutes

---

## 📖 Step-by-Step Deployment (Manual)

### Step 1: Update Code on AlmaLinux

```bash
# SSH to AlmaLinux server
ssh user@<almalinux-ip>

# Navigate to project directory
cd ~/workspace/mlops

# Pull latest changes from Git
git pull origin main

# Verify new files exist
ls -la Assignment/monitoring/
ls -la Assignment/api_server.py
ls -la Assignment/requirements.txt
```

### Step 2: Start Minikube (if not running)

```bash
# Check if Minikube is running
minikube status

# If not running, start it
minikube start --driver=docker --cpus=2 --memory=4096

# Verify it's running
minikube status
```

### Step 3: Rebuild Docker Image

```bash
# Navigate to Assignment directory
cd ~/workspace/mlops/Assignment

# Point Docker to Minikube's daemon
eval $(minikube docker-env)

# Verify you're using Minikube's Docker
docker info | grep -i "name:"
# Should show something like: Name: minikube

# Build new image with monitoring support
docker build -t heart-disease-api:latest .

# Verify image was built
docker images | grep heart-disease-api
```

### Step 4: Deploy Monitoring Stack

```bash
# Navigate to monitoring directory
cd ~/workspace/mlops/Assignment/monitoring

# Make scripts executable (if not already)
chmod +x *.sh

# Deploy Prometheus and Grafana
./deploy-monitoring.sh
```

**Expected output:**
```
✓ Namespace ready
✓ Prometheus deployed
✓ Prometheus is ready
✓ Grafana deployed
✓ Grafana is ready

Access URLs:
  Prometheus: http://<MINIKUBE_IP>:30090
  Grafana:    http://<MINIKUBE_IP>:30030
```

### Step 5: Update API Deployment

```bash
# Navigate to helm charts directory
cd ~/workspace/mlops/Assignment/helm-charts

# Check if API is already deployed
helm list -n mlops

# Upgrade existing deployment
helm upgrade heart-disease-api ./heart-disease-api \
  --namespace mlops \
  --set image.pullPolicy=Never \
  --set image.tag=latest

# Wait for rollout to complete
kubectl rollout status deployment/heart-disease-api -n mlops --timeout=120s
```

### Step 6: Configure Firewall for Remote Access

```bash
# Get NodePorts
API_PORT=$(kubectl get svc heart-disease-api -n mlops -o jsonpath='{.spec.ports[0].nodePort}')
PROMETHEUS_PORT=$(kubectl get svc prometheus -n mlops -o jsonpath='{.spec.ports[0].nodePort}')
GRAFANA_PORT=$(kubectl get svc grafana -n mlops -o jsonpath='{.spec.ports[0].nodePort}')

echo "API Port: $API_PORT"
echo "Prometheus Port: $PROMETHEUS_PORT"
echo "Grafana Port: $GRAFANA_PORT"

# Open ports in firewall
sudo firewall-cmd --permanent --add-port=${API_PORT}/tcp
sudo firewall-cmd --permanent --add-port=${PROMETHEUS_PORT}/tcp
sudo firewall-cmd --permanent --add-port=${GRAFANA_PORT}/tcp
sudo firewall-cmd --reload

# Verify firewall rules
sudo firewall-cmd --list-ports
```

### Step 7: Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n mlops

# You should see:
# - heart-disease-api pods (2 replicas)
# - prometheus pod
# - grafana pod

# Check all services
kubectl get svc -n mlops

# Test API health
MINIKUBE_IP=$(minikube ip)
curl http://$MINIKUBE_IP:$API_PORT/health

# Test metrics endpoint
curl http://$MINIKUBE_IP:$API_PORT/metrics | head -20
```

### Step 8: Access from Remote Machine

```bash
# Get AlmaLinux server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

echo "=========================================="
echo "Access from Remote Machine:"
echo "=========================================="
echo "API:        http://$SERVER_IP:$API_PORT"
echo "Metrics:    http://$SERVER_IP:$API_PORT/metrics"
echo "Prometheus: http://$SERVER_IP:$PROMETHEUS_PORT"
echo "Grafana:    http://$SERVER_IP:$GRAFANA_PORT"
echo ""
echo "Grafana Login:"
echo "  Username: admin"
echo "  Password: admin"
```

---

## 🧪 Testing the Deployment

### Test 1: Health Check

```bash
# From AlmaLinux server
MINIKUBE_IP=$(minikube ip)
API_PORT=$(kubectl get svc heart-disease-api -n mlops -o jsonpath='{.spec.ports[0].nodePort}')

curl http://$MINIKUBE_IP:$API_PORT/health

# Expected response:
# {"status":"healthy","model_loaded":true,"model_name":"logistic_regression"}
```

### Test 2: Metrics Endpoint

```bash
# View Prometheus metrics
curl http://$MINIKUBE_IP:$API_PORT/metrics

# You should see metrics like:
# api_requests_total{...}
# prediction_duration_seconds{...}
# model_loaded 1.0
```

### Test 3: Single Prediction

```bash
curl -X POST http://$MINIKUBE_IP:$API_PORT/predict \
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
  }'

# Expected response:
# {"prediction":1,"confidence":0.85,"model_name":"logistic_regression"}
```

### Test 4: Generate Traffic

```bash
# Navigate to monitoring directory
cd ~/workspace/mlops/Assignment/monitoring

# Run test script
./test-metrics.sh

# This will:
# - Make health checks
# - Run single and batch predictions
# - Generate 50 test requests
# - Display metrics summary
```

### Test 5: Access Prometheus

```bash
# Get Prometheus URL
PROMETHEUS_PORT=$(kubectl get svc prometheus -n mlops -o jsonpath='{.spec.ports[0].nodePort}')
SERVER_IP=$(hostname -I | awk '{print $1}')

echo "Prometheus: http://$SERVER_IP:$PROMETHEUS_PORT"

# Open in browser on your remote machine
# Check: http://<SERVER_IP>:30090/targets
# The heart-disease-api target should show as "UP"
```

### Test 6: Access Grafana

```bash
# Get Grafana URL
GRAFANA_PORT=$(kubectl get svc grafana -n mlops -o jsonpath='{.spec.ports[0].nodePort}')
SERVER_IP=$(hostname -I | awk '{print $1}')

echo "Grafana: http://$SERVER_IP:$GRAFANA_PORT"
echo "Login: admin / admin"

# Open in browser on your remote machine
# 1. Login with admin/admin
# 2. Click "+" → "Import"
# 3. Upload: monitoring/grafana-dashboard.json
# 4. Select Prometheus datasource
# 5. Click Import
```

---

## 🔍 Verification Checklist

Run these commands to verify everything is working:

```bash
# Create verification script
cat > ~/verify-deployment.sh << 'EOF'
#!/bin/bash

echo "╔════════════════════════════════════════════════════╗"
echo "║   Verifying Monitoring-Enhanced API Deployment    ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""

# 1. Check Minikube
echo "1. Minikube Status:"
minikube status
echo ""

# 2. Check Pods
echo "2. Pod Status:"
kubectl get pods -n mlops
echo ""

# 3. Check Services
echo "3. Service Status:"
kubectl get svc -n mlops
echo ""

# 4. Test API Health
echo "4. API Health Check:"
MINIKUBE_IP=$(minikube ip)
API_PORT=$(kubectl get svc heart-disease-api -n mlops -o jsonpath='{.spec.ports[0].nodePort}')
curl -s http://$MINIKUBE_IP:$API_PORT/health | python3 -m json.tool
echo ""

# 5. Test Metrics
echo "5. Metrics Endpoint (first 10 lines):"
curl -s http://$MINIKUBE_IP:$API_PORT/metrics | head -10
echo ""

# 6. Check Prometheus
echo "6. Prometheus Status:"
kubectl get pods -n mlops -l app=prometheus
echo ""

# 7. Check Grafana
echo "7. Grafana Status:"
kubectl get pods -n mlops -l app=grafana
echo ""

# 8. Get Access URLs
echo "8. Access URLs:"
SERVER_IP=$(hostname -I | awk '{print $1}')
PROM_PORT=$(kubectl get svc prometheus -n mlops -o jsonpath='{.spec.ports[0].nodePort}')
GRAF_PORT=$(kubectl get svc grafana -n mlops -o jsonpath='{.spec.ports[0].nodePort}')

echo "   API:        http://$SERVER_IP:$API_PORT"
echo "   Prometheus: http://$SERVER_IP:$PROM_PORT"
echo "   Grafana:    http://$SERVER_IP:$GRAF_PORT"
echo ""

echo "╔════════════════════════════════════════════════════╗"
echo "║              Verification Complete                 ║"
echo "╚════════════════════════════════════════════════════╝"
EOF

chmod +x ~/verify-deployment.sh
~/verify-deployment.sh
```

---

## 🔧 Troubleshooting

### Issue 1: Docker Build Fails

```bash
# Check if using Minikube's Docker
eval $(minikube docker-env)
docker info | grep Name

# If still fails, check Dockerfile
cd ~/workspace/mlops/Assignment
cat Dockerfile

# Try building with no cache
docker build --no-cache -t heart-disease-api:latest .
```

### Issue 2: Pods Not Starting

```bash
# Check pod status
kubectl get pods -n mlops

# Describe pod to see errors
POD_NAME=$(kubectl get pods -n mlops -l app.kubernetes.io/name=heart-disease-api -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod $POD_NAME -n mlops

# Check logs
kubectl logs -n mlops $POD_NAME

# Common fix: Delete pod and let it recreate
kubectl delete pod $POD_NAME -n mlops
```

### Issue 3: Metrics Endpoint Returns 404

```bash
# This means API wasn't rebuilt with new code

# Rebuild image
cd ~/workspace/mlops/Assignment
eval $(minikube docker-env)
docker build -t heart-disease-api:latest .

# Restart deployment
kubectl rollout restart deployment/heart-disease-api -n mlops

# Wait for rollout
kubectl rollout status deployment/heart-disease-api -n mlops
```

### Issue 4: Cannot Access from Remote

```bash
# Check firewall
sudo firewall-cmd --list-all

# Temporarily disable to test (TESTING ONLY!)
sudo systemctl stop firewalld
# Try access from remote
# If works, re-enable and add proper rules
sudo systemctl start firewalld

# Add rules properly
API_PORT=$(kubectl get svc heart-disease-api -n mlops -o jsonpath='{.spec.ports[0].nodePort}')
sudo firewall-cmd --permanent --add-port=${API_PORT}/tcp
sudo firewall-cmd --reload

# Check if SELinux is blocking
sudo getenforce
# If Enforcing, temporarily set to permissive for testing
sudo setenforce 0
# Test, then re-enable
sudo setenforce 1
```

### Issue 5: Prometheus Not Scraping

```bash
# Check Prometheus targets
PROM_PORT=$(kubectl get svc prometheus -n mlops -o jsonpath='{.spec.ports[0].nodePort}')
echo "Check: http://$(minikube ip):$PROM_PORT/targets"

# Check if API service is reachable from Prometheus
kubectl exec -n mlops deployment/prometheus -- wget -O- http://heart-disease-api:80/metrics

# If fails, check service endpoints
kubectl get endpoints -n mlops heart-disease-api

# Restart Prometheus
kubectl rollout restart deployment/prometheus -n mlops
```

### Issue 6: Image Not Found

```bash
# Make sure you're using Never pull policy
helm upgrade heart-disease-api ./heart-disease-api \
  --namespace mlops \
  --set image.pullPolicy=Never \
  --set image.repository=heart-disease-api \
  --set image.tag=latest

# Verify image exists in Minikube
eval $(minikube docker-env)
docker images | grep heart-disease-api
```

---

## 🔄 Update Workflow

When you make changes to the code:

```bash
# 1. Pull latest code
cd ~/workspace/mlops
git pull origin main

# 2. Rebuild image
cd Assignment
eval $(minikube docker-env)
docker build -t heart-disease-api:latest .

# 3. Restart deployment
kubectl rollout restart deployment/heart-disease-api -n mlops

# 4. Wait for rollout
kubectl rollout status deployment/heart-disease-api -n mlops

# 5. Verify
curl http://$(minikube ip):30080/health
curl http://$(minikube ip):30080/metrics | head -20
```

---

## 📊 Monitoring Access

### From AlmaLinux Server (Local)

```bash
# Get Minikube IP
MINIKUBE_IP=$(minikube ip)

# Access services
curl http://$MINIKUBE_IP:30080/health       # API
open http://$MINIKUBE_IP:30090              # Prometheus
open http://$MINIKUBE_IP:30030              # Grafana
```

### From Remote Machine

```bash
# Get AlmaLinux server IP
# Then from remote machine:

SERVER_IP=<your-almalinux-ip>

# Access via browser or curl
curl http://$SERVER_IP:30080/health         # API
http://$SERVER_IP:30090                     # Prometheus (browser)
http://$SERVER_IP:30030                     # Grafana (browser)
```

---

## 📈 Viewing Metrics

### In Prometheus

1. Access: `http://<SERVER_IP>:30090`
2. Go to "Graph" tab
3. Try these queries:

```promql
# Request rate
rate(api_requests_total[5m])

# Average latency
rate(api_request_duration_seconds_sum[5m]) / rate(api_request_duration_seconds_count[5m])

# Predictions per second
rate(predictions_total[5m])

# Error rate
rate(api_errors_total[5m])
```

### In Grafana

1. Access: `http://<SERVER_IP>:30030`
2. Login: `admin` / `admin`
3. Click "+" → "Import"
4. Upload: `~/workspace/mlops/Assignment/monitoring/grafana-dashboard.json`
5. Select "Prometheus" datasource
6. Click "Import"
7. View real-time metrics!

---

## 🛑 Stopping/Starting

### Stop Everything

```bash
# Stop Minikube (stops all services)
minikube stop

# Or remove monitoring only
cd ~/workspace/mlops/Assignment/monitoring
./cleanup-monitoring.sh
```

### Start After Reboot

```bash
# Start Minikube
minikube start

# Everything should auto-start
# Verify
kubectl get pods -n mlops

# If monitoring not running, redeploy
cd ~/workspace/mlops/Assignment/monitoring
./deploy-monitoring.sh
```

---

## 📝 Quick Reference Commands

```bash
# Check status
kubectl get pods -n mlops
kubectl get svc -n mlops

# View logs
kubectl logs -n mlops -l app.kubernetes.io/name=heart-disease-api
kubectl logs -n mlops -l app=prometheus
kubectl logs -n mlops -l app=grafana

# Restart components
kubectl rollout restart deployment/heart-disease-api -n mlops
kubectl rollout restart deployment/prometheus -n mlops
kubectl rollout restart deployment/grafana -n mlops

# Test API
curl http://$(minikube ip):30080/health
curl http://$(minikube ip):30080/metrics

# Generate traffic
cd ~/workspace/mlops/Assignment/monitoring
./test-metrics.sh

# Get access URLs
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "API: http://$SERVER_IP:30080"
echo "Prometheus: http://$SERVER_IP:30090"
echo "Grafana: http://$SERVER_IP:30030"
```

---

## ✅ Success Indicators

You'll know it's working when:

1. ✅ All pods show "Running" status
2. ✅ `/health` endpoint returns healthy
3. ✅ `/metrics` endpoint shows Prometheus metrics
4. ✅ Prometheus shows heart-disease-api target as "UP"
5. ✅ Grafana connects to Prometheus
6. ✅ Dashboard shows real-time metrics
7. ✅ Remote access works from your machine

---

## 🎯 Summary

**To deploy the updated monitoring-enhanced API:**

```bash
# Quick version (recommended)
cd ~/workspace/mlops/Assignment/monitoring
./setup-complete-monitoring.sh

# Manual version
cd ~/workspace/mlops
git pull origin main
cd Assignment
eval $(minikube docker-env)
docker build -t heart-disease-api:latest .
cd monitoring
./deploy-monitoring.sh
cd ../helm-charts
helm upgrade heart-disease-api ./heart-disease-api -n mlops --set image.pullPolicy=Never
```

**Then access:**
- API: `http://<SERVER_IP>:30080`
- Prometheus: `http://<SERVER_IP>:30090`
- Grafana: `http://<SERVER_IP>:30030` (admin/admin)

That's it! Your monitoring-enhanced API is now running on AlmaLinux with Docker! 🚀
