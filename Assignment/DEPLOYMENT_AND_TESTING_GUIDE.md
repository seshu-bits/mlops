# 🚀 Complete Deployment and Testing Guide with Monitoring

This comprehensive guide covers the entire deployment process including Prometheus and Grafana monitoring setup.

---

## 📋 Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Pre-Deployment Setup](#2-pre-deployment-setup)
3. [Deploy the Application](#3-deploy-the-application)
4. [Deploy Monitoring Stack](#4-deploy-monitoring-stack)
5. [Verify Deployment](#5-verify-deployment)
6. [Test the API](#6-test-the-api)
7. [Configure Grafana Dashboard](#7-configure-grafana-dashboard)
8. [Generate Test Traffic](#8-generate-test-traffic)
9. [Remote Access Setup (Optional)](#9-remote-access-setup-optional)
10. [Troubleshooting](#10-troubleshooting)

---

## 1️⃣ Prerequisites

### Required Software

Install the following before proceeding:

```bash
# Check if tools are installed
minikube version
kubectl version --client
helm version
docker --version
```

### Installation Commands (if needed)

**macOS:**
```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required tools
brew install kubectl
brew install helm
brew install minikube
brew install --cask docker
```

**Linux (AlmaLinux/RHEL/CentOS):**
```bash
# Docker
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo systemctl enable docker

# Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

---

## 2️⃣ Pre-Deployment Setup

### Step 1: Clone Repository

```bash
git clone https://github.com/seshu-bits/mlops.git
cd mlops/Assignment
```

### Step 2: Start Minikube

```bash
# Start Minikube with sufficient resources
minikube start --driver=docker --cpus=2 --memory=4096

# Verify it's running
minikube status
```

Expected output:
```
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

### Step 3: Enable Required Addons

```bash
# Enable metrics server (for HPA)
minikube addons enable metrics-server

# Verify addon is enabled
minikube addons list | grep metrics-server
```

### Step 4: Prepare Docker Environment

```bash
# Configure shell to use Minikube's Docker daemon
eval $(minikube docker-env)

# Verify
docker info | grep -i "Name:"
# Should show something like "Name: minikube"
```

---

## 3️⃣ Deploy the Application

### Option A: Automated Deployment (Recommended)

```bash
cd helm-charts
./deploy.sh
```

This script will:
- ✅ Check all prerequisites
- ✅ Build the Docker image
- ✅ Deploy using Helm
- ✅ Verify the deployment
- ✅ Test the API
- ✅ Display access information

### Option B: Manual Step-by-Step Deployment

**Step 1: Build Docker Image**

```bash
# Navigate to project root
cd /path/to/mlops/Assignment

# Use Minikube's Docker daemon
eval $(minikube docker-env)

# Build the image
docker build -t heart-disease-api:latest .

# Verify image was built
docker images | grep heart-disease-api
```

**Step 2: Install Helm Chart**

```bash
cd helm-charts

# Install the application
helm install heart-disease-api ./heart-disease-api \
  --namespace mlops \
  --create-namespace \
  --set image.pullPolicy=Never \
  --wait \
  --timeout 5m
```

**Step 3: Verify Deployment**

```bash
# Check pods
kubectl get pods -n mlops

# Check services
kubectl get svc -n mlops

# Check deployment status
kubectl rollout status deployment/heart-disease-api -n mlops
```

Expected output:
```
NAME                                  READY   STATUS    RESTARTS   AGE
heart-disease-api-xxxxxxxxxx-xxxxx    1/1     Running   0          30s
```

---

## 4️⃣ Deploy Monitoring Stack

### Option A: Complete Automated Setup (Recommended)

```bash
cd monitoring
./setup-complete-monitoring.sh
```

This will:
- ✅ Deploy Prometheus for metrics collection
- ✅ Deploy Grafana for visualization
- ✅ Rebuild API with monitoring support
- ✅ Configure service monitors
- ✅ Display access URLs

### Option B: Manual Monitoring Setup

**Step 1: Deploy Prometheus**

```bash
cd monitoring

# Create namespace (if not exists)
kubectl create namespace mlops --dry-run=client -o yaml | kubectl apply -f -

# Deploy Prometheus config
kubectl apply -f prometheus-config.yaml

# Deploy Prometheus
kubectl apply -f prometheus-deployment.yaml

# Wait for Prometheus to be ready
kubectl wait --for=condition=ready pod -l app=prometheus -n mlops --timeout=120s
```

**Step 2: Deploy Grafana**

```bash
# Deploy Grafana
kubectl apply -f grafana-deployment.yaml

# Wait for Grafana to be ready
kubectl wait --for=condition=ready pod -l app=grafana -n mlops --timeout=120s
```

**Step 3: Get Service URLs**

```bash
# Get Minikube IP
MINIKUBE_IP=$(minikube ip)

# Get service ports
kubectl get svc -n mlops

echo "Prometheus: http://$MINIKUBE_IP:30090"
echo "Grafana: http://$MINIKUBE_IP:3000"
echo "API: http://$MINIKUBE_IP:30080"
```

---

## 5️⃣ Verify Deployment

### Check All Pods

```bash
kubectl get pods -n mlops
```

All pods should be in `Running` state with `1/1` or `2/2` ready.

### Check Services

```bash
kubectl get svc -n mlops
```

Expected services:
- `heart-disease-api` (NodePort: 30080)
- `prometheus` (NodePort: 30090)
- `grafana` (NodePort: 3000)

### Check Logs

```bash
# API logs
kubectl logs -l app=heart-disease-api -n mlops --tail=50

# Prometheus logs
kubectl logs -l app=prometheus -n mlops --tail=50

# Grafana logs
kubectl logs -l app=grafana -n mlops --tail=50
```

### Test Health Endpoint

```bash
MINIKUBE_IP=$(minikube ip)
curl http://$MINIKUBE_IP:30080/health
```

Expected response:
```json
{"status":"healthy","model_loaded":true}
```

### Test Metrics Endpoint

```bash
curl http://$MINIKUBE_IP:30080/metrics
```

Should see Prometheus metrics format:
```
# HELP api_requests_total Total number of requests
# TYPE api_requests_total counter
api_requests_total{endpoint="/health",method="GET"} 1.0
...
```

---

## 6️⃣ Test the API

### Test with cURL

**1. Health Check**
```bash
MINIKUBE_IP=$(minikube ip)
curl http://$MINIKUBE_IP:30080/health
```

**2. Single Prediction**
```bash
curl -X POST "http://$MINIKUBE_IP:30080/predict" \
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
```

Expected response:
```json
{
  "prediction": 1,
  "risk_level": "high",
  "model_used": "Logistic Regression",
  "confidence": 0.85
}
```

**3. Batch Prediction**
```bash
curl -X POST "http://$MINIKUBE_IP:30080/predict_batch" \
  -H "Content-Type: application/json" \
  -d @sample_batch_input.json
```

### Test with Python Script

Create a test script `test_api.py`:

```python
import requests
import json

# Configuration
MINIKUBE_IP = "192.168.49.2"  # Replace with your Minikube IP
API_URL = f"http://{MINIKUBE_IP}:30080"

# Test data
test_input = {
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
}

# Test health
response = requests.get(f"{API_URL}/health")
print("Health Check:", response.json())

# Test prediction
response = requests.post(f"{API_URL}/predict", json=test_input)
print("Prediction:", response.json())
```

Run the script:
```bash
python test_api.py
```

### Use Automated Test Script

```bash
cd helm-charts
./test-api.sh
```

This will run comprehensive API tests.

---

## 7️⃣ Configure Grafana Dashboard

### Step 1: Access Grafana

```bash
MINIKUBE_IP=$(minikube ip)
echo "Grafana URL: http://$MINIKUBE_IP:3000"
```

Open the URL in your browser.

### Step 2: Login

- **Username:** `admin`
- **Password:** `admin`

You'll be prompted to change the password on first login.

### Step 3: Add Prometheus Data Source

1. Click the **gear icon** (⚙️) on the left sidebar
2. Select **Data Sources**
3. Click **Add data source**
4. Select **Prometheus**
5. Configure:
   - **Name:** `Prometheus`
   - **URL:** `http://prometheus:9090`
6. Click **Save & Test**

Should see: "Data source is working"

### Step 4: Import Pre-configured Dashboard

1. Click the **+** icon on the left sidebar
2. Select **Import**
3. Click **Upload JSON file**
4. Navigate to `monitoring/grafana-dashboard.json`
5. Select it and upload
6. Select **Prometheus** as the data source
7. Click **Import**

### Dashboard Panels Include:

- 📊 **API Request Rate** - Requests per second
- ⏱️ **API Latency** - Response times (p50, p95, p99)
- 🎯 **Prediction Metrics** - Total predictions and duration
- ❌ **Error Rate** - Failed requests
- 📈 **Confidence Score Distribution** - Model confidence histogram
- 🏥 **Model Health** - Model load status
- 🔥 **Active Requests** - Current concurrent requests

---

## 8️⃣ Generate Test Traffic

### Automated Test Traffic

```bash
cd monitoring
./test-metrics.sh
```

This script will:
- Send 100 test predictions
- Mix of different input patterns
- Display response times
- Show metrics summary

### Manual Test Traffic

```bash
MINIKUBE_IP=$(minikube ip)

# Send multiple requests
for i in {1..50}; do
  curl -X POST "http://$MINIKUBE_IP:30080/predict" \
    -H "Content-Type: application/json" \
    -d '{
      "age": '$((50 + RANDOM % 30))',
      "sex": '$((RANDOM % 2))',
      "cp": '$((RANDOM % 4))',
      "trestbps": '$((120 + RANDOM % 40))',
      "chol": '$((200 + RANDOM % 100))',
      "fbs": '$((RANDOM % 2))',
      "restecg": '$((RANDOM % 3))',
      "thalach": '$((120 + RANDOM % 80))',
      "exang": '$((RANDOM % 2))',
      "oldpeak": '$((RANDOM % 5))',
      "slope": '$((RANDOM % 3))',
      "ca": '$((RANDOM % 4))',
      "thal": '$((1 + RANDOM % 3))'
    }' &
done

wait
echo "Test traffic generation complete!"
```

### View Live Metrics

**In Prometheus:**
```
http://<MINIKUBE_IP>:30090
```

Query examples:
```promql
# Request rate
rate(api_requests_total[5m])

# Average latency
rate(api_request_duration_seconds_sum[5m]) / rate(api_request_duration_seconds_count[5m])

# Error rate
rate(api_errors_total[5m])
```

**In Grafana:**
- Navigate to your imported dashboard
- Set time range to "Last 5 minutes"
- Click refresh or enable auto-refresh

---

## 9️⃣ Remote Access Setup (Optional)

If you want to access the services remotely from other machines:

### Option A: Using nginx-proxy (Recommended for production-like setup)

```bash
cd /path/to/mlops/Assignment
./setup-nginx-proxy.sh
```

This configures nginx as a reverse proxy with authentication.

### Option B: Using Minikube Tunnel

```bash
# Run in a separate terminal
minikube tunnel

# Keep this running - it exposes services on localhost
```

Then access services on `localhost`:
- API: http://localhost:30080
- Prometheus: http://localhost:30090
- Grafana: http://localhost:3000

### Option C: Port Forwarding (Development)

```bash
# API
kubectl port-forward -n mlops svc/heart-disease-api 8080:8080

# Prometheus
kubectl port-forward -n mlops svc/prometheus 9090:9090

# Grafana
kubectl port-forward -n mlops svc/grafana 3000:3000
```

Access on:
- API: http://localhost:8080
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000

---

## 🔟 Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n mlops

# Describe pod for details
kubectl describe pod <pod-name> -n mlops

# Check logs
kubectl logs <pod-name> -n mlops
```

Common issues:
- **ImagePullBackOff**: Run `eval $(minikube docker-env)` and rebuild
- **CrashLoopBackOff**: Check logs for application errors

### Prometheus Not Scraping

```bash
# Check Prometheus targets
# Open: http://<MINIKUBE_IP>:30090/targets

# Verify API metrics endpoint
curl http://<MINIKUBE_IP>:30080/metrics

# Restart Prometheus
kubectl rollout restart deployment/prometheus -n mlops
```

### Grafana Dashboard Not Showing Data

1. **Check Data Source**: Settings → Data Sources → Prometheus → Test
2. **Check Query**: Dashboard → Panel → Edit → Check query syntax
3. **Check Time Range**: Ensure time range includes when you sent requests
4. **Generate Traffic**: Run `./test-metrics.sh` to generate data

### Cannot Access Services

```bash
# Check Minikube status
minikube status

# Check if services are exposed
kubectl get svc -n mlops

# Check Minikube IP
minikube ip

# Test connectivity
curl http://$(minikube ip):30080/health
```

### API Returns 500 Error

```bash
# Check API logs
kubectl logs -l app=heart-disease-api -n mlops --tail=100

# Check if models are loaded
curl http://$(minikube ip):30080/health

# Restart API
kubectl rollout restart deployment/heart-disease-api -n mlops
```

### Memory/CPU Issues

```bash
# Check resource usage
kubectl top nodes
kubectl top pods -n mlops

# Increase Minikube resources
minikube stop
minikube start --driver=docker --cpus=4 --memory=8192

# Redeploy
cd helm-charts
./deploy.sh
```

---

## 📊 Complete Deployment Verification Checklist

Use this checklist to ensure everything is working:

- [ ] Minikube is running (`minikube status`)
- [ ] All pods are running (`kubectl get pods -n mlops`)
- [ ] API health check passes (`curl http://<IP>:30080/health`)
- [ ] Single prediction works (`curl -X POST http://<IP>:30080/predict ...`)
- [ ] Batch prediction works (`curl -X POST http://<IP>:30080/predict_batch ...`)
- [ ] Metrics endpoint accessible (`curl http://<IP>:30080/metrics`)
- [ ] Prometheus UI accessible (`http://<IP>:30090`)
- [ ] Prometheus is scraping API (`Check targets page`)
- [ ] Grafana UI accessible (`http://<IP>:3000`)
- [ ] Grafana dashboard shows data
- [ ] Test traffic generates visible metrics

---

## 🎯 Quick Reference Commands

```bash
# Get all resources
kubectl get all -n mlops

# Get Minikube IP
minikube ip

# Check API health
curl http://$(minikube ip):30080/health

# Check metrics
curl http://$(minikube ip):30080/metrics

# Open Prometheus
open http://$(minikube ip):30090

# Open Grafana
open http://$(minikube ip):3000

# View API logs
kubectl logs -f -l app=heart-disease-api -n mlops

# Restart API
kubectl rollout restart deployment/heart-disease-api -n mlops

# Clean up everything
helm uninstall heart-disease-api -n mlops
kubectl delete namespace mlops
minikube stop
minikube delete
```

---

## 📚 Additional Resources

- **Project README**: `Assignment/README.md`
- **Helm Charts**: `Assignment/helm-charts/README.md`
- **Monitoring Setup**: `Assignment/monitoring/README.md`
- **API Documentation**: `http://<MINIKUBE_IP>:30080/docs`
- **Architecture**: `Assignment/ARCHITECTURE.md`

---

## 🎉 Success!

If all checks pass, you now have:

✅ Heart Disease Prediction API running on Kubernetes  
✅ Prometheus collecting metrics  
✅ Grafana visualizing performance  
✅ Complete monitoring and observability  
✅ Production-ready deployment  

Happy monitoring! 🚀📊
