# Quick Reference Guide - Heart Disease API on Minikube (Alma Linux 8)

## 🚀 Complete Deployment Steps

### Step 1: System Setup (One-time setup on Alma Linux 8)

```bash
# Update system
sudo dnf update -y

# Install Docker
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
newgrp docker

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Install Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

### Step 2: Start Minikube

```bash
minikube start --driver=docker --cpus=2 --memory=4096
```

### Step 3: Build Docker Image

```bash
# Configure to use Minikube's Docker daemon
eval $(minikube docker-env)

# Navigate to project and build
cd /path/to/mlops/Assignment
docker build -t heart-disease-api:latest .

# Verify image
docker images | grep heart-disease-api
```

### Step 4: Deploy with Helm

```bash
# Navigate to helm charts
cd helm-charts

# Deploy using automated script
./deploy.sh

# OR deploy manually
helm install heart-disease-api ./heart-disease-api \
  --namespace mlops \
  --create-namespace \
  --set image.pullPolicy=Never
```

### Step 5: Access the API

```bash
# Get service URL
minikube service heart-disease-api -n mlops --url

# Or use the URL in your browser/curl
export API_URL=$(minikube service heart-disease-api -n mlops --url)
curl $API_URL/health
```

---

## 📝 Essential Commands

### Minikube Commands
```bash
minikube start                    # Start Minikube
minikube stop                     # Stop Minikube
minikube status                   # Check status
minikube delete                   # Delete cluster
minikube ip                       # Get cluster IP
minikube service list             # List all services
minikube dashboard               # Open dashboard
minikube ssh                     # SSH into node
eval $(minikube docker-env)      # Use Minikube's Docker
```

### Helm Commands
```bash
helm list -n mlops                                    # List releases
helm install heart-disease-api ./heart-disease-api    # Install
helm upgrade heart-disease-api ./heart-disease-api    # Upgrade
helm rollback heart-disease-api -n mlops             # Rollback
helm uninstall heart-disease-api -n mlops            # Uninstall
helm status heart-disease-api -n mlops               # Get status
helm get values heart-disease-api -n mlops           # Get values
```

### Kubectl Commands
```bash
kubectl get pods -n mlops                    # List pods
kubectl get svc -n mlops                     # List services
kubectl get all -n mlops                     # List all resources
kubectl logs -f -n mlops -l app=heart-disease-api  # View logs
kubectl describe pod -n mlops <pod-name>     # Describe pod
kubectl exec -it -n mlops <pod-name> -- /bin/bash  # Shell into pod
kubectl port-forward -n mlops svc/heart-disease-api 8000:80  # Port forward
kubectl top pods -n mlops                    # Resource usage
```

---

## 🧪 Testing Commands

### Health Check
```bash
curl $(minikube service heart-disease-api -n mlops --url)/health
```

### Single Prediction
```bash
curl -X POST "$(minikube service heart-disease-api -n mlops --url)/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "age": 63, "sex": 1, "cp": 3, "trestbps": 145,
    "chol": 233, "fbs": 1, "restecg": 0, "thalach": 150,
    "exang": 0, "oldpeak": 2.3, "slope": 0, "ca": 0, "thal": 1
  }'
```

### Batch Prediction
```bash
curl -X POST "$(minikube service heart-disease-api -n mlops --url)/predict/batch" \
  -H "Content-Type: application/json" \
  -d @../sample_batch_input.json
```

### Run Test Suite
```bash
cd helm-charts
./test-api.sh
```

---

## 🔧 Troubleshooting Quick Fixes

### Problem: ImagePullBackOff
```bash
# Solution: Rebuild with Minikube's Docker
eval $(minikube docker-env)
cd ../
docker build -t heart-disease-api:latest .
helm upgrade heart-disease-api ./heart-disease-api -n mlops --set image.pullPolicy=Never
```

### Problem: Pods Not Ready
```bash
# Check what's wrong
kubectl describe pod -n mlops -l app=heart-disease-api
kubectl logs -n mlops -l app=heart-disease-api
```

### Problem: Cannot Access Service
```bash
# Method 1: Port forward
kubectl port-forward -n mlops svc/heart-disease-api 8000:80
curl http://localhost:8000/health

