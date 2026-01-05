# 🎯 Complete Summary - Docker Container Deployment on Minikube (Alma Linux 8)

## 📦 What Has Been Created

I've created a complete, production-ready deployment setup for your Heart Disease Prediction API on Minikube with Helm charts. Here's everything that was created:

### 📁 Files Created

```
Assignment/
├── MINIKUBE_SETUP_GUIDE.md          # Complete setup guide for Alma Linux 8
├── QUICK_REFERENCE.md               # Quick command reference
└── helm-charts/                     # Helm charts directory
    ├── README.md                    # Helm charts documentation
    ├── deploy.sh                    # Automated deployment script ✨
    ├── test-api.sh                  # Comprehensive API testing script ✨
    ├── cleanup.sh                   # Cleanup script ✨
    └── heart-disease-api/          # Main Helm chart
        ├── Chart.yaml              # Chart metadata
        ├── values.yaml             # Default configuration
        ├── values-dev.yaml         # Development environment config
        ├── values-prod.yaml        # Production environment config
        ├── README.md               # Chart documentation
        ├── .helmignore            # Helm ignore patterns
        └── templates/             # Kubernetes manifests
            ├── _helpers.tpl       # Template helpers
            ├── NOTES.txt          # Post-installation notes
            ├── deployment.yaml    # Pod deployment
            ├── service.yaml       # Service (NodePort)
            ├── serviceaccount.yaml # Service account
            ├── ingress.yaml       # Ingress (optional)
            ├── hpa.yaml           # Horizontal Pod Autoscaler
            ├── configmap.yaml     # ConfigMap
            ├── secret.yaml        # Secrets
            ├── pvc.yaml           # Persistent Volume Claim
            ├── pdb.yaml           # Pod Disruption Budget
            ├── networkpolicy.yaml # Network policy
            └── servicemonitor.yaml # Prometheus ServiceMonitor
```

---

## 🚀 Complete Deployment Steps for Alma Linux 8

### Phase 1: System Setup (One-time installation)

```bash
# 1. Update system
sudo dnf update -y

# 2. Install Docker
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# 3. Login/logout or run:
newgrp docker

# 4. Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client

# 5. Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
minikube version

# 6. Install Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
helm version
```

### Phase 2: Start Minikube

```bash
# Start Minikube with Docker driver
minikube start --driver=docker --cpus=2 --memory=4096

# Enable addons (optional but recommended)
minikube addons enable ingress
minikube addons enable metrics-server

# Verify
minikube status
kubectl cluster-info
```

### Phase 3: Build Docker Image

```bash
# Navigate to project directory
cd /path/to/mlops/Assignment

# IMPORTANT: Configure shell to use Minikube's Docker daemon
eval $(minikube docker-env)

# Build the Docker image
docker build -t heart-disease-api:latest .

# Verify image exists
docker images | grep heart-disease-api
```

### Phase 4: Deploy with Helm

#### Option A: Automated Deployment (Recommended)

```bash
cd helm-charts
./deploy.sh
```

This script automatically:
- ✅ Checks all prerequisites
- ✅ Builds Docker image in Minikube
- ✅ Deploys with Helm
- ✅ Verifies deployment
- ✅ Tests the API
- ✅ Shows access information

#### Option B: Manual Deployment

```bash
cd helm-charts

# Install the Helm chart
helm install heart-disease-api ./heart-disease-api \
  --namespace mlops \
  --create-namespace \
  --set image.pullPolicy=Never

# Wait for pods to be ready
kubectl wait --for=condition=ready pod \
  -l app=heart-disease-api \
  -n mlops \
  --timeout=300s

# Verify deployment
kubectl get all -n mlops
```

### Phase 5: Access the API

```bash
# Method 1: Get service URL
minikube service heart-disease-api -n mlops --url

# Method 2: Open in browser
minikube service heart-disease-api -n mlops

# Method 3: Port forward
kubectl port-forward -n mlops service/heart-disease-api 8000:80
```

### Phase 6: Test the API

```bash
# Run automated tests
cd helm-charts
./test-api.sh

# Or test manually
SERVICE_URL=$(minikube service heart-disease-api -n mlops --url)

# Health check
curl $SERVICE_URL/health

# Make a prediction
curl -X POST "$SERVICE_URL/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "age": 63, "sex": 1, "cp": 3, "trestbps": 145,
    "chol": 233, "fbs": 1, "restecg": 0, "thalach": 150,
    "exang": 0, "oldpeak": 2.3, "slope": 0, "ca": 0, "thal": 1
  }'

# Open API documentation
# Visit: http://<service-url>/docs
```

