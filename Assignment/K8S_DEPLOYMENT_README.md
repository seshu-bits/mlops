# 🚀 Kubernetes Deployment Guide

## Running Heart Disease API on Minikube (Alma Linux 8)

This directory contains everything you need to deploy the Heart Disease Prediction API on Kubernetes using Minikube and Helm charts.

---

## ⚡ Quick Start

### For First-Time Setup on Alma Linux 8

```bash
# 1. Read the deployment summary (recommended)
cat DEPLOYMENT_SUMMARY.md

# 2. Follow the complete setup guide
cat MINIKUBE_SETUP_GUIDE.md

# 3. Or use the quick reference for commands
cat QUICK_REFERENCE.md
```

### For Automated Deployment

```bash
# Navigate to helm-charts directory
cd helm-charts

# Run automated deployment
./deploy.sh

# Test the API
./test-api.sh
```

### For Manual Deployment

```bash
# Start Minikube
minikube start --driver=docker --cpus=2 --memory=4096

# Build image in Minikube
eval $(minikube docker-env)
docker build -t heart-disease-api:latest .

# Deploy with Helm
cd helm-charts
helm install heart-disease-api ./heart-disease-api \
  --namespace mlops \
  --create-namespace \
  --set image.pullPolicy=Never

# Get service URL
minikube service heart-disease-api -n mlops --url
```

---

## 📚 Documentation

### 🎯 Start Here
- **[DOCUMENTATION_INDEX.md](./DOCUMENTATION_INDEX.md)** - Complete documentation index
- **[DEPLOYMENT_SUMMARY.md](./DEPLOYMENT_SUMMARY.md)** ⭐ - Overview and quick steps
- **[MINIKUBE_SETUP_GUIDE.md](./MINIKUBE_SETUP_GUIDE.md)** - Detailed setup for Alma Linux 8

### 📖 Reference Guides
- **[QUICK_REFERENCE.md](./QUICK_REFERENCE.md)** - Command reference
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - System architecture
- **[helm-charts/README.md](./helm-charts/README.md)** - Helm chart documentation

---

## 📁 Structure

```
Assignment/
│
├── Documentation (Deployment)
│   ├── DOCUMENTATION_INDEX.md      # Complete index
│   ├── DEPLOYMENT_SUMMARY.md       # Quick overview
│   ├── MINIKUBE_SETUP_GUIDE.md    # Detailed setup
│   ├── QUICK_REFERENCE.md          # Command reference
│   └── ARCHITECTURE.md             # Architecture diagrams
│
├── Helm Charts
│   └── helm-charts/
│       ├── README.md               # Chart overview
│       ├── deploy.sh               # Automated deploy ✨
│       ├── test-api.sh            # Testing script ✨
│       ├── cleanup.sh             # Cleanup script ✨
│       └── heart-disease-api/     # Main chart
│           ├── Chart.yaml
│           ├── values.yaml
│           ├── values-dev.yaml
│           ├── values-prod.yaml
│           └── templates/         # K8s manifests
│
├── Docker
│   ├── Dockerfile
│   ├── DOCKER_GUIDE.md
│   └── run_docker.sh
│
├── Application
│   ├── api_server.py
│   ├── MLOps_Assignment.py
│   └── artifacts/
│       └── logistic_regression.pkl
│
└── Testing
    ├── integration_tests/
    └── tests/
```

---

## 🎓 Learning Paths

### Beginner (New to Kubernetes/Helm)
1. **Read**: [DEPLOYMENT_SUMMARY.md](./DEPLOYMENT_SUMMARY.md) (10 min)
2. **Follow**: [MINIKUBE_SETUP_GUIDE.md](./MINIKUBE_SETUP_GUIDE.md) (30 min)
3. **Run**: `cd helm-charts && ./deploy.sh` (5 min)
4. **Test**: `./test-api.sh` (2 min)
5. **Reference**: Bookmark [QUICK_REFERENCE.md](./QUICK_REFERENCE.md)

### Advanced (Familiar with K8s)
1. **Review**: [ARCHITECTURE.md](./ARCHITECTURE.md)
2. **Customize**: Edit `helm-charts/heart-disease-api/values.yaml`
3. **Deploy**: Manual helm install
4. **Configure**: Set up monitoring, autoscaling

---

## 🛠️ What You Get

### ✅ Complete Setup for Alma Linux 8
- Docker installation
- Minikube setup
- Kubectl configuration
- Helm installation

### ✅ Production-Ready Helm Chart
- 2 replicas by default
- Health checks (liveness, readiness, startup)
- Resource limits and requests
- Horizontal Pod Autoscaling (optional)
- Ingress support (optional)
- Pod Disruption Budget (optional)