# Method 2: Get NodePort
MINIKUBE_IP=$(minikube ip)
NODE_PORT=$(kubectl get svc heart-disease-api -n mlops -o jsonpath='{.spec.ports[0].nodePort}')
curl http://$MINIKUBE_IP:$NODE_PORT/health
```

### Problem: Minikube Won't Start
```bash
# Delete and recreate
minikube delete
minikube start --driver=docker --cpus=2 --memory=4096
```

---

## 🧹 Cleanup Commands

### Quick Cleanup
```bash
cd helm-charts
./cleanup.sh
```

### Manual Cleanup
```bash
helm uninstall heart-disease-api -n mlops
kubectl delete namespace mlops
minikube stop
```

### Complete Cleanup (including Minikube)
```bash
helm uninstall heart-disease-api -n mlops
kubectl delete namespace mlops
minikube delete
```

---

## 📊 Monitoring Commands

### Real-time Pod Logs
```bash
kubectl logs -f -n mlops -l app=heart-disease-api
```

### Watch Pod Status
```bash
kubectl get pods -n mlops -w
```

### Resource Usage
```bash
kubectl top nodes
kubectl top pods -n mlops
```

### Events
```bash
kubectl get events -n mlops --sort-by='.lastTimestamp'
```

---

## 🎯 Complete Workflow Example

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

# 5. Test
./test-api.sh

# 6. Access API docs
minikube service heart-disease-api -n mlops

# 7. Monitor
kubectl logs -f -n mlops -l app=heart-disease-api

# 8. When done, cleanup
./cleanup.sh
minikube stop
```

---

## 📍 Important File Locations

```
Assignment/
├── Dockerfile                           # Docker image definition
├── api_server.py                        # FastAPI application
├── artifacts/logistic_regression.pkl    # Trained model (required!)
├── MINIKUBE_SETUP_GUIDE.md             # Detailed setup guide
└── helm-charts/
    ├── deploy.sh                        # Automated deployment
    ├── test-api.sh                      # API testing
    ├── cleanup.sh                       # Cleanup script
    └── heart-disease-api/              # Helm chart
        ├── values.yaml                  # Default config
        ├── values-dev.yaml              # Dev config
        └── values-prod.yaml             # Prod config
```

---

## 🔗 URLs After Deployment

- **API Base**: `http://<minikube-ip>:<node-port>/`
- **Health Check**: `http://<minikube-ip>:<node-port>/health`
- **API Docs**: `http://<minikube-ip>:<node-port>/docs`
- **ReDoc**: `http://<minikube-ip>:<node-port>/redoc`
- **Prediction**: `POST http://<minikube-ip>:<node-port>/predict`

Get the actual URL:
```bash
minikube service heart-disease-api -n mlops --url
```

---

## ⚡ Pro Tips

1. **Always use Minikube's Docker daemon** when building images locally:
   ```bash
   eval $(minikube docker-env)
   ```

2. **Set imagePullPolicy to Never** for local images:
   ```bash
   --set image.pullPolicy=Never
   ```

3. **Enable metrics-server** for resource monitoring:
   ```bash
   minikube addons enable metrics-server
   ```

4. **Use port-forward** for quick testing:
   ```bash
   kubectl port-forward -n mlops svc/heart-disease-api 8000:80
   ```

5. **Check logs immediately** if pods aren't starting:
   ```bash
   kubectl logs -n mlops -l app=heart-disease-api
   ```

---

**For detailed instructions, see [MINIKUBE_SETUP_GUIDE.md](../MINIKUBE_SETUP_GUIDE.md)**
