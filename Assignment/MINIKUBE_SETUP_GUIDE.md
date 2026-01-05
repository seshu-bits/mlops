# 🚀 Minikube Deployment Guide - Alma Linux 8

## Complete Setup Guide for Running Heart Disease Prediction API on Minikube

This guide covers everything from installing prerequisites on Alma Linux 8 to deploying the application using Helm charts.

---

## 📋 Table of Contents

1. [Prerequisites Installation](#prerequisites-installation)
2. [Docker Setup](#docker-setup)
3. [Build and Push Docker Image](#build-and-push-docker-image)
4. [Minikube Installation](#minikube-installation)
5. [Helm Installation](#helm-installation)
6. [Deploy Application with Helm](#deploy-application-with-helm)
7. [Access the Application](#access-the-application)
8. [Testing and Verification](#testing-and-verification)
9. [Troubleshooting](#troubleshooting)
10. [Cleanup](#cleanup)

---

## 1. Prerequisites Installation

### Update System Packages

```bash
# Update system
sudo dnf update -y

# Install basic tools
sudo dnf install -y curl wget git vim
```

---

## 2. Docker Setup

### Install Docker on Alma Linux 8

```bash
# Remove old versions if any
sudo dnf remove docker docker-client docker-client-latest \
    docker-common docker-latest docker-latest-logrotate \
    docker-logrotate docker-engine podman runc

# Install required packages
sudo dnf install -y dnf-plugins-core

# Add Docker repository
sudo dnf config-manager --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker
sudo dnf install -y docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to docker group (logout/login required after this)
sudo usermod -aG docker $USER

# Verify Docker installation
docker --version
```

### Configure Docker (if needed)

```bash
# Test Docker
docker run hello-world

# If you see permission errors, restart Docker
sudo systemctl restart docker
```

---

## 3. Build and Push Docker Image

### Option A: Use Docker Hub (Recommended)

```bash
# Navigate to project directory
cd /Users/saghanta/Personal/Docs/Education/Seshu/BITS/Courses/SEM\ 3/MLOps/mlops/Assignment

# Build the Docker image
docker build -t heart-disease-api:latest .

# Tag the image for Docker Hub (replace 'yourusername' with your Docker Hub username)
docker tag heart-disease-api:latest yourusername/heart-disease-api:latest

# Login to Docker Hub
docker login

# Push the image
docker push yourusername/heart-disease-api:latest
```

### Option B: Use Minikube's Docker Daemon (Simpler for local testing)

```bash
# First, start Minikube (see section 4)
# Then, configure shell to use Minikube's Docker daemon
eval $(minikube docker-env)

# Now build the image (it will be built inside Minikube)
cd /Users/saghanta/Personal/Docs/Education/Seshu/BITS/Courses/SEM\ 3/MLOps/mlops/Assignment
docker build -t heart-disease-api:latest .

# Verify the image is in Minikube
docker images | grep heart-disease-api

# IMPORTANT: Set imagePullPolicy to Never in Helm values
```

---

## 4. Minikube Installation

### Install kubectl

```bash
# Download kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Make it executable
chmod +x kubectl

# Move to PATH
sudo mv kubectl /usr/local/bin/

# Verify installation
kubectl version --client
```

### Install Minikube

```bash
# Download Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# Install Minikube
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Verify installation
minikube version
```

### Start Minikube

```bash
# Start Minikube with Docker driver
minikube start --driver=docker --cpus=2 --memory=4096

# Verify Minikube is running
minikube status

# Enable necessary addons
minikube addons enable ingress
minikube addons enable metrics-server

# Verify cluster
kubectl cluster-info
kubectl get nodes
```

### Troubleshooting Minikube Start

If you encounter issues:

```bash
# If permission denied, ensure you're in docker group
newgrp docker

# Or run with sudo (not recommended)
sudo minikube start --driver=docker --force

# Check Minikube logs
minikube logs
```

---

## 5. Helm Installation

### Install Helm 3

```bash
# Download Helm installation script
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3

# Make it executable
chmod 700 get_helm.sh

# Run the installer
./get_helm.sh

# Verify installation
helm version
```

---

## 6. Deploy Application with Helm

### Navigate to Helm Chart Directory

```bash
cd /Users/saghanta/Personal/Docs/Education/Seshu/BITS/Courses/SEM\ 3/MLOps/mlops/Assignment/helm-charts
```

### Install the Application

**If using Docker Hub:**

```bash
# Update values.yaml with your Docker Hub username first
# Then install
helm install heart-disease-api ./heart-disease-api \
  --namespace mlops \
  --create-namespace
```

**If using Minikube's Docker daemon:**

```bash
# Ensure you built the image with Minikube's Docker daemon
# Install with imagePullPolicy=Never
helm install heart-disease-api ./heart-disease-api \
  --namespace mlops \
  --create-namespace \
  --set image.pullPolicy=Never
```

### Verify Deployment

```bash
# Check all resources
kubectl get all -n mlops

# Check pods
kubectl get pods -n mlops

# Check services
kubectl get svc -n mlops

# Watch pod status
kubectl get pods -n mlops -w

# Check pod logs
kubectl logs -f -n mlops -l app=heart-disease-api
```

---

## 7. Access the Application

### Method 1: Port Forward (Quick Testing)

```bash
# Forward port 8000 to local machine
kubectl port-forward -n mlops service/heart-disease-api 8000:80

# Access in browser or curl
curl http://localhost:8000/health
```

### Method 2: Minikube Service (Recommended)

```bash
# Get the service URL
minikube service heart-disease-api -n mlops --url

# Or open in browser automatically
minikube service heart-disease-api -n mlops
```

### Method 3: NodePort Access

```bash
# Get Minikube IP
MINIKUBE_IP=$(minikube ip)

# Get NodePort
NODE_PORT=$(kubectl get svc heart-disease-api -n mlops -o jsonpath='{.spec.ports[0].nodePort}')

# Access the application
curl http://$MINIKUBE_IP:$NODE_PORT/health

echo "API is available at: http://$MINIKUBE_IP:$NODE_PORT"
echo "API Documentation: http://$MINIKUBE_IP:$NODE_PORT/docs"
```

### Method 4: Ingress (if configured)

```bash
# Add entry to /etc/hosts
echo "$(minikube ip) heart-disease-api.local" | sudo tee -a /etc/hosts

# Access via hostname
curl http://heart-disease-api.local/health
```

---

## 8. Testing and Verification

### Test Health Endpoint

```bash
# Get the service URL
SERVICE_URL=$(minikube service heart-disease-api -n mlops --url)

# Test health endpoint
curl $SERVICE_URL/health
```

### Test Prediction Endpoint

```bash
# Test with sample data
curl -X POST "$SERVICE_URL/predict" \
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

### Access API Documentation

```bash
# Get the service URL
SERVICE_URL=$(minikube service heart-disease-api -n mlops --url)

# Print the docs URL
echo "API Docs: $SERVICE_URL/docs"
echo "ReDoc: $SERVICE_URL/redoc"

# Open in browser (if you have GUI)
xdg-open "$SERVICE_URL/docs" 2>/dev/null || open "$SERVICE_URL/docs" 2>/dev/null
```

### Monitor Application

```bash
# Watch pods
kubectl get pods -n mlops -w

# View logs
kubectl logs -f -n mlops -l app=heart-disease-api

# Describe pod
kubectl describe pod -n mlops -l app=heart-disease-api

# Get pod metrics (if metrics-server is enabled)
kubectl top pods -n mlops
```

---

## 9. Troubleshooting

### Common Issues and Solutions

#### 1. ImagePullBackOff Error

```bash
# Check pod events
kubectl describe pod -n mlops -l app=heart-disease-api

# Solution: Use Minikube's Docker daemon
eval $(minikube docker-env)
docker build -t heart-disease-api:latest .
helm upgrade heart-disease-api ./heart-disease-api -n mlops --set image.pullPolicy=Never
```

#### 2. CrashLoopBackOff Error

```bash
# Check logs
kubectl logs -n mlops -l app=heart-disease-api

# Common causes:
# - Missing artifacts/logistic_regression.pkl file
# - Port already in use
# - Memory limits too low
```

#### 3. Pods Not Starting

```bash
# Check pod status
kubectl get pods -n mlops

# Describe pod for events
kubectl describe pod -n mlops -l app=heart-disease-api

# Check cluster resources
kubectl top nodes
```

#### 4. Service Not Accessible

```bash
# Check service
kubectl get svc -n mlops

# Check endpoints
kubectl get endpoints -n mlops

# Test from within cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n mlops -- \
  curl http://heart-disease-api/health
```

#### 5. Minikube Issues

```bash
# Restart Minikube
minikube stop
minikube start

# Delete and recreate (WARNING: deletes all data)
minikube delete
minikube start --driver=docker --cpus=2 --memory=4096
```

---

## 10. Cleanup

### Uninstall Helm Release

```bash
# Uninstall the application
helm uninstall heart-disease-api -n mlops

# Verify deletion
kubectl get all -n mlops
```

### Delete Namespace

```bash
# Delete the namespace (removes all resources)
kubectl delete namespace mlops
```

### Stop Minikube

```bash
# Stop Minikube (preserves state)
minikube stop

# Delete Minikube cluster (removes everything)
minikube delete
```

### Cleanup Docker Images

```bash
# Remove local images
docker rmi heart-disease-api:latest

# Clean up Docker system
docker system prune -a
```

---

## 📊 Useful Commands Reference

### Helm Commands

```bash
# List all releases
helm list -n mlops

# Get values of a release
helm get values heart-disease-api -n mlops

# Upgrade release
helm upgrade heart-disease-api ./heart-disease-api -n mlops

# Rollback release
helm rollback heart-disease-api -n mlops

# Uninstall release
helm uninstall heart-disease-api -n mlops
```

### Kubernetes Commands

```bash
# Get all resources in namespace
kubectl get all -n mlops

# Describe a resource
kubectl describe <resource-type> <resource-name> -n mlops

# View logs
kubectl logs -f <pod-name> -n mlops

# Execute command in pod
kubectl exec -it <pod-name> -n mlops -- /bin/bash

# Port forward
kubectl port-forward <pod-name> 8000:8000 -n mlops

# Delete resource
kubectl delete <resource-type> <resource-name> -n mlops
```

### Minikube Commands

```bash
# Start/Stop
minikube start
minikube stop

# Status
minikube status

# Get IP
minikube ip

# SSH into node
minikube ssh

# Dashboard
minikube dashboard

# Service URL
minikube service <service-name> -n <namespace> --url

# Logs
minikube logs
```

---

## 🎯 Quick Reference: Complete Deployment Flow

```bash
# 1. Start Minikube
minikube start --driver=docker --cpus=2 --memory=4096

# 2. Use Minikube's Docker daemon
eval $(minikube docker-env)

# 3. Build image
cd Assignment
docker build -t heart-disease-api:latest .

# 4. Deploy with Helm
cd helm-charts
helm install heart-disease-api ./heart-disease-api \
  --namespace mlops \
  --create-namespace \
  --set image.pullPolicy=Never

# 5. Get service URL
minikube service heart-disease-api -n mlops --url

# 6. Test
SERVICE_URL=$(minikube service heart-disease-api -n mlops --url)
curl $SERVICE_URL/health
```

---

## 📝 Notes

- **Resource Requirements**: Minikube needs at least 2 CPUs and 4GB RAM
- **Docker Daemon**: Always use `eval $(minikube docker-env)` when building images locally
- **Image Pull Policy**: Set to `Never` when using Minikube's Docker daemon
- **Namespace**: Using `mlops` namespace for organization
- **Service Type**: Using `NodePort` for easy external access

---

## 🔗 Additional Resources

- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [Alma Linux Documentation](https://wiki.almalinux.org/)

---

**Happy Deploying! 🚀**
