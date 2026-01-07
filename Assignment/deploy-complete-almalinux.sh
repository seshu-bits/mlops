#!/bin/bash

# Complete MLOps Deployment Script for Alma Linux 8
# This script automates the entire deployment process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Server IP
SERVER_IP="72.163.219.91"

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║       MLOps Complete Deployment - Alma Linux 8                ║"
echo "║   API + Prometheus + Grafana + MLflow + Ingress                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo "Server IP: $SERVER_IP"
echo ""

# Function to print step header
print_step() {
    echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Function to check command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}✗ $1 not found${NC}"
        return 1
    else
        echo -e "${GREEN}✓ $1 found${NC}"
        return 0
    fi
}

# Function to wait for pods
wait_for_pods() {
    local label=$1
    local namespace=$2
    local timeout=${3:-120}

    echo "Waiting for pods with label $label in namespace $namespace..."
    kubectl wait --for=condition=ready pod -l $label -n $namespace --timeout=${timeout}s
    echo -e "${GREEN}✓ Pods ready${NC}"
}

# Step 1: Prerequisites Check
print_step "Step 1: Checking Prerequisites"

PREREQUISITES_OK=true

check_command docker || PREREQUISITES_OK=false
check_command kubectl || PREREQUISITES_OK=false
check_command minikube || PREREQUISITES_OK=false
check_command helm || PREREQUISITES_OK=false
check_command git || PREREQUISITES_OK=false

if [ "$PREREQUISITES_OK" = false ]; then
    echo -e "\n${RED}Missing prerequisites. Please install them first.${NC}"
    echo "Run: sudo dnf install -y docker kubectl minikube helm git"
    exit 1
fi

# Step 2: Minikube Setup
print_step "Step 2: Setting up Minikube"

if minikube status &> /dev/null; then
    echo -e "${YELLOW}Minikube is already running${NC}"
    read -p "Do you want to restart it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        minikube delete
        minikube start --driver=docker --cpus=4 --memory=8192 --disk-size=40g
    fi
else
    echo "Starting Minikube..."
    minikube start --driver=docker --cpus=4 --memory=8192 --disk-size=40g
fi

echo "Enabling Minikube addons..."
minikube addons enable ingress
minikube addons enable metrics-server
minikube addons enable dashboard

echo -e "${GREEN}✓ Minikube ready${NC}"
MINIKUBE_IP=$(minikube ip)
echo "Minikube IP: $MINIKUBE_IP"

# Step 3: Create Namespace
print_step "Step 3: Creating Namespace"

if kubectl get namespace mlops &> /dev/null; then
    echo -e "${YELLOW}Namespace mlops already exists${NC}"
else
    kubectl create namespace mlops
    echo -e "${GREEN}✓ Namespace created${NC}"
fi

kubectl config set-context --current --namespace=mlops

# Step 4: Build Application
print_step "Step 4: Building Application"

# Use Minikube's Docker daemon
eval $(minikube docker-env)

echo "Building heart-disease-api..."

# Try different build methods
if docker build -t heart-disease-api:latest -f Dockerfile.almalinux . 2>/dev/null; then
    echo -e "${GREEN}✓ Built with Dockerfile.almalinux${NC}"
elif docker build -t heart-disease-api:latest -f Dockerfile.offline . 2>/dev/null; then
    echo -e "${GREEN}✓ Built with Dockerfile.offline${NC}"
elif [ -f "./smart-docker-build.sh" ]; then
    echo "Using smart build script..."
    chmod +x ./smart-docker-build.sh
    ./smart-docker-build.sh
else
    echo -e "${RED}Build failed. Please check Docker setup.${NC}"
    exit 1
fi

# Verify image
docker images | grep heart-disease-api

# Step 5: Deploy Monitoring Stack
print_step "Step 5: Deploying Monitoring Stack"

cd monitoring

echo "Deploying Prometheus..."
kubectl apply -f prometheus-config.yaml -n mlops
kubectl apply -f prometheus-deployment.yaml -n mlops
wait_for_pods "app=prometheus" "mlops" 120

echo "Deploying Grafana..."
kubectl apply -f grafana-deployment.yaml -n mlops
wait_for_pods "app=grafana" "mlops" 120

cd ..

# Step 6: Deploy MLflow
print_step "Step 6: Deploying MLflow"

cat > /tmp/mlflow-deployment.yaml << 'EOF'
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

kubectl apply -f /tmp/mlflow-deployment.yaml
wait_for_pods "app=mlflow" "mlops" 180

# Step 7: Deploy API
print_step "Step 7: Deploying Heart Disease API"

cd helm-charts

helm upgrade --install heart-disease-api ./heart-disease-api \
  --namespace mlops \
  --set ingress.enabled=true \
  --set image.repository=heart-disease-api \
  --set image.tag=latest \
  --set image.pullPolicy=Never \
  --wait --timeout=300s

cd ..

echo -e "${GREEN}✓ API deployed${NC}"

# Step 8: Setup Ingress
print_step "Step 8: Setting up Ingress"