---

## 📊 Helm Chart Features

### ✨ Key Features

1. **Production-Ready Configuration**
   - Health checks (liveness, readiness, startup probes)
   - Resource limits and requests
   - Horizontal Pod Autoscaling (optional)
   - Pod Disruption Budget
   - Rolling updates

2. **Multi-Environment Support**
   - Development configuration (values-dev.yaml)
   - Production configuration (values-prod.yaml)
   - Custom values override

3. **Observability**
   - Prometheus metrics (via ServiceMonitor)
   - Comprehensive logging
   - Health check endpoints

4. **Security**
   - Service accounts
   - Network policies (optional)
   - Security contexts
   - Secret management

5. **Scalability**
   - Horizontal Pod Autoscaler
   - Resource management
   - LoadBalancer support

### 🎛️ Configuration Options

Key values you can customize in `values.yaml`:

```yaml
# Scaling
replicaCount: 2
autoscaling.enabled: true
autoscaling.maxReplicas: 10

# Resources
resources.limits.cpu: 500m
resources.limits.memory: 512Mi

# Service
service.type: NodePort  # or LoadBalancer, ClusterIP
service.nodePort: 30080

# Image
image.repository: heart-disease-api
image.tag: latest
image.pullPolicy: Never  # Important for Minikube!

# Ingress
ingress.enabled: false  # Enable for domain-based routing
```

---

## 🧪 Testing

### Automated Test Suite

The `test-api.sh` script tests:

1. ✅ Health endpoint (`/health`)
2. ✅ Root endpoint (`/`)
3. ✅ Single prediction (`/predict`)
4. ✅ Batch prediction (`/predict/batch`)
5. ✅ Input validation
6. ✅ API documentation endpoints
7. ✅ Performance metrics

### Manual Testing Examples

```bash
# Get service URL
export API_URL=$(minikube service heart-disease-api -n mlops --url)

# Health check
curl $API_URL/health

# Root endpoint
curl $API_URL/

# Single prediction
curl -X POST "$API_URL/predict" \
  -H "Content-Type: application/json" \
  -d @sample_input.json

# Batch prediction
curl -X POST "$API_URL/predict/batch" \
  -H "Content-Type: application/json" \
  -d @sample_batch_input.json

# View API docs
echo "API Docs: $API_URL/docs"
echo "ReDoc: $API_URL/redoc"
```

---

## 📈 Monitoring & Management

### View Logs

```bash
# Follow logs from all pods
kubectl logs -f -n mlops -l app=heart-disease-api

# Logs from specific pod
kubectl logs -f -n mlops <pod-name>

# View recent events
kubectl get events -n mlops --sort-by='.lastTimestamp'
```

### Check Status

```bash
# Pod status
kubectl get pods -n mlops

# Service status
kubectl get svc -n mlops

# All resources
kubectl get all -n mlops

# Detailed pod info
kubectl describe pod -n mlops -l app=heart-disease-api
```

### Resource Usage

```bash
# Pod resource usage (requires metrics-server)
kubectl top pods -n mlops

# Node resource usage
kubectl top nodes

# Minikube dashboard
minikube dashboard
```

### Scaling

```bash
# Manual scaling
kubectl scale deployment heart-disease-api -n mlops --replicas=5

# Enable autoscaling
helm upgrade heart-disease-api ./heart-disease-api \
  -n mlops \
  --set autoscaling.enabled=true \
  --set autoscaling.minReplicas=2 \
  --set autoscaling.maxReplicas=10
```

---

## 🔄 Upgrade & Rollback

### Upgrade Release

```bash
# Upgrade with new image tag
helm upgrade heart-disease-api ./heart-disease-api \
  -n mlops \
  --set image.tag=v2.0.0

# Upgrade with values file
helm upgrade heart-disease-api ./heart-disease-api \
  -f values-prod.yaml \
  -n mlops
```

### Rollback

```bash
# View revision history
helm history heart-disease-api -n mlops

# Rollback to previous version
helm rollback heart-disease-api -n mlops

# Rollback to specific revision
helm rollback heart-disease-api 2 -n mlops
```

---

## 🧹 Cleanup

### Quick Cleanup

```bash
cd helm-charts
./cleanup.sh
```

### Manual Cleanup

```bash
# Uninstall Helm release
helm uninstall heart-disease-api -n mlops

# Delete namespace
kubectl delete namespace mlops

# Stop Minikube
minikube stop

# Delete Minikube cluster (complete cleanup)
minikube delete
```

