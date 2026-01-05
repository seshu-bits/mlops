# Heart Disease Prediction API - Helm Charts

This directory contains Helm charts and deployment scripts for deploying the Heart Disease Prediction API on Kubernetes/Minikube.

## 📁 Directory Structure

```
helm-charts/
├── heart-disease-api/          # Main Helm chart
│   ├── Chart.yaml             # Chart metadata
│   ├── values.yaml            # Default values
│   ├── values-dev.yaml        # Development environment values
│   ├── values-prod.yaml       # Production environment values
│   ├── README.md              # Chart documentation
│   ├── .helmignore           # Files to ignore when packaging
│   └── templates/            # Kubernetes manifests templates
│       ├── _helpers.tpl      # Template helpers
│       ├── NOTES.txt         # Post-installation notes
│       ├── deployment.yaml   # Deployment
│       ├── service.yaml      # Service
│       ├── serviceaccount.yaml
│       ├── ingress.yaml      # Ingress (optional)
│       ├── hpa.yaml          # HorizontalPodAutoscaler (optional)
│       ├── configmap.yaml    # ConfigMap (optional)
│       ├── secret.yaml       # Secret (optional)
│       ├── pvc.yaml          # PersistentVolumeClaim (optional)
│       ├── pdb.yaml          # PodDisruptionBudget (optional)
│       ├── networkpolicy.yaml # NetworkPolicy (optional)
│       └── servicemonitor.yaml # ServiceMonitor (optional)
├── deploy.sh                 # Automated deployment script
├── test-api.sh              # API testing script
├── cleanup.sh               # Cleanup script
└── README.md                # This file
```

## 🚀 Quick Start

### Prerequisites

1. **Minikube** installed and running
2. **Helm 3.0+** installed
3. **kubectl** installed
4. **Docker** installed

### Option 1: Automated Deployment (Recommended)

Use the automated deployment script:

```bash
cd helm-charts
./deploy.sh
```

This script will:
- Check prerequisites
- Build Docker image in Minikube's Docker daemon
- Install/upgrade Helm release
- Verify deployment
- Test the API
- Display access information

### Option 2: Manual Deployment

```bash
# 1. Start Minikube
minikube start --driver=docker --cpus=2 --memory=4096

# 2. Configure Docker to use Minikube's daemon
eval $(minikube docker-env)

# 3. Build Docker image
cd ../
docker build -t heart-disease-api:latest .

# 4. Install Helm chart
cd helm-charts
helm install heart-disease-api ./heart-disease-api \
  --namespace mlops \
  --create-namespace \
  --set image.pullPolicy=Never

# 5. Get service URL
minikube service heart-disease-api -n mlops --url
```

## 📝 Deployment Environments

### Development Environment

```bash
helm install heart-disease-api ./heart-disease-api \
  -f ./heart-disease-api/values-dev.yaml \
  --namespace mlops \
  --create-namespace
```

Features:
- 1 replica
- Lower resource limits
- Debug logging enabled
- NodePort service

### Production Environment

```bash
helm install heart-disease-api ./heart-disease-api \
  -f ./heart-disease-api/values-prod.yaml \
  --namespace mlops \
  --create-namespace
```

Features:
- 3 replicas (scalable to 10)
- Higher resource limits
- Autoscaling enabled
- LoadBalancer service
- Ingress enabled
- Pod disruption budget

## 🧪 Testing

### Automated Testing

Run the comprehensive test suite:

```bash
./test-api.sh
```

This tests:
- Health endpoint
- Root endpoint
- Single prediction
- Batch prediction
- Input validation
- Documentation endpoints
- Performance metrics

### Manual Testing

```bash
# Get service URL
SERVICE_URL=$(minikube service heart-disease-api -n mlops --url)

# Test health
curl $SERVICE_URL/health

# Make a prediction
curl -X POST "$SERVICE_URL/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "age": 63, "sex": 1, "cp": 3, "trestbps": 145,
    "chol": 233, "fbs": 1, "restecg": 0, "thalach": 150,
    "exang": 0, "oldpeak": 2.3, "slope": 0, "ca": 0, "thal": 1
  }'

# Open API docs in browser
minikube service heart-disease-api -n mlops
```

## 🔧 Configuration

### Key Configuration Options

Edit `values.yaml` or use `--set` flags:

```yaml
# Number of replicas
replicaCount: 2

# Image configuration
image:
  repository: heart-disease-api
  pullPolicy: Never
  tag: latest

# Service configuration
service:
  type: NodePort
  port: 80
  targetPort: 8000
  nodePort: 30080

# Resource limits
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

# Autoscaling
autoscaling:
  enabled: false
  minReplicas: 2
  maxReplicas: 10
```

### Custom Values

Create your own values file:

```bash
helm install heart-disease-api ./heart-disease-api \
  -f my-custom-values.yaml \
  --namespace mlops \
  --create-namespace
```

## 📊 Monitoring

### View Logs

```bash
# Follow logs from all pods
kubectl logs -f -n mlops -l app=heart-disease-api

# Logs from specific pod
kubectl logs -f -n mlops <pod-name>
```

### Pod Status

```bash
# Get all pods
kubectl get pods -n mlops

# Watch pod status
kubectl get pods -n mlops -w

# Describe pod
kubectl describe pod -n mlops -l app=heart-disease-api
```

### Resource Usage

```bash
# Pod metrics (requires metrics-server)
kubectl top pods -n mlops

# Node metrics
kubectl top nodes
```

### Kubernetes Dashboard

```bash
# Start dashboard
minikube dashboard

# Or access via kubectl proxy
kubectl proxy
```

## 🔄 Upgrade

### Upgrade Release

```bash
# Upgrade with new values
helm upgrade heart-disease-api ./heart-disease-api \
  --namespace mlops \
  --set image.tag=v2.0.0

# Upgrade with new values file
helm upgrade heart-disease-api ./heart-disease-api \
  -f new-values.yaml \
  --namespace mlops
```

### Rollback

```bash
# List release history
helm history heart-disease-api -n mlops

# Rollback to previous version
helm rollback heart-disease-api -n mlops

# Rollback to specific revision
helm rollback heart-disease-api 1 -n mlops
```

## 🧹 Cleanup

### Automated Cleanup

```bash
./cleanup.sh
```

This will:
- Uninstall Helm release
- Delete namespace
- Remove Docker images (optional)

### Manual Cleanup

```bash
# Uninstall release
helm uninstall heart-disease-api -n mlops

# Delete namespace
kubectl delete namespace mlops

# Remove Docker images (in Minikube's daemon)
eval $(minikube docker-env)
docker rmi heart-disease-api:latest

# Stop Minikube
minikube stop

# Delete Minikube cluster
minikube delete
```

## 🐛 Troubleshooting

### ImagePullBackOff Error

```bash
# Check if image exists in Minikube
eval $(minikube docker-env)
docker images | grep heart-disease-api

# Rebuild if needed
docker build -t heart-disease-api:latest ../

# Ensure pullPolicy is Never
helm upgrade heart-disease-api ./heart-disease-api \
  -n mlops \
  --set image.pullPolicy=Never
```

### Pods Not Starting

```bash
# Check pod events
kubectl describe pod -n mlops -l app=heart-disease-api

# Check pod logs
kubectl logs -n mlops -l app=heart-disease-api

# Check resource constraints
kubectl get nodes
kubectl top nodes
```

### Service Not Accessible

```bash
# Check service
kubectl get svc -n mlops

# Check endpoints
kubectl get endpoints -n mlops

# Port forward to test directly
kubectl port-forward -n mlops service/heart-disease-api 8000:80
curl http://localhost:8000/health
```

### Helm Issues

```bash
# Verify Helm installation
helm version

# List all releases
helm list -n mlops

# Get release status
helm status heart-disease-api -n mlops

# Get release values
helm get values heart-disease-api -n mlops
```

## 📚 Additional Resources

- [Complete Setup Guide](../MINIKUBE_SETUP_GUIDE.md)
- [Chart Documentation](./heart-disease-api/README.md)
- [Docker Guide](../DOCKER_GUIDE.md)
- [API Documentation](../README_API.md)

## 🆘 Common Commands

```bash
# Check Minikube status
minikube status

# Get Minikube IP
minikube ip

# SSH into Minikube node
minikube ssh

# Access Minikube Docker daemon
eval $(minikube docker-env)

# Get service URL
minikube service heart-disease-api -n mlops --url

# Open service in browser
minikube service heart-disease-api -n mlops

# View all resources
kubectl get all -n mlops

# Delete all resources in namespace
kubectl delete all --all -n mlops
```

## 📄 License

This Helm chart is part of the MLOps Assignment project.

---

**For detailed Alma Linux 8 setup instructions, see [MINIKUBE_SETUP_GUIDE.md](../MINIKUBE_SETUP_GUIDE.md)**
