# 🌐 Remote Access Configuration for Minikube Services

## Problem: Minikube IP is Not Accessible Remotely

**Minikube IP**: 192.168.49.2 (internal Docker network)  
**Server IP**: Your AlmaLinux public/private IP  
**Issue**: Remote machines cannot reach 192.168.49.2

---

## 🎯 Solution Options

### Option 1: Port Forwarding with kubectl (Recommended for Testing)
### Option 2: Minikube Tunnel (Recommended for Development)
### Option 3: HAProxy/NGINX Reverse Proxy (Recommended for Production)
### Option 4: NodePort with Host IP (Current Setup - Works!)

---

## ✅ Option 1: kubectl Port Forward (Simple & Quick)

Forward Minikube services to your server's network interface.

### Setup

```bash
# Get your server's IP
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "Server IP: $SERVER_IP"

# Forward API service to all interfaces (0.0.0.0)
kubectl port-forward -n mlops service/heart-disease-api 8080:80 --address 0.0.0.0 &

# Forward Prometheus
kubectl port-forward -n mlops service/prometheus 9090:9090 --address 0.0.0.0 &

# Forward Grafana
kubectl port-forward -n mlops service/grafana 3000:3000 --address 0.0.0.0 &
```

### Open Firewall

```bash
# Open ports for remote access
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --add-port=9090/tcp
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --reload
```

### Access from Remote

```bash
# From your local machine
SERVER_IP=<your-almalinux-ip>

curl http://$SERVER_IP:8080/health      # API
open http://$SERVER_IP:9090             # Prometheus
open http://$SERVER_IP:3000             # Grafana
```

### Make Persistent (systemd)

Create a service to run port-forward on startup:

```bash
# Create systemd service for API
sudo tee /etc/systemd/system/k8s-port-forward-api.service > /dev/null <<EOF
[Unit]
Description=Kubernetes Port Forward for API
After=network.target

[Service]
Type=simple
User=$USER
Environment="KUBECONFIG=/home/$USER/.kube/config"
ExecStart=/usr/local/bin/kubectl port-forward -n mlops service/heart-disease-api 8080:80 --address 0.0.0.0
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable k8s-port-forward-api
sudo systemctl start k8s-port-forward-api
sudo systemctl status k8s-port-forward-api
```

**Pros**: ✅ Simple, ✅ No extra tools  
**Cons**: ❌ Requires systemd services for persistence

---

## ✅ Option 2: Minikube Tunnel (Recommended)

Creates a route from your host to Minikube cluster.

### Setup

```bash
# Start minikube tunnel (requires sudo, run in background)
sudo -E minikube tunnel &

# This will create routes to access LoadBalancer services
```

### Change Services to LoadBalancer

```bash
# Update API to LoadBalancer type
kubectl patch svc heart-disease-api -n mlops -p '{"spec":{"type":"LoadBalancer"}}'

# Update Prometheus
kubectl patch svc prometheus -n mlops -p '{"spec":{"type":"LoadBalancer"}}'

# Update Grafana
kubectl patch svc grafana -n mlops -p '{"spec":{"type":"LoadBalancer"}}'

# Check external IPs (should show Minikube IP now routable)
kubectl get svc -n mlops
```

### Make Minikube Tunnel Persistent

```bash
# Create systemd service for minikube tunnel
sudo tee /etc/systemd/system/minikube-tunnel.service > /dev/null <<EOF
[Unit]
Description=Minikube Tunnel
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/minikube tunnel --cleanup
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable minikube-tunnel
sudo systemctl start minikube-tunnel
sudo systemctl status minikube-tunnel
```

**Pros**: ✅ Native Kubernetes LoadBalancer support, ✅ Automatic  
**Cons**: ❌ Requires sudo, ❌ Minikube-specific

---

## ✅ Option 3: NGINX/HAProxy Reverse Proxy (Production)

Set up a reverse proxy on the host that forwards to Minikube services.

### Install NGINX

```bash
sudo dnf install nginx -y
sudo systemctl enable nginx
```

### Configure NGINX

