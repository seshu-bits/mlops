# 🌐 Remote Access Configuration Guide - AlmaLinux 8

## Complete Guide to Configure Ingress for Remote Access

This guide explains how to configure your Kubernetes service running on AlmaLinux 8 with Minikube to be accessible from remote systems.

---

## 📋 Table of Contents

1. [Understanding Your Current Setup](#understanding-your-current-setup)
2. [Option 1: NodePort Access (Quick & Simple)](#option-1-nodeport-access-quick--simple)
3. [Option 2: Ingress with NGINX (Production-Ready)](#option-2-ingress-with-nginx-production-ready)
4. [Option 3: MetalLB LoadBalancer (Advanced)](#option-3-metallb-loadbalancer-advanced)
5. [Troubleshooting](#troubleshooting)
6. [Security Considerations](#security-considerations)

---

## Understanding Your Current Setup

Your service is configured with:
- **Service Type**: NodePort (port 30080)
- **Ingress**: Enabled with NGINX class
- **Host**: `heart-disease-api.local`
- **Container Port**: 8000
- **Service Port**: 80

---

## Option 1: NodePort Access (Quick & Simple)

**Best for**: Quick testing, development, simple deployments

### Step 1: Configure Firewall on AlmaLinux Server

```bash
# Open the NodePort in firewall
sudo firewall-cmd --permanent --add-port=30080/tcp
sudo firewall-cmd --reload

# Verify firewall rules
sudo firewall-cmd --list-ports

# Check if port is listening
sudo ss -tlnp | grep 30080
```

### Step 2: Get Minikube IP

```bash
# Get Minikube node IP
minikube ip

# Or get the service URL directly
minikube service heart-disease-api -n mlops --url
```

### Step 3: Access from Remote System

Since Minikube runs in Docker, you need to access via the **host machine's IP**, not Minikube's internal IP.

```bash
# From remote system:
# Get your AlmaLinux server's IP
curl http://<ALMALINUX_SERVER_IP>:30080/health

# Example:
curl http://192.168.1.100:30080/health
```

### Step 4: Port Forwarding (If Minikube is in Docker)

If direct access doesn't work, set up port forwarding:

```bash
# On AlmaLinux server, forward traffic from host to Minikube
kubectl port-forward -n mlops --address 0.0.0.0 \
  service/heart-disease-api 30080:80 &

# Now access from remote:
curl http://<ALMALINUX_SERVER_IP>:30080/health
```

---

## Option 2: Ingress with NGINX (Production-Ready)

**Best for**: Production deployments, multiple services, domain-based routing

### Step 1: Enable NGINX Ingress Controller

```bash
# Enable ingress addon in Minikube
minikube addons enable ingress

# Wait for ingress controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Verify ingress controller is running
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

### Step 2: Configure Ingress NodePort Access

The ingress controller itself exposes NodePorts. Find them:

```bash
# Get ingress controller service details
kubectl get svc ingress-nginx-controller -n ingress-nginx

# You'll see output like:
# PORT(S): 80:XXXXX/TCP,443:YYYYY/TCP
# Where XXXXX and YYYYY are the NodePorts (e.g., 80:32080/TCP, 443:32443/TCP)
```

### Step 3: Configure Firewall

```bash
# Open HTTP and HTTPS ports (replace with actual NodePorts from above)
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --permanent --add-port=32080/tcp  # Example HTTP NodePort
sudo firewall-cmd --permanent --add-port=32443/tcp  # Example HTTPS NodePort
sudo firewall-cmd --reload

# Verify
sudo firewall-cmd --list-ports
```

### Step 4: Set Up DNS or Hosts File

**Option A: DNS (Production)**

Configure your DNS provider to point your domain to the AlmaLinux server IP:
```
A record: heart-disease-api.yourdomain.com -> <ALMALINUX_IP>
```

**Option B: Hosts File (Development/Testing)**

On each **client machine** that needs access:

**Linux/Mac:**
```bash
sudo nano /etc/hosts
# Add:
<ALMALINUX_SERVER_IP> heart-disease-api.local
```

**Windows:**
```
# Run Notepad as Administrator
# Edit: C:\Windows\System32\drivers\etc\hosts
# Add:
<ALMALINUX_SERVER_IP> heart-disease-api.local
```

### Step 5: Set Up Ingress Tunnel (For Minikube)

```bash
# Option A: Use minikube tunnel (requires root)
# This creates a network route from host to Minikube
sudo minikube tunnel

# Keep this running in a separate terminal or as a service
```

**Or configure as a systemd service:**

```bash
# Create systemd service file
sudo nano /etc/systemd/system/minikube-tunnel.service
```

Add this content:
```ini
[Unit]
Description=Minikube Tunnel
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/minikube tunnel
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable minikube-tunnel
sudo systemctl start minikube-tunnel
sudo systemctl status minikube-tunnel
```

### Step 6: Test Remote Access

```bash
# From remote system (after setting up hosts file):
curl http://heart-disease-api.local/health

# Or using IP directly with Host header:
curl -H "Host: heart-disease-api.local" http://<ALMALINUX_IP>/health
```

### Step 7: Configure for Multiple Hosts (Optional)

If you want to use actual domain or IP-based access, update your Helm values:

```bash
# Edit values file
nano ~/helm-charts/heart-disease-api/values.yaml

# Update ingress section to:
ingress:
  enabled: true
  className: "nginx"
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
  hosts:
    - host: heart-disease-api.local  # For local testing
      paths:
        - path: /
          pathType: Prefix
    - host: <YOUR_ALMALINUX_IP>.nip.io  # For IP-based access
      paths:
        - path: /
          pathType: Prefix
```

Redeploy:
```bash
helm upgrade heart-disease-api ./heart-disease-api -n mlops
```

---

## Option 3: MetalLB LoadBalancer (Advanced)

**Best for**: Bare-metal Kubernetes clusters, production environments

### Step 1: Install MetalLB

```bash
# Install MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml

# Wait for MetalLB to be ready
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=app=metallb \
  --timeout=90s
```

### Step 2: Configure IP Address Pool

Create a configuration file:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
  - <ALMALINUX_IP>/32  # Use your server's IP
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
spec:
  ipAddressPools:
  - default-pool
EOF
```

### Step 3: Update Service Type to LoadBalancer

```bash
# Update values.yaml
nano ~/helm-charts/heart-disease-api/values.yaml

# Change:
service:
  type: LoadBalancer  # Changed from NodePort
  port: 80
  targetPort: 8000
```

Redeploy:
```bash
helm upgrade heart-disease-api ./heart-disease-api -n mlops
```

### Step 4: Get External IP

```bash
kubectl get svc -n mlops heart-disease-api
# EXTERNAL-IP should show your AlmaLinux IP
```

### Step 5: Access from Remote

```bash
curl http://<ALMALINUX_IP>/health
```

---

## Troubleshooting

### Issue: Cannot Access from Remote

**Check 1: Firewall Status**
```bash
# Check if firewall is blocking
sudo firewall-cmd --list-all

# Temporarily disable to test (re-enable after!)
sudo systemctl stop firewalld
```

**Check 2: SELinux**
```bash
# Check SELinux status
sudo getenforce

# Temporarily set to permissive (for testing only)
sudo setenforce 0

# If this fixes it, configure SELinux properly instead of disabling
```

**Check 3: Service Status**
```bash
# Check if pods are running
kubectl get pods -n mlops

# Check service endpoints
kubectl get endpoints -n mlops

# Check ingress status
kubectl get ingress -n mlops
kubectl describe ingress -n mlops
```

**Check 4: Network Connectivity**
```bash
# From AlmaLinux server, test locally first
curl http://$(minikube ip):30080/health

# Check if port is listening on host
sudo ss -tlnp | grep -E '30080|80|443'

# Test from server itself
curl http://localhost:30080/health
```

**Check 5: Minikube Status**
```bash
# Check Minikube status
minikube status

# Check logs
minikube logs

# Restart if needed
minikube stop
minikube start
```

### Issue: DNS Not Resolving

```bash
# Test DNS resolution on client
nslookup heart-disease-api.local
ping heart-disease-api.local

# Test with IP directly
curl http://<ALMALINUX_IP>:30080/health

# Test with Host header
curl -H "Host: heart-disease-api.local" http://<ALMALINUX_IP>:30080/health
```

### Issue: Ingress Not Working

```bash
# Check ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# Verify ingress resource
kubectl describe ingress -n mlops heart-disease-api

# Check if ingress has address assigned
kubectl get ingress -n mlops
```

### Quick Debug Commands

```bash
# Complete service check
cat << 'EOF' > check_service.sh
#!/bin/bash
echo "=== Minikube Status ==="
minikube status

echo -e "\n=== Pods Status ==="
kubectl get pods -n mlops

echo -e "\n=== Service Details ==="
kubectl get svc -n mlops
kubectl describe svc -n mlops heart-disease-api

echo -e "\n=== Ingress Details ==="
kubectl get ingress -n mlops
kubectl describe ingress -n mlops

echo -e "\n=== Firewall Status ==="
sudo firewall-cmd --list-all

echo -e "\n=== Listening Ports ==="
sudo ss -tlnp | grep -E '30080|80|443'

echo -e "\n=== Test Local Access ==="
curl -s http://$(minikube ip):30080/health || echo "Local access failed"
EOF

chmod +x check_service.sh
./check_service.sh
```

---

## Security Considerations

### 1. Firewall Best Practices

```bash
# Only open required ports
sudo firewall-cmd --permanent --add-port=30080/tcp

# Or use services
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https

# Restrict to specific IPs (recommended)
sudo firewall-cmd --permanent --add-rich-rule='
  rule family="ipv4"
  source address="192.168.1.0/24"
  port protocol="tcp" port="30080" accept'

sudo firewall-cmd --reload
```

### 2. Enable TLS/HTTPS

Update your ingress configuration:

```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: heart-disease-api.yourdomain.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: heart-disease-api-tls
      hosts:
        - heart-disease-api.yourdomain.com
```

Install cert-manager for automatic TLS:
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

### 3. Authentication

Add basic auth to ingress:

```yaml
ingress:
  annotations:
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required'
```

Create auth secret:
```bash
htpasswd -c auth username
kubectl create secret generic basic-auth --from-file=auth -n mlops
```

### 4. Rate Limiting

```yaml
ingress:
  annotations:
    nginx.ingress.kubernetes.io/limit-rps: "10"
    nginx.ingress.kubernetes.io/limit-connections: "10"
```

---

## Recommended Configuration for Remote Access

### For Development/Testing:

1. Use **NodePort** (Option 1)
2. Configure firewall for port 30080
3. Access via `http://<ALMALINUX_IP>:30080`

### For Production:

1. Use **Ingress with NGINX** (Option 2)
2. Set up proper DNS
3. Enable TLS with cert-manager
4. Configure authentication
5. Enable rate limiting
6. Use proper monitoring and logging

### Quick Setup Script

```bash
# Save this as setup_remote_access.sh
cat << 'EOF' > setup_remote_access.sh
#!/bin/bash

echo "=== Setting up Remote Access ==="

# 1. Configure firewall
echo "Configuring firewall..."
sudo firewall-cmd --permanent --add-port=30080/tcp
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --reload

# 2. Enable ingress
echo "Enabling ingress addon..."
minikube addons enable ingress

# 3. Start minikube tunnel
echo "Starting minikube tunnel (requires sudo)..."
sudo nohup minikube tunnel > /tmp/minikube-tunnel.log 2>&1 &

# 4. Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "Server IP: $SERVER_IP"

# 5. Test local access
echo "Testing local access..."
sleep 5
MINIKUBE_IP=$(minikube ip)
curl -s http://$MINIKUBE_IP:30080/health && echo "✓ Local access working"

echo ""
echo "=== Setup Complete ==="
echo "Access your service from remote systems using:"
echo "  NodePort: http://$SERVER_IP:30080/health"
echo "  Ingress:  http://heart-disease-api.local (after setting up hosts file)"
echo ""
echo "Add this to remote system's /etc/hosts:"
echo "  $SERVER_IP heart-disease-api.local"
EOF

chmod +x setup_remote_access.sh
./setup_remote_access.sh
```

---

## Testing Remote Access

### From Remote System:

```bash
# Test NodePort access
curl http://<ALMALINUX_IP>:30080/health

# Test ingress (after hosts file setup)
curl http://heart-disease-api.local/health

# Test prediction endpoint
curl -X POST http://<ALMALINUX_IP>:30080/predict \
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

---

## Summary

**Quickest Method**: Use NodePort (already configured at port 30080)
- Open firewall: `sudo firewall-cmd --permanent --add-port=30080/tcp && sudo firewall-cmd --reload`
- Access: `http://<ALMALINUX_IP>:30080`

**Best Practice**: Use NGINX Ingress with proper domain
- Enable ingress: `minikube addons enable ingress`
- Start tunnel: `sudo minikube tunnel`
- Configure DNS or hosts file
- Access: `http://heart-disease-api.yourdomain.com`

For production deployments, always enable TLS, authentication, and monitoring.
