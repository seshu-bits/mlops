# Deployment Guide for Alma Linux 8

This guide covers deploying the Heart Disease API on Alma Linux 8 with Docker and Minikube.

## Prerequisites

### 1. Install Docker
```bash
# Remove any old Docker installations
sudo dnf remove docker docker-client docker-client-latest docker-common \
    docker-latest docker-latest-logrotate docker-logrotate docker-engine

# Install Docker CE
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group (logout/login required after this)
sudo usermod -aG docker $USER
```

### 2. Install Minikube
```bash
# Download and install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64

# Start Minikube with Docker driver
minikube start --driver=docker --cpus=2 --memory=4096
```

### 3. Install kubectl
```bash
# Download kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Install kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Verify installation
kubectl version --client
```

### 4. Install Helm
```bash
# Download and install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify installation
helm version
```

## Deployment Options

### Option 1: Quick Deploy (Recommended for Alma Linux 8)

Use the Alma Linux optimized Dockerfile:

```bash
cd Assignment

# Configure to use Minikube's Docker daemon
eval $(minikube docker-env)

# Build using Alma Linux native Dockerfile
docker build -t heart-disease-api:latest -f Dockerfile.almalinux .

# Deploy with Helm
cd helm-charts
./deploy.sh
```

### Option 2: Standard Deploy with Base Image

The deploy script will automatically detect Alma Linux and try the best approach:

```bash
cd Assignment/helm-charts
./deploy.sh
```

This will:
1. Detect you're on Alma Linux
2. Try Dockerfile.almalinux first (uses almalinux:8 base)
3. Fall back to building local-python-base if needed
4. Deploy to Minikube with Helm

### Option 3: Completely Offline Deployment

If your Alma Linux 8 server has **no internet access**:

#### Step 1: Prepare images on a machine with internet

```bash
# On a machine with internet access:
docker pull almalinux:8
docker save almalinux:8 -o almalinux-8.tar

# Transfer almalinux-8.tar to your Alma Linux server
```

#### Step 2: Load images on your Alma Linux server

```bash
# On your Alma Linux server:
# Start Minikube
minikube start --driver=docker

# Configure shell to use Minikube's Docker
eval $(minikube docker-env)

# Load the base image
docker load -i almalinux-8.tar

# Verify it loaded
docker images | grep almalinux

# Now build and deploy
cd Assignment
docker build -t heart-disease-api:latest -f Dockerfile.almalinux .

cd helm-charts
./deploy.sh
```

## Troubleshooting

### Issue: "Cannot connect to Docker daemon"
```bash
# Ensure Docker is running
sudo systemctl status docker
sudo systemctl start docker

# Add user to docker group
sudo usermod -aG docker $USER
# Then logout and login again
```

### Issue: "Minikube is not running"
```bash
# Start Minikube
minikube start --driver=docker --cpus=2 --memory=4096

# Check status
minikube status
```

### Issue: "Failed to pull image"
This means you cannot reach external registries. Use Option 3 (Offline Deployment) above.

### Issue: "Python 3.11 not found in almalinux:8"
```bash
# Enable PowerTools and EPEL repositories
sudo dnf install -y epel-release
sudo dnf config-manager --set-enabled powertools

# Install Python 3.11 from EPEL
sudo dnf install -y python3.11 python3.11-pip python3.11-devel
```

### Issue: Build hangs at "load metadata"
This indicates network issues reaching Docker registries. Solutions:
1. Use Dockerfile.almalinux which uses almalinux:8 base (should be cached locally)
2. Pre-load required base images (see Option 3 above)
3. Configure Docker to use a mirror/proxy if available in your network

## Verifying Deployment

After deployment completes:

```bash
# Check pods are running
kubectl get pods -n mlops

# Check service
kubectl get svc -n mlops

# Get the service URL
minikube service heart-disease-api -n mlops --url

# Test the API
SERVICE_URL=$(minikube service heart-disease-api -n mlops --url)
curl $SERVICE_URL/health
```

## Accessing the API

```bash
# Option 1: Via minikube service
minikube service heart-disease-api -n mlops

# Option 2: Port forward
kubectl port-forward -n mlops service/heart-disease-api 8000:80

# Then access at http://localhost:8000
```

## Useful Commands

```bash
# View logs
kubectl logs -f -n mlops -l app=heart-disease-api

# Restart deployment
kubectl rollout restart deployment heart-disease-api -n mlops

# Delete deployment
helm uninstall heart-disease-api -n mlops

# Stop Minikube
minikube stop

# Clean up everything
minikube delete
```

## Network Configuration for Enterprise Environments

If you're in a corporate network with proxies:

```bash
# Set proxy for Docker
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf <<EOF
[Service]
Environment="HTTP_PROXY=http://proxy.example.com:8080"
Environment="HTTPS_PROXY=http://proxy.example.com:8080"
Environment="NO_PROXY=localhost,127.0.0.1,192.168.0.0/16"
EOF

sudo systemctl daemon-reload
sudo systemctl restart docker

# Start Minikube with proxy
minikube start --driver=docker \
  --docker-env HTTP_PROXY=http://proxy.example.com:8080 \
  --docker-env HTTPS_PROXY=http://proxy.example.com:8080 \
  --docker-env NO_PROXY=localhost,127.0.0.1,192.168.0.0/16
```

## Support

For issues specific to this deployment, check:
- Build logs: `/tmp/docker-build.log`
- Base image logs: `/tmp/base-build.log`
- Minikube logs: `minikube logs`
- Pod logs: `kubectl logs -n mlops <pod-name>`
