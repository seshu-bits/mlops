# Complete MLOps Deployment Guide for Alma Linux 8
## Docker + Minikube + Prometheus + Grafana + MLflow + Ingress

**Server IP:** 72.163.219.91

This guide provides a complete from-scratch deployment of the MLOps application on Alma Linux 8 with all monitoring and tracking components accessible via ingress.

---

## 📋 Table of Contents

1. [Prerequisites Installation](#1-prerequisites-installation)
2. [Minikube Setup](#2-minikube-setup)
3. [Build Application](#3-build-application)
4. [Deploy Monitoring Stack](#4-deploy-monitoring-stack)
5. [Deploy MLflow](#5-deploy-mlflow)
6. [Setup Ingress](#6-setup-ingress)
7. [Verify Deployment](#7-verify-deployment)
8. [Remote Access](#8-remote-access)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Prerequisites Installation

### 1.1 Update System
```bash
sudo dnf update -y
```

### 1.2 Install Docker
```bash
# Remove old versions
sudo dnf remove -y docker docker-client docker-client-latest docker-common \
    docker-latest docker-latest-logrotate docker-logrotate docker-engine podman runc

# Add Docker repository
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Verify Docker
docker --version
docker run hello-world
```

### 1.3 Install kubectl
```bash
# Download kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Install kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Verify
kubectl version --client
```

### 1.4 Install Minikube
```bash
# Download Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# Install Minikube
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64

# Verify
minikube version
```

### 1.5 Install Helm
```bash
# Download and install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify
helm version
```

### 1.6 Install Git (if not already installed)
```bash
sudo dnf install -y git
git --version
```

---

## 2. Minikube Setup

### 2.1 Start Minikube with Docker Driver
```bash
# Start Minikube with sufficient resources
minikube start --driver=docker --cpus=4 --memory=8192 --disk-size=40g

# Verify Minikube is running
minikube status

# Enable addons
minikube addons enable ingress
minikube addons enable metrics-server
minikube addons enable dashboard

# Verify addons
minikube addons list
```

### 2.2 Configure Docker Environment
```bash
# Use Minikube's Docker daemon for building images
eval $(minikube docker-env)

# Verify you're using Minikube's Docker
docker info | grep -i "Name:"
```

### 2.3 Create Namespace
```bash
# Create mlops namespace
kubectl create namespace mlops

# Set as default namespace
kubectl config set-context --current --namespace=mlops

# Verify
kubectl get namespaces
```

---

## 3. Build Application

### 3.1 Clone Repository
```bash
# Clone the project
cd ~
git clone https://github.com/seshu-bits/mlops.git
cd mlops/Assignment
```

### 3.2 Build Docker Image
```bash
# Make sure we're using Minikube's Docker daemon
eval $(minikube docker-env)

# Option 1: Build with Alma Linux native Dockerfile (Recommended)
docker build -t heart-disease-api:latest -f Dockerfile.almalinux .

# Option 2: If above fails, use the smart build script
chmod +x smart-docker-build.sh
./smart-docker-build.sh

# Verify image is built
docker images | grep heart-disease-api
```

---

## 4. Deploy Monitoring Stack

### 4.1 Deploy Prometheus
```bash
cd ~/mlops/Assignment/monitoring

# Apply Prometheus configuration
kubectl apply -f prometheus-config.yaml -n mlops

# Deploy Prometheus
kubectl apply -f prometheus-deployment.yaml -n mlops

# Wait for Prometheus to be ready
kubectl wait --for=condition=ready pod -l app=prometheus -n mlops --timeout=120s

# Verify Prometheus
kubectl get pods -n mlops -l app=prometheus
kubectl get svc -n mlops -l app=prometheus
```

### 4.2 Deploy Grafana
```bash
# Deploy Grafana
kubectl apply -f grafana-deployment.yaml -n mlops

# Wait for Grafana to be ready
kubectl wait --for=condition=ready pod -l app=grafana -n mlops --timeout=120s

# Verify Grafana
kubectl get pods -n mlops -l app=grafana
kubectl get svc -n mlops -l app=grafana
```

---

## 5. Deploy MLflow

### 5.1 Create MLflow Deployment
```bash
# Create MLflow deployment file
cat > ~/mlops/Assignment/monitoring/mlflow-deployment.yaml << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mlflow-pvc
  namespace: mlops
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mlflow
  namespace: mlops
  labels:
    app: mlflow
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mlflow
  template:
    metadata:
      labels:
        app: mlflow
    spec:
      containers:
      - name: mlflow
        image: ghcr.io/mlflow/mlflow:v2.9.2
        ports:
        - containerPort: 5000
          name: http
        command:
          - mlflow
          - server
          - --host
          - "0.0.0.0"
          - --port
          - "5000"
          - --backend-store-uri
          - "sqlite:///mlflow/mlflow.db"
          - --default-artifact-root
          - "/mlflow/artifacts"
        volumeMounts:
        - name: mlflow-storage
          mountPath: /mlflow
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
      volumes:
      - name: mlflow-storage
        persistentVolumeClaim:
          claimName: mlflow-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: mlflow
  namespace: mlops
  labels:
    app: mlflow
spec:
  type: ClusterIP
  ports:
  - port: 5000
    targetPort: 5000
    protocol: TCP
    name: http
  selector:
    app: mlflow
EOF

# Apply MLflow deployment
kubectl apply -f ~/mlops/Assignment/monitoring/mlflow-deployment.yaml

# Wait for MLflow to be ready
kubectl wait --for=condition=ready pod -l app=mlflow -n mlops --timeout=180s

# Verify MLflow
kubectl get pods -n mlops -l app=mlflow
kubectl get svc -n mlops -l app=mlflow
```

---

## 6. Setup Ingress

### 6.1 Deploy Heart Disease API
```bash
cd ~/mlops/Assignment/helm-charts

# Install/Upgrade API with Helm (ingress disabled - we'll create a unified ingress later)
helm upgrade --install heart-disease-api ./heart-disease-api \
  --namespace mlops \
  --set ingress.enabled=false \
  --set image.repository=heart-disease-api \
  --set image.tag=latest \
  --set image.pullPolicy=Never \
  --wait --timeout=300s

# Verify deployment
kubectl get pods -n mlops
kubectl get svc -n mlops
```

### 6.2 Create Unified Ingress Configuration
```bash
# Create ingress for all services
cat > ~/mlops/Assignment/ingress-complete.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mlops-ingress
  namespace: mlops
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/proxy-read-timeout: "300"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "300"
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
spec:
  ingressClassName: nginx
  rules:
  # Main API
  - host: api.mlops.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: heart-disease-api
            port:
              number: 80
  # Prometheus
  - host: prometheus.mlops.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: prometheus
            port:
              number: 9090
  # Grafana
  - host: grafana.mlops.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: grafana
            port:
              number: 3000
  # MLflow
  - host: mlflow.mlops.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: mlflow
            port:
              number: 5000
---
# IP-based ingress (alternative access method)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mlops-ingress-ip
  namespace: mlops
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
    nginx.ingress.kubernetes.io/proxy-read-timeout: "300"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "300"
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      # API: http://<IP>/api/
      - path: /api(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: heart-disease-api
            port:
              number: 80
      # Prometheus: http://<IP>/prometheus/
      - path: /prometheus(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: prometheus
            port:
              number: 9090
      # Grafana: http://<IP>/grafana/
      - path: /grafana(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: grafana
            port:
              number: 3000
      # MLflow: http://<IP>/mlflow/
      - path: /mlflow(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: mlflow
            port:
              number: 5000
      # Default: API root
      - path: /
        pathType: Prefix
        backend:
          service:
            name: heart-disease-api
            port:
              number: 80
EOF

# Apply ingress
kubectl apply -f ~/mlops/Assignment/ingress-complete.yaml

# Verify ingress
kubectl get ingress -n mlops
kubectl describe ingress mlops-ingress -n mlops
```

### 6.3 Configure Port Forwarding for Remote Access
```bash
# Get Minikube IP
MINIKUBE_IP=$(minikube ip)
echo "Minikube IP: $MINIKUBE_IP"

# Setup tunnel (run in background)
nohup minikube tunnel > /tmp/minikube-tunnel.log 2>&1 &

# Get ingress controller service
kubectl get svc -n ingress-nginx

# Alternative: Use NodePort for direct access
kubectl patch svc ingress-nginx-controller -n ingress-nginx -p '{"spec":{"type":"NodePort"}}'
```

---

## 7. Verify Deployment

### 7.1 Check All Pods
```bash
# Check all pods are running
kubectl get pods -n mlops

# Expected output should show:
# - heart-disease-api-xxx (2 replicas)
# - prometheus-xxx
# - grafana-xxx
# - mlflow-xxx

# Check pod logs if any issues
kubectl logs -n mlops <pod-name>
```

### 7.2 Check Services
```bash
# List all services
kubectl get svc -n mlops

# Should show:
# - heart-disease-api (ClusterIP)
# - prometheus (ClusterIP)
# - grafana (ClusterIP)
# - mlflow (ClusterIP)
```

### 7.3 Check Ingress
```bash
# Check ingress configuration
kubectl get ingress -n mlops
kubectl describe ingress mlops-ingress -n mlops

# Get ingress address
INGRESS_IP=$(kubectl get ingress mlops-ingress-ip -n mlops -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Ingress IP: $INGRESS_IP"
```

### 7.4 Test Services Locally
```bash
# Get Minikube IP
MINIKUBE_IP=$(minikube ip)

# Test API
curl http://$MINIKUBE_IP/health
curl http://$MINIKUBE_IP/metrics

# Test with host headers
curl -H "Host: api.mlops.local" http://$MINIKUBE_IP/health
curl -H "Host: prometheus.mlops.local" http://$MINIKUBE_IP/
curl -H "Host: grafana.mlops.local" http://$MINIKUBE_IP/
curl -H "Host: mlflow.mlops.local" http://$MINIKUBE_IP/
```

---

## 8. Remote Access

### 8.1 Setup Firewall Rules
```bash
# Allow HTTP/HTTPS traffic
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --reload

# Verify
sudo firewall-cmd --list-all
```

### 8.2 Setup HAProxy/Nginx Reverse Proxy

#### Option A: Using Nginx (Recommended)
```bash
# Install Nginx
sudo dnf install -y nginx

# IMPORTANT: Create clean nginx.conf to avoid conflicts with default server blocks
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%Y%m%d_%H%M%S)
sudo tee /etc/nginx/nginx.conf > /dev/null << 'NGINXCONF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 4096;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    include /etc/nginx/conf.d/*.conf;
}
NGINXCONF

# Create Nginx configuration in conf.d
sudo tee /etc/nginx/conf.d/mlops-proxy.conf > /dev/null << 'EOF'
# Get Minikube IP first: minikube ip
# Replace MINIKUBE_IP below with actual IP

upstream api_backend {
    server MINIKUBE_IP:80;
}

upstream prometheus_backend {
    server MINIKUBE_IP:80;
}

upstream grafana_backend {
    server MINIKUBE_IP:80;
}

upstream mlflow_backend {
    server MINIKUBE_IP:80;
}

# Main API
server {
    listen 80;
    server_name api.72.163.219.91 72.163.219.91;

    location / {
        proxy_pass http://api_backend;
        proxy_set_header Host api.mlops.local;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
}

# Prometheus
server {
    listen 9090;
    server_name 72.163.219.91;

    location / {
        proxy_pass http://prometheus_backend;
        proxy_set_header Host prometheus.mlops.local;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

# Grafana
server {
    listen 3000;
    server_name 72.163.219.91;

    location / {
        proxy_pass http://grafana_backend;
        proxy_set_header Host grafana.mlops.local;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

# MLflow
server {
    listen 5000;
    server_name 72.163.219.91;

    location / {
        proxy_pass http://mlflow_backend;
        proxy_set_header Host mlflow.mlops.local;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF

# Update MINIKUBE_IP in the config
MINIKUBE_IP=$(minikube ip)
sudo sed -i "s/MINIKUBE_IP/$MINIKUBE_IP/g" /etc/nginx/conf.d/mlops-proxy.conf

# IMPORTANT: Configure SELinux to allow Nginx to bind to non-standard ports
if command -v getenforce &> /dev/null && [ "$(getenforce)" != "Disabled" ]; then
    # Install SELinux management tools if needed
    if ! command -v semanage &> /dev/null; then
        sudo dnf install -y policycoreutils-python-utils
    fi
    
    # Allow Nginx to bind to ports 3000, 5000, 9090
    sudo semanage port -a -t http_port_t -p tcp 9090 2>/dev/null || sudo semanage port -m -t http_port_t -p tcp 9090
    sudo semanage port -a -t http_port_t -p tcp 3000 2>/dev/null || sudo semanage port -m -t http_port_t -p tcp 3000
    sudo semanage port -a -t http_port_t -p tcp 5000 2>/dev/null || sudo semanage port -m -t http_port_t -p tcp 5000
fi

# Test Nginx configuration
sudo nginx -t

# Start and enable Nginx
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl status nginx
```

#### Option B: Using HAProxy
```bash
# Install HAProxy
sudo dnf install -y haproxy

# Backup original config
sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.backup

# Create HAProxy configuration
MINIKUBE_IP=$(minikube ip)

sudo tee /etc/haproxy/haproxy.cfg > /dev/null << EOF
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    timeout connect 5000
    timeout client  300000
    timeout server  300000

# API Frontend
frontend api_frontend
    bind *:80
    default_backend api_backend

backend api_backend
    balance roundrobin
    http-request set-header Host api.mlops.local
    server minikube $MINIKUBE_IP:80 check

# Prometheus Frontend
frontend prometheus_frontend
    bind *:9090
    default_backend prometheus_backend

backend prometheus_backend
    balance roundrobin
    http-request set-header Host prometheus.mlops.local
    server minikube $MINIKUBE_IP:80 check

# Grafana Frontend
frontend grafana_frontend
    bind *:3000
    default_backend grafana_backend

backend grafana_backend
    balance roundrobin
    http-request set-header Host grafana.mlops.local
    server minikube $MINIKUBE_IP:80 check

# MLflow Frontend
frontend mlflow_frontend
    bind *:5000
    default_backend mlflow_backend

backend mlflow_backend
    balance roundrobin
    http-request set-header Host mlflow.mlops.local
    server minikube $MINIKUBE_IP:80 check
EOF

# Enable and start HAProxy
sudo setsebool -P haproxy_connect_any 1
sudo systemctl start haproxy
sudo systemctl enable haproxy
sudo systemctl status haproxy
```

### 8.3 Open Additional Firewall Ports
```bash
# Open ports for Prometheus, Grafana, MLflow
sudo firewall-cmd --permanent --add-port=9090/tcp
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --permanent --add-port=5000/tcp
sudo firewall-cmd --reload
```

### 8.4 Test Remote Access
```bash
# From remote machine, test:
# API
curl http://72.163.219.91/health
curl http://72.163.219.91/docs

# Prometheus
curl http://72.163.219.91:9090/

# Grafana
curl http://72.163.219.91:3000/

# MLflow
curl http://72.163.219.91:5000/
```

---

## 9. Troubleshooting

### 9.1 Check Minikube Status
```bash
minikube status
minikube logs

# If Minikube is not running
minikube start --driver=docker
```

### 9.2 Check Ingress Controller
```bash
# Check ingress-nginx namespace
kubectl get pods -n ingress-nginx

# If ingress controller is not running
minikube addons disable ingress
minikube addons enable ingress

# Wait for ingress controller
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

### 9.3 Check Pod Logs
```bash
# API logs
kubectl logs -n mlops -l app.kubernetes.io/name=heart-disease-api --tail=100

# Prometheus logs
kubectl logs -n mlops -l app=prometheus --tail=100

# Grafana logs
kubectl logs -n mlops -l app=grafana --tail=100

# MLflow logs
kubectl logs -n mlops -l app=mlflow --tail=100
```

### 9.4 Debug Ingress
```bash
# Check ingress configuration
kubectl describe ingress -n mlops

# Test ingress controller
kubectl run curl --image=curlimages/curl -i --rm --restart=Never -- \
  curl -H "Host: api.mlops.local" http://heart-disease-api.mlops.svc.cluster.local/health

# Check ingress logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx --tail=100
```

### 9.5 Restart Services
```bash
# Restart API
kubectl rollout restart deployment heart-disease-api -n mlops

# Restart Prometheus
kubectl rollout restart deployment prometheus -n mlops

# Restart Grafana
kubectl rollout restart deployment grafana -n mlops

# Restart MLflow
kubectl rollout restart deployment mlflow -n mlops
```

### 9.6 Clean Start
```bash
# Delete everything and start fresh
kubectl delete namespace mlops
minikube delete
minikube start --driver=docker --cpus=4 --memory=8192

# Then follow deployment steps again
```

---

## 📊 Access URLs

After successful deployment, access the services at:

| Service | URL | Credentials |
|---------|-----|-------------|
| **API** | http://72.163.219.91/health | - |
| **API Docs** | http://72.163.219.91/docs | - |
| **Prometheus** | http://72.163.219.91:9090 | - |
| **Grafana** | http://72.163.219.91:3000 | admin/admin |
| **MLflow** | http://72.163.219.91:5000 | - |

### Alternative Domain-based Access

Add to `/etc/hosts` on client machines:
```
72.163.219.91  api.mlops.local prometheus.mlops.local grafana.mlops.local mlflow.mlops.local
```

Then access via:
- http://api.mlops.local
- http://prometheus.mlops.local
- http://grafana.mlops.local
- http://mlflow.mlops.local

---

## 🔄 Quick Commands Reference

```bash
# Check everything
kubectl get all -n mlops

# Scale API
kubectl scale deployment heart-disease-api --replicas=3 -n mlops

# Update API image
eval $(minikube docker-env)
docker build -t heart-disease-api:latest -f Dockerfile.almalinux .
kubectl rollout restart deployment heart-disease-api -n mlops

# View logs
kubectl logs -n mlops -l app.kubernetes.io/name=heart-disease-api -f

# Port forward (for testing)
kubectl port-forward -n mlops svc/heart-disease-api 8080:80

# Get Minikube dashboard
minikube dashboard
```

---

## 📝 Notes

1. **Persistent Storage**: MLflow uses PersistentVolumeClaim for storing experiments
2. **Resource Limits**: Adjust CPU/memory in deployment files based on server capacity
3. **Security**: Consider adding TLS/SSL certificates for production use
4. **Backup**: Regularly backup `/var/lib/docker/volumes` for persistent data
5. **Monitoring**: Check Grafana dashboards after generating some API traffic

---

## 🎯 Next Steps

1. Configure Grafana dashboards (import from `monitoring/grafana-dashboard.json`)
2. Setup Prometheus alerts
3. Configure MLflow authentication
4. Add SSL/TLS certificates
5. Setup log aggregation (ELK/Loki)
6. Configure backup strategies

---

**Deployment Complete! 🎉**

Your MLOps application is now running on Alma Linux 8 with full monitoring and tracking capabilities accessible from remote servers.
