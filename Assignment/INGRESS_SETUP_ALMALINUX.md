# 🌐 Ingress Setup for AlmaLinux 8 with Minikube

## Simple Guide to Configure Ingress Access from Remote Systems

---

## Understanding Minikube Tunnel

`minikube tunnel` is a **subcommand** of minikube (not a separate binary). It runs as:
```bash
/usr/local/bin/minikube tunnel
```

However, for AlmaLinux with Minikube in Docker driver, there are better approaches that don't require tunnel.

---

## ✅ Recommended Solution: Direct NodePort + Ingress

This approach works reliably on AlmaLinux without needing `minikube tunnel`.

### Step 1: Enable NGINX Ingress Addon

```bash
# Enable ingress addon
minikube addons enable ingress

# Verify it's enabled
minikube addons list | grep ingress

# Wait for ingress controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

### Step 2: Check Ingress Controller NodePorts

```bash
# Get the ingress controller service
kubectl get svc -n ingress-nginx

# You'll see output like:
# NAME                                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)
# ingress-nginx-controller             NodePort    10.96.xxx.xxx   <none>        80:XXXXX/TCP,443:YYYYY/TCP
#                                                                                  ↑        ↑
#                                                                            HTTP Port  HTTPS Port
```

The ports in format `80:XXXXX` mean:
- **80** = Internal cluster port
- **XXXXX** = NodePort (external access port, usually 30000-32767 range)

### Step 3: Configure Firewall

```bash
# Get the actual NodePorts from step 2 (replace 32080 and 32443 with your actual ports)
HTTP_NODEPORT=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}')
HTTPS_NODEPORT=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.ports[?(@.port==443)].nodePort}')

echo "HTTP NodePort: $HTTP_NODEPORT"
echo "HTTPS NodePort: $HTTPS_NODEPORT"

# Open these ports in firewall
sudo firewall-cmd --permanent --add-port=${HTTP_NODEPORT}/tcp
sudo firewall-cmd --permanent --add-port=${HTTPS_NODEPORT}/tcp

# Also open standard ports (optional, for documentation)
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp

# Also keep your service NodePort open
sudo firewall-cmd --permanent --add-port=30080/tcp

# Apply changes
sudo firewall-cmd --reload

# Verify
sudo firewall-cmd --list-ports
```

### Step 4: Get Your AlmaLinux Server IP

```bash
# Get server IP address
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "Server IP: $SERVER_IP"

# Or manually check
ip addr show | grep "inet " | grep -v 127.0.0.1
```

### Step 5: Configure Port Forwarding (Alternative to Tunnel)

Instead of `minikube tunnel`, use `kubectl port-forward`:

```bash
# Forward ingress controller port to host
kubectl port-forward -n ingress-nginx \
  --address 0.0.0.0 \
  service/ingress-nginx-controller 8080:80 &

# This makes ingress accessible on port 8080 of your AlmaLinux server
```

Or forward your application service directly:
```bash
kubectl port-forward -n mlops \
  --address 0.0.0.0 \
  service/heart-disease-api 8080:80 &
```

### Step 6: Test Local Access First

```bash
# Get Minikube IP
MINIKUBE_IP=$(minikube ip)
echo "Minikube IP: $MINIKUBE_IP"

# Test NodePort access to your service
curl http://$MINIKUBE_IP:30080/health

# Test ingress (with Host header)
curl -H "Host: heart-disease-api.local" http://$MINIKUBE_IP/health

# Or test via ingress NodePort
HTTP_NODEPORT=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}')
curl -H "Host: heart-disease-api.local" http://$MINIKUBE_IP:$HTTP_NODEPORT/health
```

### Step 7: Configure Remote Access

**Option A: Using Ingress NodePort (Recommended)**

From remote system:
```bash
# Get the HTTP NodePort (from step 2)
# Replace 32080 with your actual NodePort
curl -H "Host: heart-disease-api.local" http://<ALMALINUX_IP>:32080/health
```

**Option B: Using Port Forward**

If you set up port-forward in Step 5:
```bash
# From remote system
curl -H "Host: heart-disease-api.local" http://<ALMALINUX_IP>:8080/health
```

**Option C: Direct Service NodePort (Simplest)**

```bash
# From remote system
curl http://<ALMALINUX_IP>:30080/health
```

### Step 8: Set Up Hosts File (For Domain Access)

On your **remote client machine**:

**Linux/Mac:**
```bash
sudo nano /etc/hosts

