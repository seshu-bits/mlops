# 🌐 Remote Access via Server IP - Ingress Configuration Guide

## Complete Step-by-Step Guide to Access Your Service from Remote Hosts

This guide shows exactly how to configure AlmaLinux with Minikube so remote systems can access your service using the server's IP address.

---

## 📋 Prerequisites

- AlmaLinux 8 server with Minikube installed
- Your service deployed with Helm
- kubectl configured
- Root/sudo access

---

## 🚀 Complete Configuration Steps

### Step 1: Get Your AlmaLinux Server IP

```bash
# On AlmaLinux server, get your IP address
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "Server IP: $SERVER_IP"

# Or manually check all IPs
ip addr show | grep "inet " | grep -v 127.0.0.1

# Note down your server's IP (e.g., 192.168.1.100)
```

### Step 2: Enable Ingress Addon in Minikube

```bash
# Enable the ingress addon
minikube addons enable ingress

# Verify it's enabled
minikube addons list | grep ingress

# Wait for ingress controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Check ingress controller status
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

### Step 3: Find Ingress Controller NodePorts

```bash
# Get the ingress-nginx-controller service details
kubectl get svc ingress-nginx-controller -n ingress-nginx

# Output will look like:
# NAME                       TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
# ingress-nginx-controller   NodePort   10.96.195.123   <none>        80:32080/TCP,443:32443/TCP   5m

# Extract the NodePorts
HTTP_NODEPORT=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}')
HTTPS_NODEPORT=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.ports[?(@.port==443)].nodePort}')

echo "HTTP NodePort: $HTTP_NODEPORT"
echo "HTTPS NodePort: $HTTPS_NODEPORT"

# Note these ports (e.g., HTTP: 32080, HTTPS: 32443)
```

### Step 4: Configure Firewall on AlmaLinux

```bash
# Open the ingress NodePorts
sudo firewall-cmd --permanent --add-port=${HTTP_NODEPORT}/tcp
sudo firewall-cmd --permanent --add-port=${HTTPS_NODEPORT}/tcp

# Also open your service NodePort (if using direct service access)
sudo firewall-cmd --permanent --add-port=30080/tcp

# Optional: Open standard HTTP/HTTPS ports for documentation
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp

# Apply firewall changes
sudo firewall-cmd --reload

# Verify firewall rules
sudo firewall-cmd --list-ports

# Check firewall status
sudo firewall-cmd --list-all
```

### Step 5: Configure Ingress to Accept IP-Based Requests

Your current ingress configuration only accepts requests for `heart-disease-api.local`. To accept requests using the server IP, you have two options:

**Option A: Add IP-based host to ingress (Recommended)**

Update your Helm values file:

```bash
cd ~/helm-charts/heart-disease-api
nano values.yaml
```

Modify the ingress section:
```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
  hosts:
    - host: heart-disease-api.local
      paths:
        - path: /
          pathType: Prefix
    # Add IP-based access using nip.io or xip.io
    - host: ""  # Empty host matches all requests
      paths:
        - path: /
          pathType: Prefix
  tls: []
```

Or use a wildcard service like nip.io:
```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations: {}
  hosts:
    - host: heart-disease-api.local
      paths:
        - path: /
          pathType: Prefix
    - host: "192.168.1.100.nip.io"  # Replace with your actual IP
      paths:
        - path: /
          pathType: Prefix
  tls: []
```

**Option B: Configure NGINX to accept any host**

Add annotation to accept all hosts:
```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    nginx.ingress.kubernetes.io/server-snippet: |
      server_name _;
  hosts:
    - host: heart-disease-api.local
      paths:
        - path: /
          pathType: Prefix
  tls: []
```

Apply the changes:
```bash
# Upgrade the Helm release
helm upgrade heart-disease-api ./heart-disease-api -n mlops

# Verify ingress was updated
kubectl get ingress -n mlops
kubectl describe ingress -n mlops heart-disease-api
```

### Step 6: Set Up Port Forwarding (Critical for Docker Driver)

Since Minikube runs in Docker, you need to forward traffic from the host to Minikube:

**Method 1: Using kubectl port-forward (Recommended)**

```bash
# Forward ingress-nginx-controller to host's standard ports
# Run in background
nohup kubectl port-forward -n ingress-nginx \
  --address 0.0.0.0 \
  service/ingress-nginx-controller 80:80 443:443 \
  > /tmp/ingress-forward.log 2>&1 &