cat > /tmp/ingress-complete.yaml << 'EOF'
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
      - path: /api(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: heart-disease-api
            port:
              number: 80
      - path: /prometheus(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: prometheus
            port:
              number: 9090
      - path: /grafana(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: grafana
            port:
              number: 3000
      - path: /mlflow(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: mlflow
            port:
              number: 5000
      - path: /
        pathType: Prefix
        backend:
          service:
            name: heart-disease-api
            port:
              number: 80
EOF

kubectl apply -f /tmp/ingress-complete.yaml

echo "Waiting for ingress controller..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s || true

# Step 9: Setup Minikube Tunnel
print_step "Step 9: Starting Minikube Tunnel"

# Kill existing tunnel if any
pkill -f "minikube tunnel" || true

# Start tunnel in background
echo "Starting minikube tunnel (requires sudo)..."
echo "You may be prompted for your password..."
nohup minikube tunnel > /tmp/minikube-tunnel.log 2>&1 &
sleep 5

# Step 10: Verification
print_step "Step 10: Verifying Deployment"

echo "Checking pods..."
kubectl get pods -n mlops

echo -e "\nChecking services..."
kubectl get svc -n mlops

echo -e "\nChecking ingress..."
kubectl get ingress -n mlops

# Test API locally
echo -e "\n${YELLOW}Testing API locally...${NC}"
sleep 10  # Give services time to stabilize

if curl -s -f http://$MINIKUBE_IP/health > /dev/null; then
    echo -e "${GREEN}✓ API health check passed${NC}"
else
    echo -e "${YELLOW}⚠ API not responding yet. It may take a few more moments.${NC}"
fi

# Step 11: Remote Access Setup
print_step "Step 11: Remote Access Configuration"

echo "Setting up Nginx reverse proxy..."

# Check if nginx is installed
if ! command -v nginx &> /dev/null; then
    echo "Installing Nginx..."
    sudo dnf install -y nginx
fi

# Create Nginx config
sudo tee /etc/nginx/conf.d/mlops-proxy.conf > /dev/null << EOF
upstream api_backend {
    server $MINIKUBE_IP:80;
}

server {
    listen 80 default_server;
    server_name $SERVER_IP _;

    location / {
        proxy_pass http://api_backend;
        proxy_set_header Host api.mlops.local;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
}

server {
    listen 9090;
    server_name $SERVER_IP;

    location / {
        proxy_pass http://api_backend;
        proxy_set_header Host prometheus.mlops.local;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}

server {
    listen 3000;
    server_name $SERVER_IP;

    location / {
        proxy_pass http://api_backend;
        proxy_set_header Host grafana.mlops.local;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}

server {
    listen 5000;
    server_name $SERVER_IP;

    location / {
        proxy_pass http://api_backend;
        proxy_set_header Host mlflow.mlops.local;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

# Test and restart Nginx
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx

# Configure firewall
echo "Configuring firewall..."
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --permanent --add-port=9090/tcp
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --permanent --add-port=5000/tcp
sudo firewall-cmd --reload

echo -e "${GREEN}✓ Remote access configured${NC}"

# Final Summary
print_step "🎉 Deployment Complete!"

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                      Access Information                        ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${GREEN}Local Access (from Alma Linux server):${NC}"
echo "  API:        http://$MINIKUBE_IP/health"
echo "  API Docs:   http://$MINIKUBE_IP/docs"
echo "  Prometheus: http://$MINIKUBE_IP (Host: prometheus.mlops.local)"
echo "  Grafana:    http://$MINIKUBE_IP (Host: grafana.mlops.local)"
echo "  MLflow:     http://$MINIKUBE_IP (Host: mlflow.mlops.local)"
echo ""
echo -e "${GREEN}Remote Access (from any network):${NC}"
echo "  API:        http://$SERVER_IP/"
echo "  API Docs:   http://$SERVER_IP/docs"
echo "  Prometheus: http://$SERVER_IP:9090"
echo "  Grafana:    http://$SERVER_IP:3000 (admin/admin)"
echo "  MLflow:     http://$SERVER_IP:5000"
echo ""
echo -e "${YELLOW}Important Notes:${NC}"
echo "  1. Minikube tunnel is running in background"
echo "  2. Check tunnel status: tail -f /tmp/minikube-tunnel.log"
echo "  3. Grafana default credentials: admin/admin"
echo "  4. To stop tunnel: pkill -f 'minikube tunnel'"
echo "  5. To restart deployment: kubectl rollout restart deployment -n mlops"
echo ""
echo -e "${BLUE}Quick Commands:${NC}"
echo "  View all pods:     kubectl get pods -n mlops"
echo "  View all services: kubectl get svc -n mlops"
echo "  View logs:         kubectl logs -n mlops -l app.kubernetes.io/name=heart-disease-api"
echo "  Scale API:         kubectl scale deployment heart-disease-api --replicas=3 -n mlops"
echo ""
echo -e "${GREEN}✓ All services deployed and accessible!${NC}"
echo ""