# Add:
<ALMALINUX_IP> heart-disease-api.local
```

**Windows:**
```
# Run as Administrator
notepad C:\Windows\System32\drivers\etc\hosts

# Add:
<ALMALINUX_IP> heart-disease-api.local
```

Now you can access:
```bash
# Using ingress NodePort
curl http://heart-disease-api.local:32080/health

# Or if using port-forward on port 8080
curl http://heart-disease-api.local:8080/health
```

---

## 🔧 Alternative: Make Port Forward Persistent

### Create systemd service for port forwarding

```bash
# Create service file
sudo nano /etc/systemd/system/k8s-ingress-forward.service
```

Add this content:
```ini
[Unit]
Description=Kubernetes Ingress Port Forward
After=network.target

[Service]
Type=simple
User=<YOUR_USERNAME>
WorkingDirectory=/home/<YOUR_USERNAME>
ExecStart=/usr/bin/kubectl port-forward -n ingress-nginx --address 0.0.0.0 service/ingress-nginx-controller 80:80 443:443
Restart=always
RestartSec=10
Environment="KUBECONFIG=/home/<YOUR_USERNAME>/.kube/config"

[Install]
WantedBy=multi-user.target
```

Replace `<YOUR_USERNAME>` with your actual username.

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable k8s-ingress-forward
sudo systemctl start k8s-ingress-forward
sudo systemctl status k8s-ingress-forward
```

Now ingress will be accessible on standard ports 80/443:
```bash
# From remote
curl -H "Host: heart-disease-api.local" http://<ALMALINUX_IP>/health
```

---

## 🚀 Complete Automated Setup Script

Save this as `setup_ingress.sh`:

```bash
#!/bin/bash

echo "=== Setting up Ingress for Remote Access ==="

# 1. Enable ingress addon
echo "Step 1: Enabling ingress addon..."
minikube addons enable ingress

# 2. Wait for ingress controller
echo "Step 2: Waiting for ingress controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# 3. Get NodePorts
echo "Step 3: Getting NodePorts..."
HTTP_NODEPORT=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}')
HTTPS_NODEPORT=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.ports[?(@.port==443)].nodePort}')

echo "HTTP NodePort: $HTTP_NODEPORT"
echo "HTTPS NodePort: $HTTPS_NODEPORT"

# 4. Configure firewall
echo "Step 4: Configuring firewall..."
sudo firewall-cmd --permanent --add-port=${HTTP_NODEPORT}/tcp
sudo firewall-cmd --permanent --add-port=${HTTPS_NODEPORT}/tcp
sudo firewall-cmd --permanent --add-port=30080/tcp
sudo firewall-cmd --reload

# 5. Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "Server IP: $SERVER_IP"

# 6. Get Minikube IP
MINIKUBE_IP=$(minikube ip)
echo "Minikube IP: $MINIKUBE_IP"

# 7. Test local access
echo "Step 5: Testing local access..."
sleep 5

echo "Testing service NodePort..."
curl -s http://$MINIKUBE_IP:30080/health && echo "✓ Service NodePort working"

echo "Testing ingress via NodePort..."
curl -s -H "Host: heart-disease-api.local" http://$MINIKUBE_IP:$HTTP_NODEPORT/health && echo "✓ Ingress working"

# 8. Display access information
echo ""
echo "=============================================="
echo "=== Setup Complete ==="
echo "=============================================="
echo ""
echo "Access your service from remote systems:"
echo ""
echo "1. Direct Service NodePort (Simplest):"
echo "   curl http://$SERVER_IP:30080/health"
echo ""
echo "2. Via Ingress NodePort:"
echo "   curl -H \"Host: heart-disease-api.local\" http://$SERVER_IP:$HTTP_NODEPORT/health"
echo ""
echo "3. Set up hosts file on remote client:"
echo "   Add this line to /etc/hosts (Linux/Mac) or C:\\Windows\\System32\\drivers\\etc\\hosts (Windows):"
echo "   $SERVER_IP heart-disease-api.local"
echo ""
echo "   Then access:"
echo "   curl http://heart-disease-api.local:$HTTP_NODEPORT/health"
echo ""
echo "4. For standard port 80 access, set up port forwarding:"
echo "   kubectl port-forward -n ingress-nginx --address 0.0.0.0 service/ingress-nginx-controller 80:80 &"
echo ""
echo "=============================================="
```

