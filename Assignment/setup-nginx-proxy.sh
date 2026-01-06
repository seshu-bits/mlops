#!/bin/bash
# Setup NGINX reverse proxy for Minikube services
# This allows remote access to services running in Minikube

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║   NGINX Reverse Proxy Setup for Minikube Services     ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root or with sudo
if [[ $EUID -eq 0 ]]; then
   echo "⚠️  Please run this script as a regular user (it will use sudo when needed)"
   exit 1
fi

# Check if Minikube is running
if ! minikube status > /dev/null 2>&1; then
    echo "❌ Minikube is not running. Please start it first:"
    echo "   minikube start"
    exit 1
fi

# Get Minikube IP
MINIKUBE_IP=$(minikube ip)
echo "✓ Minikube IP: $MINIKUBE_IP"

# Get Server IP
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "✓ Server IP: $SERVER_IP"
echo ""

# Install NGINX
echo "📦 Installing NGINX..."
if ! command -v nginx &> /dev/null; then
    sudo dnf install nginx -y
    echo "✓ NGINX installed"
else
    echo "✓ NGINX already installed"
fi
echo ""

# Create NGINX configuration
echo "📝 Creating NGINX configuration..."
sudo tee /etc/nginx/conf.d/mlops-proxy.conf > /dev/null <<EOF
# MLOps Services Reverse Proxy Configuration
# Created by setup-nginx-proxy.sh

# API Backend (Minikube NodePort 30080)
upstream api_backend {
    server ${MINIKUBE_IP}:30080;
}

# Prometheus Backend (Minikube NodePort 30090)
upstream prometheus_backend {
    server ${MINIKUBE_IP}:30090;
}

# Grafana Backend (Minikube NodePort 30030)
upstream grafana_backend {
    server ${MINIKUBE_IP}:30030;
}

# API Server on port 80
server {
    listen 80;
    listen [::]:80;
    server_name _;

    # Increase body size for large predictions
    client_max_body_size 10M;

    location / {
        proxy_pass http://api_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # Increase timeouts for long-running predictions
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
        proxy_send_timeout 300s;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://api_backend/health;
        access_log off;
    }
}

# Prometheus Server on port 9090
server {
    listen 9090;
    listen [::]:9090;
    server_name _;

    location / {
        proxy_pass http://prometheus_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}

# Grafana Server on port 3000
server {
    listen 3000;
    listen [::]:3000;
    server_name _;

    location / {
        proxy_pass http://grafana_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

        # WebSocket support for Grafana live updates
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF

echo "✓ NGINX configuration created"
echo ""

# Test NGINX configuration
echo "🔍 Testing NGINX configuration..."
if sudo nginx -t > /dev/null 2>&1; then
    echo "✓ NGINX configuration is valid"
else
    echo "❌ NGINX configuration has errors:"
    sudo nginx -t
    exit 1
fi
echo ""

# Configure SELinux
echo "🔒 Configuring SELinux..."
if command -v getenforce &> /dev/null; then
    SELINUX_STATUS=$(getenforce)
    if [ "$SELINUX_STATUS" != "Disabled" ]; then
        sudo setsebool -P httpd_can_network_connect 1
        echo "✓ SELinux configured to allow NGINX network connections"
    else
        echo "ℹ️  SELinux is disabled"
    fi
fi
echo ""

# Configure firewall
echo "🔥 Configuring firewall..."
if command -v firewall-cmd &> /dev/null; then
    if sudo firewall-cmd --state > /dev/null 2>&1; then
        sudo firewall-cmd --permanent --add-service=http > /dev/null
        sudo firewall-cmd --permanent --add-port=9090/tcp > /dev/null
        sudo firewall-cmd --permanent --add-port=3000/tcp > /dev/null
        sudo firewall-cmd --reload > /dev/null
        echo "✓ Firewall configured (ports 80, 3000, 9090 opened)"
    else
        echo "⚠️  Firewall is not running"
    fi
else
    echo "ℹ️  firewalld not found"
fi
echo ""

# Enable and start NGINX
echo "🚀 Starting NGINX..."
sudo systemctl enable nginx > /dev/null 2>&1
sudo systemctl restart nginx

if sudo systemctl is-active --quiet nginx; then
    echo "✓ NGINX is running"
else
    echo "❌ Failed to start NGINX"
    sudo systemctl status nginx
    exit 1
fi
echo ""

# Test local connectivity
echo "🧪 Testing local connectivity..."
sleep 2

if curl -sf http://localhost/health > /dev/null 2>&1; then
    echo "✓ API is accessible via NGINX"
else
    echo "⚠️  API health check failed (service might still be starting)"
fi

if curl -sf http://localhost:9090/-/healthy > /dev/null 2>&1; then
    echo "✓ Prometheus is accessible via NGINX"
else
    echo "⚠️  Prometheus health check failed"
fi

if curl -sf http://localhost:3000/api/health > /dev/null 2>&1; then
    echo "✓ Grafana is accessible via NGINX"
else
    echo "⚠️  Grafana health check failed"
fi
echo ""

# Display success message
echo "╔════════════════════════════════════════════════════════╗"
echo "║                   ✅ Setup Complete!                   ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "Your services are now accessible from remote machines:"
echo ""
echo "  🌐 API (Heart Disease Prediction):"
echo "     http://${SERVER_IP}/"
echo "     http://${SERVER_IP}/health"
echo "     http://${SERVER_IP}/docs"
echo ""
echo "  📊 Prometheus:"
echo "     http://${SERVER_IP}:9090"
echo ""
echo "  📈 Grafana:"
echo "     http://${SERVER_IP}:3000"
echo "     Login: admin / admin"
echo ""
echo "Test from your local machine:"
echo "  curl http://${SERVER_IP}/health"
echo "  open http://${SERVER_IP}/docs"
echo ""
echo "Configuration file: /etc/nginx/conf.d/mlops-proxy.conf"
echo ""
echo "Logs:"
echo "  NGINX access: sudo tail -f /var/log/nginx/access.log"
echo "  NGINX error:  sudo tail -f /var/log/nginx/error.log"
echo ""