### ✅ Multiple Environments
- Development (`values-dev.yaml`)
- Production (`values-prod.yaml`)
- Easy customization

### ✅ Automation Scripts
- **deploy.sh** - One-command deployment
- **test-api.sh** - Comprehensive testing
- **cleanup.sh** - Easy cleanup

### ✅ Comprehensive Documentation
- 5+ detailed guides
- Architecture diagrams
- Troubleshooting sections
- Quick reference

---

## 🧪 Testing

### Automated Testing
```bash
cd helm-charts
./test-api.sh
```

Tests include:
- ✅ Health endpoint
- ✅ Root endpoint
- ✅ Single prediction
- ✅ Batch prediction
- ✅ Input validation
- ✅ API documentation
- ✅ Performance metrics

### Manual Testing
```bash
# Get service URL
SERVICE_URL=$(minikube service heart-disease-api -n mlops --url)

# Test health
curl $SERVICE_URL/health

# Make prediction
curl -X POST "$SERVICE_URL/predict" \
  -H "Content-Type: application/json" \
  -d @sample_input.json
```

---

## 📊 Monitoring

```bash
# View logs
kubectl logs -f -n mlops -l app=heart-disease-api

# Check pod status
kubectl get pods -n mlops

# Resource usage
kubectl top pods -n mlops

# Get all resources
kubectl get all -n mlops
```

---

## 🔧 Management

### Upgrade
```bash
helm upgrade heart-disease-api ./helm-charts/heart-disease-api -n mlops
```

### Scale
```bash
kubectl scale deployment heart-disease-api -n mlops --replicas=5
```

### Rollback
```bash
helm rollback heart-disease-api -n mlops
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
helm uninstall heart-disease-api -n mlops
kubectl delete namespace mlops
minikube stop
```

---

## 🐛 Troubleshooting

### Common Issues

**Issue**: ImagePullBackOff
```bash
eval $(minikube docker-env)
docker build -t heart-disease-api:latest .
helm upgrade heart-disease-api ./helm-charts/heart-disease-api -n mlops --set image.pullPolicy=Never
```

**Issue**: Pods not starting
```bash
kubectl describe pod -n mlops -l app=heart-disease-api
kubectl logs -n mlops -l app=heart-disease-api
```

**Issue**: Service not accessible
```bash
kubectl port-forward -n mlops svc/heart-disease-api 8000:80
curl http://localhost:8000/health
```

**More troubleshooting**: See [MINIKUBE_SETUP_GUIDE.md - Section 9](./MINIKUBE_SETUP_GUIDE.md#9-troubleshooting)

---

## 📋 Prerequisites

- **OS**: Alma Linux 8 (or compatible)
- **RAM**: 4GB minimum (8GB recommended)
- **CPU**: 2 cores minimum (4 cores recommended)
- **Disk**: 20GB free space
- **Tools**: Docker, Minikube, kubectl, Helm (installation guide provided)

---

## 🔗 External Resources

- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Documentation](https://docs.docker.com/)

---

## 📝 Quick Commands

```bash
# Start Minikube
minikube start --driver=docker --cpus=2 --memory=4096

# Build and deploy
eval $(minikube docker-env)
docker build -t heart-disease-api:latest .
cd helm-charts && ./deploy.sh

# Access API
minikube service heart-disease-api -n mlops --url

# View logs
kubectl logs -f -n mlops -l app=heart-disease-api

# Cleanup
cd helm-charts && ./cleanup.sh
```

---

## 🎯 Key Features

✅ **Automated deployment** with `deploy.sh`  
✅ **Comprehensive testing** with `test-api.sh`  
✅ **Production-ready** Helm chart  
✅ **Multi-environment** support (dev/prod)  
✅ **Auto-scaling** capability  
✅ **Health checks** and monitoring  
✅ **Complete documentation** with diagrams  
✅ **Easy cleanup** with `cleanup.sh`  

---

## 📞 Need Help?

1. **Check**: [DOCUMENTATION_INDEX.md](./DOCUMENTATION_INDEX.md) for all guides
2. **Search**: Troubleshooting sections in each guide
3. **Run**: `./deploy.sh` for automated deployment with checks
4. **Reference**: [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) for commands

---

## 🎉 Ready to Deploy?

### Option 1: Automated (Recommended)
```bash
cd helm-charts
./deploy.sh
```

### Option 2: Read First
Start with [DEPLOYMENT_SUMMARY.md](./DEPLOYMENT_SUMMARY.md)

### Option 3: Complete Setup
Follow [MINIKUBE_SETUP_GUIDE.md](./MINIKUBE_SETUP_GUIDE.md)

---

**Happy Deploying! 🚀**

For detailed instructions, see [DOCUMENTATION_INDEX.md](./DOCUMENTATION_INDEX.md)