Make it executable and run:
```bash
chmod +x setup_ingress.sh
./setup_ingress.sh
```

---

## 🔍 Troubleshooting

### Issue 1: Cannot find kubectl

```bash
# Check if kubectl is available
which kubectl

# If not found, install it
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
```

### Issue 2: Ingress addon fails to enable

```bash
# Check Minikube status
minikube status

# If not running, start it
minikube start --driver=docker --cpus=2 --memory=4096

# Try enabling ingress again
minikube addons enable ingress

# Check logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

### Issue 3: Port forwarding disconnects

```bash
# Run port-forward with auto-restart
while true; do
  kubectl port-forward -n ingress-nginx --address 0.0.0.0 service/ingress-nginx-controller 8080:80
  echo "Port forward stopped, restarting in 5 seconds..."
  sleep 5
done
```

Or use the systemd service approach mentioned above.

### Issue 4: Remote access still not working

```bash
# Check if firewall is blocking
sudo firewall-cmd --list-all

# Temporarily disable to test (TESTING ONLY!)
sudo systemctl stop firewalld

# Try access from remote again
# If it works, the firewall was blocking - configure it properly and re-enable

sudo systemctl start firewalld
```

### Issue 5: SELinux blocking connections

```bash
# Check SELinux status
sudo getenforce

# If "Enforcing", temporarily set to permissive (TESTING ONLY!)
sudo setenforce 0

# Try access from remote again
# If it works, configure SELinux properly:

sudo semanage port -a -t http_port_t -p tcp 30080
sudo semanage port -a -t http_port_t -p tcp 32080  # Or your actual NodePort

# Re-enable enforcing
sudo setenforce 1
```

---

## 📊 Verification Commands

```bash
# Check all services
kubectl get svc --all-namespaces

# Check ingress resources
kubectl get ingress -n mlops
kubectl describe ingress -n mlops

# Check ingress controller
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller --tail=50

# Check endpoints
kubectl get endpoints -n mlops

# Test from within cluster
kubectl run -it --rm debug --image=alpine --restart=Never -- sh
# Inside the pod:
apk add curl
curl http://heart-disease-api.mlops.svc.cluster.local/health
```

---

## 🎯 Recommended Configuration for Your Setup

Based on AlmaLinux 8 with Minikube in Docker driver:

### Quick Access (Development):
```bash
# Use direct service NodePort - already configured
curl http://<ALMALINUX_IP>:30080/health
```

### Production Access:
```bash
# 1. Enable ingress
minikube addons enable ingress

# 2. Set up persistent port forwarding (systemd service)
# 3. Configure firewall
# 4. Set up proper DNS or hosts file
# 5. Access via domain name
curl http://heart-disease-api.local/health
```

---

## 📝 Summary

**You DON'T need a separate tunnel binary!** The command is:
```bash
/usr/local/bin/minikube tunnel
```

**However, for AlmaLinux + Docker driver, better options are:**

1. **Use Service NodePort directly** (port 30080) - Already working
2. **Use Ingress NodePort** - Enable ingress and use its NodePort
3. **Use kubectl port-forward** - Forward ports from cluster to host
4. **Use systemd service** - Make port-forward persistent

**Simplest working solution right now:**
```bash
# On AlmaLinux server:
sudo firewall-cmd --permanent --add-port=30080/tcp
sudo firewall-cmd --reload

# From remote:
curl http://<ALMALINUX_IP>:30080/health
```

This works immediately without any tunnel or ingress configuration!