# Check if it's running
ps aux | grep "port-forward"
tail -f /tmp/ingress-forward.log
```

**Method 2: Using socat (Alternative)**

```bash
# Install socat if not available
sudo dnf install -y socat

# Forward port 80 to ingress NodePort
sudo socat TCP-LISTEN:80,fork,reuseaddr TCP:$(minikube ip):${HTTP_NODEPORT} &

# Forward port 443 to ingress HTTPS NodePort
sudo socat TCP-LISTEN:443,fork,reuseaddr TCP:$(minikube ip):${HTTPS_NODEPORT} &
```

**Method 3: Make port-forward persistent with systemd**

```bash
# Create systemd service file
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

# Enable and start the service
sudo systemctl enable k8s-ingress-forward
sudo systemctl start k8s-ingress-forward

# Check status
sudo systemctl status k8s-ingress-forward

# View logs
sudo journalctl -u k8s-ingress-forward -f
```

### Step 7: Test Local Access First

```bash
# Get Minikube IP
MINIKUBE_IP=$(minikube ip)
echo "Minikube IP: $MINIKUBE_IP"

# Test 1: Direct access to service NodePort
curl http://$MINIKUBE_IP:30080/health
echo "✓ Direct service access works"

# Test 2: Access via ingress with Host header
curl -H "Host: heart-disease-api.local" http://$MINIKUBE_IP:$HTTP_NODEPORT/health
echo "✓ Ingress with Host header works"

# Test 3: Access via localhost (after port-forward)
curl -H "Host: heart-disease-api.local" http://localhost/health
echo "✓ Port-forward to localhost works"

# Test 4: Access via server IP (after port-forward)
curl -H "Host: heart-disease-api.local" http://$SERVER_IP/health
echo "✓ Access via server IP works"
```

### Step 8: Verify from Remote Host

Now test from your **remote client machine**:

**Test 1: Direct Service NodePort (Simplest)**
```bash
# From remote machine
curl http://<SERVER_IP>:30080/health

# Example
curl http://192.168.1.100:30080/health
```

**Test 2: Via Ingress NodePort with Host Header**
```bash
# From remote machine
curl -H "Host: heart-disease-api.local" http://<SERVER_IP>:32080/health

# Replace 32080 with your actual HTTP_NODEPORT
curl -H "Host: heart-disease-api.local" http://192.168.1.100:32080/health
```

**Test 3: Via Standard Port 80 (After port-forward setup)**
```bash
# From remote machine (after setting up port-forward in Step 6)
curl -H "Host: heart-disease-api.local" http://<SERVER_IP>/health

# Example
curl -H "Host: heart-disease-api.local" http://192.168.1.100/health
```

**Test 4: Without Host Header (If configured in Step 5)**
```bash
# From remote machine
curl http://<SERVER_IP>/health

# Or using nip.io
curl http://192.168.1.100.nip.io/health
```

### Step 9: Full API Testing

```bash
# Test prediction endpoint from remote machine
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

# Test batch prediction
curl -X POST http://<SERVER_IP>:30080/batch_predict \
  -H "Content-Type: application/json" \
  -d '{
    "patients": [
      {
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
      }
    ]
  }'
```

---

## 🔧 Complete Automation Script

Save this as `setup_remote_ingress.sh` on your AlmaLinux server:

```bash
#!/bin/bash

set -e  # Exit on error

echo "=========================================="
echo "Setting up Ingress for Remote IP Access"
echo "=========================================="
echo ""

# Step 1: Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "Step 1: Server IP detected: $SERVER_IP"
echo ""

# Step 2: Enable ingress
echo "Step 2: Enabling ingress addon..."
minikube addons enable ingress
echo ""

# Step 3: Wait for ingress controller
echo "Step 3: Waiting for ingress controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
echo ""

