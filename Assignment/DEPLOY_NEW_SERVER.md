# 🚀 Deploy Application on New AlmaLinux 8 Server

## Complete Guide to Deploy Heart Disease API from Scratch

This guide covers everything needed to deploy your application on a fresh AlmaLinux 8 server.

---

## 📋 Table of Contents

1. [Prerequisites Check](#prerequisites-check)
2. [Install Required Software](#install-required-software)
3. [Clone Repository](#clone-repository)
4. [Build Docker Image](#build-docker-image)
5. [Deploy with Kubernetes/Helm](#deploy-with-kuberneteshelm)
6. [Configure Remote Access](#configure-remote-access)
7. [Verification](#verification)
8. [Troubleshooting](#troubleshooting)

---

## 1. Prerequisites Check

### System Requirements

```bash
# Check OS version
cat /etc/redhat-release
# Should show: AlmaLinux release 8.x

# Check available resources
free -h  # At least 4GB RAM recommended
df -h    # At least 20GB free disk space
nproc    # Number of CPU cores (at least 2 recommended)
```

### Update System

```bash
# Update all packages
sudo dnf update -y

# Install basic tools
sudo dnf install -y curl wget git vim net-tools bind-utils
```

---

## 2. Install Required Software

### Step 2.1: Install Docker

```bash
# Remove any old Docker versions
sudo dnf remove -y docker \
    docker-client \
    docker-client-latest \
    docker-common \
    docker-latest \
    docker-latest-logrotate \
    docker-logrotate \
    docker-engine \
    podman \
    runc

# Install required packages
sudo dnf install -y dnf-plugins-core

# Add Docker repository
sudo dnf config-manager --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker
sudo dnf install -y docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group
sudo usermod -aG docker $USER

# Verify Docker installation
docker --version

# Test Docker (logout and login first, or use newgrp docker)
newgrp docker
docker run hello-world
```

### Step 2.2: Install kubectl

```bash
# Download kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Make it executable
chmod +x kubectl

# Move to system path
sudo mv kubectl /usr/local/bin/

# Verify installation
kubectl version --client

# Enable kubectl autocomplete
echo 'source <(kubectl completion bash)' >> ~/.bashrc
source ~/.bashrc
```

### Step 2.3: Install Minikube

```bash
# Download Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# Install Minikube
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Remove downloaded file
rm minikube-linux-amd64

# Verify installation
minikube version
```

### Step 2.4: Install Helm

```bash
# Download Helm installation script
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify installation
helm version

# Add Helm autocomplete
echo 'source <(helm completion bash)' >> ~/.bashrc
source ~/.bashrc
```

### Step 2.5: Install Python (for local testing)

```bash
# Install Python 3.9 or later
sudo dnf install -y python39 python39-pip python39-devel

# Verify installation
python3 --version
pip3 --version

# Create symbolic links (optional)
sudo alternatives --set python /usr/bin/python3
sudo alternatives --set python3 /usr/bin/python3.9
```

---

## 3. Clone Repository

### Option A: Clone from GitHub (Recommended)

```bash
# Navigate to home directory
cd ~

# Create workspace directory
mkdir -p ~/workspace
cd ~/workspace

# Clone your repository
git clone https://github.com/seshu-bits/mlops.git

# Navigate to project directory
cd mlops/Assignment

# Verify files
ls -la
```

### Option B: Transfer from Another Server

If you don't have GitHub access:

```bash
# On your original server (Mac):
cd /Users/saghanta/Personal/Docs/Education/Seshu/BITS/Courses/SEM\ 3/MLOps/mlops
tar -czf mlops-project.tar.gz Assignment/

# Copy to new AlmaLinux server
scp mlops-project.tar.gz user@<NEW_SERVER_IP>:~/

# On the new AlmaLinux server:
cd ~
tar -xzf mlops-project.tar.gz
cd Assignment
```

---

## 4. Build Docker Image

### Step 4.1: Start Minikube

```bash
# Start Minikube with Docker driver
minikube start --driver=docker --cpus=2 --memory=4096

# Verify Minikube is running
minikube status

# Get Minikube IP
minikube ip
```

### Step 4.2: Configure Docker Environment for Minikube

```bash
# Point Docker CLI to Minikube's Docker daemon
eval $(minikube docker-env)

# Verify you're using Minikube's Docker
docker ps

# To return to host Docker later, run:
# eval $(minikube docker-env -u)
```

### Step 4.3: Build Docker Image

```bash
# Navigate to project directory
cd ~/workspace/mlops/Assignment

# Verify Dockerfile exists
ls -la Dockerfile

# Build the Docker image
docker build -t heart-disease-api:latest .

# Verify image was built
docker images | grep heart-disease-api

# Test the image locally (optional)
docker run -d -p 8000:8000 --name test-api heart-disease-api:latest

# Test the API
sleep 5
curl http://localhost:8000/health

# Stop and remove test container
docker stop test-api
docker rm test-api
```

---

## 5. Deploy with Kubernetes/Helm

### Step 5.1: Create Namespace

```bash
# Create mlops namespace
kubectl create namespace mlops

# Verify namespace
kubectl get namespaces
```

### Step 5.2: Deploy with Helm

```bash
# Navigate to helm charts directory
cd ~/workspace/mlops/Assignment/helm-charts

# Verify chart structure
ls -la heart-disease-api/

# Install the application
helm install heart-disease-api ./heart-disease-api \
  --namespace mlops \
  --set image.repository=heart-disease-api \
  --set image.tag=latest \
  --set image.pullPolicy=Never

# Verify deployment
helm list -n mlops

# Check pods status
kubectl get pods -n mlops

# Wait for pods to be ready
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=heart-disease-api \
  -n mlops \
  --timeout=300s
```

### Step 5.3: Verify Services

```bash
# Check services
kubectl get svc -n mlops

# Check endpoints
kubectl get endpoints -n mlops

# Describe service
kubectl describe svc heart-disease-api -n mlops
```

---

## 6. Configure Remote Access

### Step 6.1: Enable Ingress

```bash
# Enable ingress addon
minikube addons enable ingress

# Verify ingress controller
kubectl get pods -n ingress-nginx

# Wait for ingress controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

### Step 6.2: Configure Firewall

```bash
# Get NodePorts
HTTP_NODEPORT=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}')
HTTPS_NODEPORT=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.ports[?(@.port==443)].nodePort}')
SERVICE_NODEPORT=30080

echo "HTTP NodePort: $HTTP_NODEPORT"
echo "HTTPS NodePort: $HTTPS_NODEPORT"
echo "Service NodePort: $SERVICE_NODEPORT"

# Configure firewall
sudo firewall-cmd --permanent --add-port=${HTTP_NODEPORT}/tcp
sudo firewall-cmd --permanent --add-port=${HTTPS_NODEPORT}/tcp
sudo firewall-cmd --permanent --add-port=${SERVICE_NODEPORT}/tcp
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --reload

# Verify firewall rules
sudo firewall-cmd --list-ports
```

### Step 6.3: Set Up Port Forwarding

```bash
# Create systemd service for port forwarding
sudo tee /etc/systemd/system/k8s-ingress-forward.service > /dev/null <<EOF
[Unit]
Description=Kubernetes Ingress Port Forward
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME
ExecStart=/usr/bin/kubectl port-forward -n ingress-nginx --address 0.0.0.0 service/ingress-nginx-controller 80:80 443:443
Restart=always
RestartSec=10
Environment="KUBECONFIG=$HOME/.kube/config"

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
sudo systemctl daemon-reload

# Enable and start service
sudo systemctl enable k8s-ingress-forward
sudo systemctl start k8s-ingress-forward

# Check status
sudo systemctl status k8s-ingress-forward
```

### Step 6.4: Get Server IP

```bash
# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "Server IP: $SERVER_IP"

# Save for reference
echo "export SERVER_IP=$SERVER_IP" >> ~/.bashrc
```

---

## 7. Verification

### Step 7.1: Local Testing

```bash
# Get Minikube IP
MINIKUBE_IP=$(minikube ip)

# Test 1: Direct pod access
kubectl port-forward -n mlops svc/heart-disease-api 8888:80 &
PF_PID=$!
sleep 3
curl http://localhost:8888/health
kill $PF_PID

# Test 2: NodePort access
curl http://$MINIKUBE_IP:30080/health

# Test 3: Ingress access
curl -H "Host: heart-disease-api.local" http://localhost/health
```

### Step 7.2: Remote Testing

From your **client machine** (Mac or another system):

```bash
# Test 1: Direct NodePort access
curl http://<SERVER_IP>:30080/health

# Test 2: Health endpoint
curl http://<SERVER_IP>:30080/health

# Test 3: Prediction endpoint
curl -X POST http://<SERVER_IP>:30080/predict \
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

### Step 7.3: Check Logs

```bash
# View pod logs
kubectl logs -n mlops -l app.kubernetes.io/name=heart-disease-api

# Follow logs in real-time
kubectl logs -n mlops -l app.kubernetes.io/name=heart-disease-api -f

# Check ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller --tail=50
```

---

## 8. Troubleshooting

### Issue 1: Minikube won't start

```bash
# Check Docker is running
sudo systemctl status docker
sudo systemctl start docker

# Delete and recreate Minikube
minikube delete
minikube start --driver=docker --cpus=2 --memory=4096

# Check logs
minikube logs
```

### Issue 2: Image not found

```bash
# Verify you're using Minikube's Docker
eval $(minikube docker-env)

# List images
docker images | grep heart-disease-api

# Rebuild if necessary
cd ~/workspace/mlops/Assignment
docker build -t heart-disease-api:latest .
```

### Issue 3: Pods not starting

```bash
# Check pod status
kubectl get pods -n mlops

# Describe pod to see errors
kubectl describe pod -n mlops -l app.kubernetes.io/name=heart-disease-api

# Check events
kubectl get events -n mlops --sort-by='.lastTimestamp'

# Check logs
kubectl logs -n mlops -l app.kubernetes.io/name=heart-disease-api
```

### Issue 4: Cannot access from remote

```bash
# Check firewall
sudo firewall-cmd --list-all

# Check if ports are listening
sudo ss -tlnp | grep -E '80|443|30080'

# Check SELinux
sudo getenforce
# If Enforcing, temporarily disable for testing
sudo setenforce 0
# Test access, then re-enable
sudo setenforce 1

# Check port forwarding service
sudo systemctl status k8s-ingress-forward
sudo journalctl -u k8s-ingress-forward -f
```

### Issue 5: Service not accessible

```bash
# Check service
kubectl get svc -n mlops

# Check endpoints
kubectl get endpoints -n mlops

# Port forward directly to test
kubectl port-forward -n mlops svc/heart-disease-api 8080:80 &
curl http://localhost:8080/health
```

---

## 🤖 Complete Automated Deployment Script

Save this as `deploy_new_server.sh`:

```bash
#!/bin/bash

set -e  # Exit on error

echo "=========================================="
echo "Automated Deployment on New AlmaLinux Server"
echo "=========================================="
echo ""

# Step 1: Update system
echo "Step 1: Updating system..."
sudo dnf update -y
sudo dnf install -y curl wget git vim net-tools bind-utils
echo ""

# Step 2: Install Docker
echo "Step 2: Installing Docker..."
if ! command -v docker &> /dev/null; then
    sudo dnf remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine podman runc 2>/dev/null || true
    sudo dnf install -y dnf-plugins-core
    sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    echo "Docker installed successfully"
else
    echo "Docker already installed"
fi
echo ""

# Step 3: Install kubectl
echo "Step 3: Installing kubectl..."
if ! command -v kubectl &> /dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    echo "kubectl installed successfully"
else
    echo "kubectl already installed"
fi
echo ""

# Step 4: Install Minikube
echo "Step 4: Installing Minikube..."
if ! command -v minikube &> /dev/null; then
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
    echo "Minikube installed successfully"
else
    echo "Minikube already installed"
fi
echo ""

# Step 5: Install Helm
echo "Step 5: Installing Helm..."
if ! command -v helm &> /dev/null; then
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    echo "Helm installed successfully"
else
    echo "Helm already installed"
fi
echo ""

# Step 6: Start Minikube
echo "Step 6: Starting Minikube..."
newgrp docker <<EONG
minikube start --driver=docker --cpus=2 --memory=4096
EONG
minikube status
echo ""

# Step 7: Clone repository
echo "Step 7: Cloning repository..."
if [ ! -d "$HOME/workspace/mlops" ]; then
    mkdir -p $HOME/workspace
    cd $HOME/workspace
    git clone https://github.com/seshu-bits/mlops.git
    echo "Repository cloned successfully"
else
    echo "Repository already exists"
    cd $HOME/workspace/mlops
    git pull
fi
echo ""

# Step 8: Build Docker image
echo "Step 8: Building Docker image..."
cd $HOME/workspace/mlops/Assignment
eval $(minikube docker-env)
docker build -t heart-disease-api:latest .
echo "Docker image built successfully"
echo ""

# Step 9: Create namespace
echo "Step 9: Creating namespace..."
kubectl create namespace mlops --dry-run=client -o yaml | kubectl apply -f -
echo ""

# Step 10: Deploy with Helm
echo "Step 10: Deploying with Helm..."
cd $HOME/workspace/mlops/Assignment/helm-charts
helm upgrade --install heart-disease-api ./heart-disease-api \
  --namespace mlops \
  --set image.repository=heart-disease-api \
  --set image.tag=latest \
  --set image.pullPolicy=Never
echo ""

# Step 11: Wait for pods
echo "Step 11: Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=heart-disease-api \
  -n mlops \
  --timeout=300s
echo ""

# Step 12: Enable ingress
echo "Step 12: Enabling ingress..."
minikube addons enable ingress
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
echo ""

# Step 13: Configure firewall
echo "Step 13: Configuring firewall..."
HTTP_NODEPORT=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}')
HTTPS_NODEPORT=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.ports[?(@.port==443)].nodePort}')
sudo firewall-cmd --permanent --add-port=${HTTP_NODEPORT}/tcp
sudo firewall-cmd --permanent --add-port=${HTTPS_NODEPORT}/tcp
sudo firewall-cmd --permanent --add-port=30080/tcp
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --reload
echo ""

# Step 14: Set up port forwarding
echo "Step 14: Setting up port forwarding..."
sudo tee /etc/systemd/system/k8s-ingress-forward.service > /dev/null <<EOF
[Unit]
Description=Kubernetes Ingress Port Forward
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME
ExecStart=/usr/bin/kubectl port-forward -n ingress-nginx --address 0.0.0.0 service/ingress-nginx-controller 80:80 443:443
Restart=always
RestartSec=10
Environment="KUBECONFIG=$HOME/.kube/config"

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable k8s-ingress-forward
sudo systemctl start k8s-ingress-forward
echo ""

# Step 15: Verify deployment
echo "Step 15: Verifying deployment..."
sleep 10

SERVER_IP=$(hostname -I | awk '{print $1}')
MINIKUBE_IP=$(minikube ip)

echo "Testing local access..."
if curl -s http://$MINIKUBE_IP:30080/health > /dev/null; then
    echo "✓ Local access working"
else
    echo "✗ Local access failed"
fi

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "Server IP: $SERVER_IP"
echo "Minikube IP: $MINIKUBE_IP"
echo ""
echo "Access your application from remote systems:"
echo "  curl http://$SERVER_IP:30080/health"
echo ""
echo "Useful commands:"
echo "  kubectl get pods -n mlops"
echo "  kubectl logs -n mlops -l app.kubernetes.io/name=heart-disease-api"
echo "  helm list -n mlops"
echo "  minikube status"
echo ""
```

Make it executable and run:
```bash
chmod +x deploy_new_server.sh
./deploy_new_server.sh
```

---

## 📝 Post-Deployment Checklist

- [ ] Minikube is running: `minikube status`
- [ ] Docker image is built: `docker images | grep heart-disease-api`
- [ ] Pods are running: `kubectl get pods -n mlops`
- [ ] Service is exposed: `kubectl get svc -n mlops`
- [ ] Ingress is enabled: `minikube addons list | grep ingress`
- [ ] Firewall is configured: `sudo firewall-cmd --list-ports`
- [ ] Port forwarding is running: `sudo systemctl status k8s-ingress-forward`
- [ ] Local access works: `curl http://$(minikube ip):30080/health`
- [ ] Remote access works: `curl http://<SERVER_IP>:30080/health`

---

## 🔄 Starting/Stopping the Application

### Stop the Application

```bash
# Stop port forwarding
sudo systemctl stop k8s-ingress-forward

# Delete Helm release
helm uninstall heart-disease-api -n mlops

# Stop Minikube
minikube stop

# Or completely remove
minikube delete
```

### Start the Application

```bash
# Start Minikube
minikube start --driver=docker --cpus=2 --memory=4096

# Point to Minikube's Docker
eval $(minikube docker-env)

# Deploy with Helm
cd ~/workspace/mlops/Assignment/helm-charts
helm install heart-disease-api ./heart-disease-api \
  --namespace mlops \
  --set image.pullPolicy=Never

# Start port forwarding
sudo systemctl start k8s-ingress-forward
```

### Restart After Server Reboot

```bash
# Start Minikube
minikube start

# Wait for all services
sleep 30

# Check status
kubectl get pods -n mlops
sudo systemctl status k8s-ingress-forward

# If port forwarding not running
sudo systemctl restart k8s-ingress-forward
```

---

## 📊 Monitoring and Maintenance

```bash
# Check overall status
kubectl get all -n mlops

# Monitor pod logs
kubectl logs -n mlops -l app.kubernetes.io/name=heart-disease-api -f

# Check resource usage
kubectl top pods -n mlops
kubectl top nodes

# Check Minikube resources
minikube ssh -- df -h
minikube ssh -- free -h

# Update application
cd ~/workspace/mlops/Assignment
git pull
eval $(minikube docker-env)
docker build -t heart-disease-api:latest .
helm upgrade heart-disease-api ./helm-charts/heart-disease-api -n mlops
kubectl rollout restart deployment -n mlops
```

---

## 🎯 Quick Reference

### Essential Commands

```bash
# Check everything is running
minikube status && kubectl get pods -n mlops && sudo systemctl status k8s-ingress-forward

# View logs
kubectl logs -n mlops -l app.kubernetes.io/name=heart-disease-api --tail=100

# Test API
curl http://$(hostname -I | awk '{print $1}'):30080/health

# Restart deployment
kubectl rollout restart deployment -n mlops heart-disease-api
```

### Important Paths

- **Project**: `~/workspace/mlops/Assignment`
- **Helm Charts**: `~/workspace/mlops/Assignment/helm-charts`
- **Kubeconfig**: `~/.kube/config`
- **Minikube**: `~/.minikube`

That's everything you need to deploy and run your application on a new AlmaLinux server!