```bash
# Create NGINX config for API
sudo tee /etc/nginx/conf.d/mlops-api.conf > /dev/null <<EOF
upstream api_backend {
    server 192.168.49.2:30080;  # Minikube IP + NodePort
}

upstream prometheus_backend {
    server 192.168.49.2:30090;
}

upstream grafana_backend {
    server 192.168.49.2:30030;
}

server {
    listen 80;
    server_name _;

    # API endpoints
    location / {
        proxy_pass http://api_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Increase timeouts for long-running predictions
        proxy_read_timeout 300s;
        proxy_connect_timeout 300s;
    }
}

server {
    listen 9090;
    server_name _;

    location / {
        proxy_pass http://prometheus_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}

server {
    listen 3000;
    server_name _;

    location / {
        proxy_pass http://grafana_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

# Test configuration
sudo nginx -t

# Restart NGINX
sudo systemctl restart nginx
```

### Open Firewall

```bash
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-port=9090/tcp
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --reload
```

### SELinux Configuration

```bash
# Allow NGINX to make network connections
sudo setsebool -P httpd_can_network_connect 1
```

### Access from Remote

```bash
SERVER_IP=<your-almalinux-ip>

curl http://$SERVER_IP/health           # API on port 80
open http://$SERVER_IP:9090             # Prometheus
open http://$SERVER_IP:3000             # Grafana
```

**Pros**: ✅ Production-grade, ✅ SSL/TLS support, ✅ Load balancing, ✅ Persistent  
**Cons**: ❌ Extra component to manage

---

## ✅ Option 4: NodePort with iptables (Current - Already Works!)

Your current NodePort setup SHOULD work with proper iptables rules.

### Verify Current Setup

```bash
# Check services
kubectl get svc -n mlops

# Get NodePorts
API_PORT=$(kubectl get svc heart-disease-api -n mlops -o jsonpath='{.spec.ports[0].nodePort}')
PROM_PORT=$(kubectl get svc prometheus -n mlops -o jsonpath='{.spec.ports[0].nodePort}')
GRAF_PORT=$(kubectl get svc grafana -n mlops -o jsonpath='{.spec.ports[0].nodePort}')

echo "API NodePort: $API_PORT (should be 30080)"
echo "Prometheus NodePort: $PROM_PORT (should be 30090)"
echo "Grafana NodePort: $GRAF_PORT (should be 30030)"
```

### Configure iptables to Route to Minikube

```bash
# Get Minikube IP
MINIKUBE_IP=$(minikube ip)
echo "Minikube IP: $MINIKUBE_IP"

# Forward external traffic on NodePorts to Minikube
sudo iptables -t nat -A PREROUTING -p tcp --dport 30080 -j DNAT --to-destination ${MINIKUBE_IP}:30080
sudo iptables -t nat -A PREROUTING -p tcp --dport 30090 -j DNAT --to-destination ${MINIKUBE_IP}:30090
sudo iptables -t nat -A PREROUTING -p tcp --dport 30030 -j DNAT --to-destination ${MINIKUBE_IP}:30030

# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf

# Add POSTROUTING rule for NAT
sudo iptables -t nat -A POSTROUTING -j MASQUERADE

# Save iptables rules (AlmaLinux 8)
sudo iptables-save | sudo tee /etc/sysconfig/iptables
```

### Open Firewall

```bash
sudo firewall-cmd --permanent --add-port=30080/tcp
sudo firewall-cmd --permanent --add-port=30090/tcp
sudo firewall-cmd --permanent --add-port=30030/tcp
sudo firewall-cmd --reload
```

### Test from Remote

```bash
SERVER_IP=<your-almalinux-ip>

curl http://$SERVER_IP:30080/health
curl http://$SERVER_IP:30090
curl http://$SERVER_IP:30030
```

**Pros**: ✅ Uses existing setup, ✅ No extra services  
**Cons**: ❌ Requires iptables management

---

## 🚀 Recommended Solution: NGINX Reverse Proxy

For your production use case, I recommend **Option 3 (NGINX)** because:

1. ✅ Production-grade and reliable
2. ✅ Easy to configure SSL/TLS later
3. ✅ Persistent across reboots
4. ✅ Can add authentication
5. ✅ Better logging and monitoring
6. ✅ Load balancing capabilities

### Quick Setup Script

```bash
#!/bin/bash
# Setup NGINX reverse proxy for Minikube services

set -e

echo "🔧 Setting up NGINX reverse proxy for Minikube services"

# Install NGINX
echo "Installing NGINX..."
sudo dnf install nginx -y

# Get Minikube IP
MINIKUBE_IP=$(minikube ip)
echo "Minikube IP: $MINIKUBE_IP"

# Create NGINX configuration
echo "Creating NGINX configuration..."
sudo tee /etc/nginx/conf.d/mlops.conf > /dev/null <<EOF
# API Backend
upstream api_backend {
    server ${MINIKUBE_IP}:30080;
}

# Prometheus Backend
upstream prometheus_backend {
    server ${MINIKUBE_IP}:30090;
}

# Grafana Backend
upstream grafana_backend {
    server ${MINIKUBE_IP}:30030;
}

# API Server on port 80
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://api_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_read_timeout 300s;
    }
}

# Prometheus Server on port 9090
server {
    listen 9090;
    location / {
        proxy_pass http://prometheus_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}

# Grafana Server on port 3000
server {
    listen 3000;
    location / {
        proxy_pass http://grafana_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

# Test NGINX configuration
echo "Testing NGINX configuration..."
sudo nginx -t

# Configure SELinux
echo "Configuring SELinux..."
sudo setsebool -P httpd_can_network_connect 1

# Configure firewall
echo "Configuring firewall..."
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-port=9090/tcp
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --reload

# Enable and start NGINX
echo "Starting NGINX..."
sudo systemctl enable nginx
sudo systemctl restart nginx

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "✅ Setup complete!"
echo ""
echo "Access your services from remote machines:"
echo "  API:        http://${SERVER_IP}/"
echo "  Prometheus: http://${SERVER_IP}:9090"
echo "  Grafana:    http://${SERVER_IP}:3000"
echo ""
echo "Test locally:"
echo "  curl http://localhost/health"
echo "  curl http://localhost:9090/-/healthy"
echo "  curl http://localhost:3000/api/health"
EOF

chmod +x setup-nginx-proxy.sh
```

---

## 🧪 Testing Remote Access

### From Remote Machine

```bash
# Replace with your actual AlmaLinux IP
SERVER_IP=<your-server-ip>

# Test API
curl http://$SERVER_IP/health
curl http://$SERVER_IP/docs

# Test Prometheus (in browser)
open http://$SERVER_IP:9090

# Test Grafana (in browser)
open http://$SERVER_IP:3000
```

### Troubleshooting

```bash
# Check if NGINX is running
sudo systemctl status nginx

# Check NGINX error logs
sudo tail -f /var/log/nginx/error.log

# Check if ports are listening
sudo ss -tulpn | grep -E '(:80|:3000|:9090)'

# Test from server itself
curl http://localhost/health
curl http://localhost:9090/-/healthy
curl http://localhost:3000/api/health

# Check firewall
sudo firewall-cmd --list-all

# Check SELinux (if issues)
sudo ausearch -m avc -ts recent
sudo setenforce 0  # Temporarily disable for testing
```

---

## 📋 Summary

| Solution | Complexity | Production Ready | Persistent | Recommendation |
|----------|------------|------------------|------------|----------------|
| kubectl port-forward | Low | ❌ | ⚠️ (with systemd) | Testing only |
| minikube tunnel | Low | ❌ | ⚠️ (with systemd) | Development |
| **NGINX Proxy** | Medium | ✅ | ✅ | **✅ Recommended** |
| iptables NAT | High | ⚠️ | ✅ | Alternative |

## 🎯 Next Steps

1. Choose **NGINX reverse proxy** (recommended)
2. Run the setup script
3. Test remote access
4. Configure SSL/TLS for HTTPS
5. Add authentication if needed

Your services will be accessible from any remote machine using your AlmaLinux server's IP! 🚀