---

## 🐛 Troubleshooting Guide

### Issue 1: ImagePullBackOff

**Symptoms**: Pods stuck in `ImagePullBackOff` state

**Solution**:
```bash
# Ensure you're using Minikube's Docker daemon
eval $(minikube docker-env)

# Rebuild image
docker build -t heart-disease-api:latest .

# Verify image exists
docker images | grep heart-disease-api

# Set pullPolicy to Never
helm upgrade heart-disease-api ./heart-disease-api \
  -n mlops \
  --set image.pullPolicy=Never
```

### Issue 2: CrashLoopBackOff

**Symptoms**: Pods keep crashing and restarting

**Solution**:
```bash
# Check logs
kubectl logs -n mlops -l app=heart-disease-api

# Common causes:
# - Missing model file (artifacts/logistic_regression.pkl)
# - Memory limits too low
# - Application errors

# Check if model file exists in image
kubectl exec -it -n mlops $(kubectl get pod -n mlops -l app=heart-disease-api -o jsonpath='{.items[0].metadata.name}') -- ls -la /app/artifacts/
```

### Issue 3: Service Not Accessible

**Symptoms**: Cannot reach the API

**Solution**:
```bash
# Check service
kubectl get svc -n mlops

# Check endpoints
kubectl get endpoints -n mlops

# Try port-forward
kubectl port-forward -n mlops svc/heart-disease-api 8000:80
curl http://localhost:8000/health

# Get NodePort details
MINIKUBE_IP=$(minikube ip)
NODE_PORT=$(kubectl get svc heart-disease-api -n mlops -o jsonpath='{.spec.ports[0].nodePort}')
echo "Try: curl http://$MINIKUBE_IP:$NODE_PORT/health"
```

### Issue 4: Minikube Won't Start

**Symptoms**: `minikube start` fails

**Solution**:
```bash
# Check Docker is running
sudo systemctl status docker

# Delete and recreate Minikube
minikube delete
minikube start --driver=docker --cpus=2 --memory=4096

# Check logs
minikube logs

# If permission issues
sudo usermod -aG docker $USER
newgrp docker
```

---

## 📚 Documentation Files

1. **MINIKUBE_SETUP_GUIDE.md** - Complete detailed setup guide
2. **QUICK_REFERENCE.md** - Quick command reference
3. **helm-charts/README.md** - Helm charts documentation
4. **helm-charts/heart-disease-api/README.md** - Chart-specific docs

---

## 🎯 Quick Start Commands (Copy-Paste Ready)

```bash
# 1. Start Minikube
minikube start --driver=docker --cpus=2 --memory=4096

# 2. Configure Docker
eval $(minikube docker-env)

# 3. Build image
cd /path/to/mlops/Assignment
docker build -t heart-disease-api:latest .

# 4. Deploy
cd helm-charts
./deploy.sh

# 5. Get URL
minikube service heart-disease-api -n mlops --url

# 6. Test
./test-api.sh

# 7. View logs
kubectl logs -f -n mlops -l app=heart-disease-api

# 8. Cleanup when done
./cleanup.sh
```

---

## ✅ Verification Checklist

After deployment, verify:

- [ ] Minikube is running: `minikube status`
- [ ] Pods are running: `kubectl get pods -n mlops`
- [ ] Service is accessible: `minikube service heart-disease-api -n mlops --url`
- [ ] Health endpoint works: `curl <service-url>/health`
- [ ] API docs accessible: Visit `<service-url>/docs`
- [ ] Predictions work: Test with `test-api.sh`
- [ ] Logs are clean: `kubectl logs -n mlops -l app=heart-disease-api`

---

## 🆘 Support & Resources

- **Minikube Docs**: https://minikube.sigs.k8s.io/docs/
- **Helm Docs**: https://helm.sh/docs/
- **Kubernetes Docs**: https://kubernetes.io/docs/
- **Docker Docs**: https://docs.docker.com/

---

## 🎉 Summary

You now have:

✅ Complete Alma Linux 8 setup instructions  
✅ Production-ready Helm charts  
✅ Automated deployment scripts  
✅ Comprehensive testing suite  
✅ Multi-environment support (dev/prod)  
✅ Monitoring and logging setup  
✅ Detailed troubleshooting guide  
✅ Cleanup automation  

**Everything you need to deploy and manage your Heart Disease Prediction API on Minikube!** 🚀

---

**Need help? Start with [MINIKUBE_SETUP_GUIDE.md](./MINIKUBE_SETUP_GUIDE.md) for detailed step-by-step instructions!**