# Step 4: Get NodePorts
echo "Step 4: Getting ingress NodePorts..."
HTTP_NODEPORT=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}')
HTTPS_NODEPORT=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.ports[?(@.port==443)].nodePort}')
echo "HTTP NodePort: $HTTP_NODEPORT"
echo "HTTPS NodePort: $HTTPS_NODEPORT"
echo ""

# Step 5: Configure firewall
echo "Step 5: Configuring firewall..."
sudo firewall-cmd --permanent --add-port=${HTTP_NODEPORT}/tcp
sudo firewall-cmd --permanent --add-port=${HTTPS_NODEPORT}/tcp
sudo firewall-cmd --permanent --add-port=30080/tcp
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --reload
echo "Firewall configured"
echo ""

# Step 6: Update ingress configuration
echo "Step 6: Updating ingress to accept all hosts..."
cd ~/helm-charts/heart-disease-api

# Backup current values
cp values.yaml values.yaml.backup

# Update values.yaml to accept any host
cat > /tmp/ingress_patch.yaml <<EOF
ingress:
  enabled: true
  className: "nginx"
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
  hosts:
    - host: heart-disease-api.local
      paths:
        - path: /
          pathType: Prefix
    - host: ""
      paths:
        - path: /
          pathType: Prefix
  tls: []
EOF

# Apply the update
helm upgrade heart-disease-api ./heart-disease-api -n mlops \
  -f /tmp/ingress_patch.yaml
echo "Ingress configuration updated"
echo ""

# Step 7: Set up port forwarding
echo "Step 7: Setting up port forwarding..."

# Kill any existing port-forward
pkill -f "kubectl port-forward.*ingress-nginx" || true

# Create systemd service
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
echo "Port forwarding service started"
echo ""

# Step 8: Wait for everything to be ready
echo "Step 8: Waiting for services to be ready..."
sleep 10
echo ""

# Step 9: Test local access
echo "Step 9: Testing local access..."
MINIKUBE_IP=$(minikube ip)

# Test service NodePort
if curl -s http://$MINIKUBE_IP:30080/health > /dev/null; then
    echo "✓ Service NodePort working"
else
    echo "✗ Service NodePort failed"
fi

# Test ingress via NodePort
if curl -s -H "Host: heart-disease-api.local" http://$MINIKUBE_IP:$HTTP_NODEPORT/health > /dev/null; then
    echo "✓ Ingress via NodePort working"
else
    echo "✗ Ingress via NodePort failed"
fi

# Test via localhost after port-forward
if curl -s http://localhost/health > /dev/null; then
    echo "✓ Port forward working"
else
    echo "✗ Port forward failed (may need a few more seconds)"
fi

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Your service is now accessible from remote hosts using:"
echo ""
echo "1. Direct Service Access (No Host Header Required):"
echo "   curl http://$SERVER_IP:30080/health"
echo ""
echo "2. Via Ingress NodePort (With Host Header):"
echo "   curl -H \"Host: heart-disease-api.local\" http://$SERVER_IP:$HTTP_NODEPORT/health"
echo ""
echo "3. Via Standard Port 80 (With Host Header):"
echo "   curl -H \"Host: heart-disease-api.local\" http://$SERVER_IP/health"
echo ""
echo "4. Via Standard Port 80 (Without Host Header - if ingress configured for any host):"
echo "   curl http://$SERVER_IP/health"
echo ""
echo "Test from your remote machine using any of the above commands!"
echo ""
echo "To check port-forward status:"
echo "   sudo systemctl status k8s-ingress-forward"
echo ""
echo "To view logs:"
echo "   sudo journalctl -u k8s-ingress-forward -f"
echo ""
```

Make it executable and run:
```bash
chmod +x setup_remote_ingress.sh
./setup_remote_ingress.sh
```

---

## 🔍 Troubleshooting

### Issue 1: Remote host cannot connect

```bash
# On AlmaLinux server, check if port is listening
sudo ss -tlnp | grep -E '80|443|30080'

# Check firewall
sudo firewall-cmd --list-all

# Check if SELinux is blocking
sudo getenforce
sudo ausearch -m avc -ts recent

# Temporarily disable firewall to test
sudo systemctl stop firewalld
# Try from remote, then re-enable
sudo systemctl start firewalld
```

### Issue 2: Port forward keeps disconnecting

```bash
# Check systemd service status
sudo systemctl status k8s-ingress-forward

# View logs
sudo journalctl -u k8s-ingress-forward -n 50

# Restart service
sudo systemctl restart k8s-ingress-forward

# Check if kubectl is working
kubectl get pods -n ingress-nginx
```

### Issue 3: Getting 404 Not Found

```bash
# Check ingress configuration
kubectl get ingress -n mlops
kubectl describe ingress -n mlops heart-disease-api

# Check if backend service is healthy
kubectl get svc -n mlops
kubectl get endpoints -n mlops

# Check ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller --tail=100

# Verify ingress rules
kubectl get ingress -n mlops heart-disease-api -o yaml
```

### Issue 4: Connection refused

```bash
# Check if Minikube is running
minikube status

# Check if pods are running
kubectl get pods -n mlops

# Check if service exists
kubectl get svc -n mlops

# Test from within Minikube
minikube ssh
curl http://localhost:30080/health
exit
```

### Issue 5: SELinux denying connections

```bash
# Check SELinux denials
sudo ausearch -m avc -ts recent | grep denied

# Allow HTTP connections (if needed)
sudo setsebool -P httpd_can_network_connect 1

# For specific ports
sudo semanage port -a -t http_port_t -p tcp 30080
sudo semanage port -a -t http_port_t -p tcp 32080

# If still having issues, check context
ls -Z /usr/bin/kubectl
```

---

## 📊 Verification Checklist

Run this verification script on AlmaLinux:

```bash
#!/bin/bash

echo "=== Ingress Configuration Verification ==="
echo ""

SERVER_IP=$(hostname -I | awk '{print $1}')
echo "1. Server IP: $SERVER_IP"
echo ""

echo "2. Minikube Status:"
minikube status
echo ""

echo "3. Ingress Addon Status:"
minikube addons list | grep ingress
echo ""

echo "4. Ingress Controller Pods:"
kubectl get pods -n ingress-nginx
echo ""

echo "5. Ingress Controller Service:"
kubectl get svc -n ingress-nginx
echo ""

echo "6. Application Service:"
kubectl get svc -n mlops
echo ""

echo "7. Ingress Resource:"
kubectl get ingress -n mlops
echo ""

echo "8. Application Pods:"
kubectl get pods -n mlops
echo ""

echo "9. Firewall Rules:"
sudo firewall-cmd --list-ports
echo ""

echo "10. Port Forward Service Status:"
sudo systemctl status k8s-ingress-forward --no-pager
echo ""

echo "11. Listening Ports:"
sudo ss -tlnp | grep -E '80|443|30080'
echo ""

echo "12. Local Health Check:"
curl -s http://localhost/health && echo "✓ Localhost access OK" || echo "✗ Localhost access failed"
echo ""

echo "=== Copy this command to test from remote host ==="
echo "curl http://$SERVER_IP:30080/health"
```

---

## 🎯 Summary - Quick Reference

### On AlmaLinux Server:

```bash
# 1. Enable ingress
minikube addons enable ingress

# 2. Get NodePorts
HTTP_NODEPORT=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}')
echo "HTTP NodePort: $HTTP_NODEPORT"

# 3. Configure firewall
sudo firewall-cmd --permanent --add-port=${HTTP_NODEPORT}/tcp
sudo firewall-cmd --permanent --add-port=30080/tcp
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --reload

# 4. Set up port forwarding
kubectl port-forward -n ingress-nginx --address 0.0.0.0 service/ingress-nginx-controller 80:80 443:443 &

# 5. Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "Access via: http://$SERVER_IP:30080/health"
```

### From Remote Host:

```bash
# Direct service access (simplest, always works)
curl http://<SERVER_IP>:30080/health

# Via ingress NodePort
curl -H "Host: heart-disease-api.local" http://<SERVER_IP>:32080/health

# Via standard port (after port-forward)
curl http://<SERVER_IP>/health
```

**That's it!** Your service is now accessible from any remote host using the server's IP address.
