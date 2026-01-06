# 🌐 LoadBalancer with Ingress Setup Guide

Complete guide to configure LoadBalancer with Ingress for external access to your MLOps application on AlmaLinux with Minikube.

---

## 📋 Overview

**Current Setup**: NodePort (direct access via port 30080)  
**Target Setup**: Ingress with LoadBalancer (access via port 80/443)

### Architecture

```
Internet/Remote Client
       ↓
   [Port 80/443]
       ↓
  NGINX Ingress Controller (LoadBalancer)
       ↓
   Kubernetes Ingress
       ↓
   Heart Disease API Service (ClusterIP)
       ↓
   API Pods
```

---

## 🚀 Quick Setup (3 Steps)

### Step 1: Enable NGINX Ingress on Minikube

```bash
# Enable the ingress addon
minikube addons enable ingress

# Verify it's running
kubectl get pods -n ingress-nginx

# Wait for ingress controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

### Step 2: Update Helm Deployment

```bash
cd ~/workspace/mlops/Assignment/helm-charts

# Pull latest changes
git pull origin main

# Upgrade deployment with Ingress enabled
helm upgrade --install heart-disease-api ./heart-disease-api \
  --namespace mlops \
  --create-namespace \
  --set service.type=ClusterIP \
  --set ingress.enabled=true \
  --set image.pullPolicy=Never

# Verify ingress is created
kubectl get ingress -n mlops
```

### Step 3: Access via Ingress

```bash
# Get Ingress IP
INGRESS_IP=$(minikube ip)

# Test access (use port 80, not 30080!)
curl http://$INGRESS_IP/health

# Access from browser
echo "API: http://$INGRESS_IP"
echo "API Docs: http://$INGRESS_IP/docs"
echo "Metrics: http://$INGRESS_IP/metrics"
```

---

## 📖 Detailed Setup Guide

### Prerequisites

- Minikube running on AlmaLinux
- kubectl configured
- Helm 3.x installed
- Application deployed

### Step-by-Step Configuration

#### 1. Enable NGINX Ingress Controller

```bash
# Check if ingress addon is available
minikube addons list | grep ingress

# Enable ingress addon (installs NGINX Ingress Controller)
minikube addons enable ingress

# Verify installation
kubectl get ns ingress-nginx
kubectl get pods -n ingress-nginx

# You should see:
# - ingress-nginx-controller-xxx (Running)
# - ingress-nginx-admission-create-xxx (Completed)
# - ingress-nginx-admission-patch-xxx (Completed)
```

#### 2. Verify Ingress Controller Service

```bash
# Check ingress controller service
kubectl get svc -n ingress-nginx

# Output should show:
# NAME                                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)
# ingress-nginx-controller             NodePort    10.x.x.x        <none>        80:xxxxx/TCP,443:xxxxx/TCP
# ingress-nginx-controller-admission   ClusterIP   10.x.x.x        <none>        443/TCP
```

#### 3. Update Application Configuration

The values.yaml has been updated to:
- Use `ClusterIP` service type (for use with Ingress)
- Enable Ingress with NGINX controller
- Accept all hostnames (empty host field)

```yaml
service:
  type: ClusterIP  # Changed from NodePort
  port: 80
  targetPort: 8000

ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: ""  # Empty = accept all hostnames
      paths:
        - path: /
          pathType: Prefix
```

#### 4. Deploy/Update Application

```bash
# Navigate to helm charts
cd ~/workspace/mlops/Assignment/helm-charts

# Upgrade existing deployment
helm upgrade heart-disease-api ./heart-disease-api \
  --namespace mlops \
  --set image.pullPolicy=Never \
  --set image.tag=latest

# Or fresh install
helm install heart-disease-api ./heart-disease-api \
  --namespace mlops \
  --create-namespace \
  --set image.pullPolicy=Never

# Wait for rollout
kubectl rollout status deployment/heart-disease-api -n mlops
```

#### 5. Verify Ingress Resource

```bash
# Check ingress resource
kubectl get ingress -n mlops

# Describe for details
kubectl describe ingress heart-disease-api -n mlops

# You should see:
# - Host: <empty> or *
# - Address: <minikube-ip>
# - Rules matching path /
```

#### 6. Configure Firewall

Since Ingress uses port 80 (and 443 for HTTPS), open those ports:

```bash
# Get the NodePort that ingress controller uses
INGRESS_HTTP_PORT=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')
INGRESS_HTTPS_PORT=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')

echo "HTTP Port: $INGRESS_HTTP_PORT"
echo "HTTPS Port: $INGRESS_HTTPS_PORT"

# Open firewall for these ports
sudo firewall-cmd --permanent --add-port=${INGRESS_HTTP_PORT}/tcp
sudo firewall-cmd --permanent --add-port=${INGRESS_HTTPS_PORT}/tcp
sudo firewall-cmd --reload

# Or for standard ports if you set up port forwarding
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --reload
```

---

## 🌐 Accessing the Application

### Via Minikube IP

```bash
# Get Minikube IP
MINIKUBE_IP=$(minikube ip)

# Access application (port 80 via Ingress)
curl http://$MINIKUBE_IP/health
curl http://$MINIKUBE_IP/docs

# From browser
open http://$MINIKUBE_IP
```

### Via Server IP (Remote Access)

```bash
# On AlmaLinux server, get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

# From remote machine
curl http://$SERVER_IP:$INGRESS_HTTP_PORT/health

# Or set up port forwarding from 80 to ingress port
```

### Port Forwarding for Port 80 (Optional)

If you want to access via standard port 80:

```bash
# Get ingress NodePort
INGRESS_PORT=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')

# Set up iptables port forwarding (run as root)
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port $INGRESS_PORT

# Make persistent (AlmaLinux)
sudo service iptables save
```

---

## 🔧 Monitoring Services via Ingress

### Option 1: Separate Ingress for Each Service

Create ingress for Prometheus and Grafana:

```bash
# Create ingress for Prometheus
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: prometheus-ingress
  namespace: mlops
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /prometheus
        pathType: Prefix
        backend:
          service:
            name: prometheus
            port:
              number: 9090
EOF

# Create ingress for Grafana
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana-ingress
  namespace: mlops
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /grafana
        pathType: Prefix
        backend:
          service:
            name: grafana
            port:
              number: 3000
EOF
```

Access via:
- API: `http://<ip>/`
- Prometheus: `http://<ip>/prometheus`
- Grafana: `http://<ip>/grafana`

### Option 2: Use Subdomains

```yaml
# In values.yaml
ingress:
  hosts:
    - host: api.yourdomain.com
    - host: prometheus.yourdomain.com
    - host: grafana.yourdomain.com
```

### Option 3: Keep NodePort for Monitoring

Keep NodePort for Prometheus/Grafana, use Ingress only for API:
- API: `http://<ip>/` (via Ingress)
- Prometheus: `http://<ip>:30090` (via NodePort)
- Grafana: `http://<ip>:30030` (via NodePort)

---

## 🧪 Testing the Setup

### Test Script

```bash
#!/bin/bash
# Test Ingress setup

MINIKUBE_IP=$(minikube ip)
echo "Testing Ingress at: $MINIKUBE_IP"
echo ""

# Test API endpoints
echo "Testing API endpoints via Ingress:"
echo -n "  Health: "
curl -s http://$MINIKUBE_IP/health | grep -q "healthy" && echo "✅ OK" || echo "❌ FAIL"

echo -n "  Root: "
curl -s http://$MINIKUBE_IP/ | grep -q "Heart Disease" && echo "✅ OK" || echo "❌ FAIL"

echo -n "  Docs: "
curl -s http://$MINIKUBE_IP/docs | grep -q "swagger" && echo "✅ OK" || echo "❌ FAIL"

echo -n "  Metrics: "
curl -s http://$MINIKUBE_IP/metrics | grep -q "api_requests_total" && echo "✅ OK" || echo "❌ FAIL"

echo ""
echo "Ingress configuration:"
kubectl get ingress -n mlops
```

### Verify Ingress Logs

```bash
# Get ingress controller pod name
INGRESS_POD=$(kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller -o jsonpath='{.items[0].metadata.name}')

# View logs
kubectl logs -n ingress-nginx $INGRESS_POD --tail=50

# Follow logs in real-time
kubectl logs -n ingress-nginx $INGRESS_POD -f
```

---

## 🚨 Troubleshooting

### Issue 1: 404 Not Found

```bash
# Check if ingress is created
kubectl get ingress -n mlops

# Check ingress details
kubectl describe ingress heart-disease-api -n mlops

# Verify backend service
kubectl get svc heart-disease-api -n mlops

# Check ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

### Issue 2: Service Unavailable (503)

```bash
# Check if pods are running
kubectl get pods -n mlops

# Check service endpoints
kubectl get endpoints heart-disease-api -n mlops

# Should show pod IPs, if empty, pods aren't ready
```

### Issue 3: Connection Refused

```bash
# Check ingress controller is running
kubectl get pods -n ingress-nginx

# Verify service type is ClusterIP when using Ingress
kubectl get svc heart-disease-api -n mlops
# Should show: TYPE = ClusterIP (not NodePort)

# Check firewall
sudo firewall-cmd --list-ports
```

### Issue 4: Ingress Addon Won't Enable

```bash
# Check Minikube status
minikube status

# Check available addons
minikube addons list

# Try disabling and re-enabling
minikube addons disable ingress
minikube addons enable ingress

# Wait for pods to start
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

---

## 🔄 Switching Between NodePort and Ingress

### Switch to Ingress (LoadBalancer approach)

```bash
helm upgrade heart-disease-api ./heart-disease-api \
  --namespace mlops \
  --set service.type=ClusterIP \
  --set ingress.enabled=true

# Access via Minikube IP on port 80
curl http://$(minikube ip)/health
```

### Switch Back to NodePort

```bash
helm upgrade heart-disease-api ./heart-disease-api \
  --namespace mlops \
  --set service.type=NodePort \
  --set service.nodePort=30080 \
  --set ingress.enabled=false

# Access via NodePort
curl http://$(minikube ip):30080/health
```

---

## 📊 Comparison: NodePort vs Ingress

| Feature | NodePort | Ingress |
|---------|----------|---------|
| **Access** | `http://<ip>:30080` | `http://<ip>/` |
| **Port** | 30080 | 80 (standard HTTP) |
| **External IP** | Not needed | Not needed (Minikube IP) |
| **Production Ready** | Dev/Testing | ✅ Production |
| **SSL/TLS** | Manual setup | Built-in support |
| **Load Balancing** | Kubernetes only | NGINX + Kubernetes |
| **Path Routing** | No | ✅ Yes |
| **Multiple Services** | Need multiple ports | ✅ Single port, path-based |

---

## ✅ Verification Checklist

After setup, verify:

- [ ] Ingress addon enabled: `minikube addons list | grep ingress`
- [ ] Ingress controller running: `kubectl get pods -n ingress-nginx`
- [ ] Ingress resource created: `kubectl get ingress -n mlops`
- [ ] Service type is ClusterIP: `kubectl get svc heart-disease-api -n mlops`
- [ ] Application accessible via HTTP: `curl http://$(minikube ip)/health`
- [ ] Firewall configured for ingress ports
- [ ] Can access from remote machine

---

## 🎯 Next Steps

1. **Enable HTTPS** with cert-manager and Let's Encrypt
2. **Configure custom domain** instead of IP address
3. **Add authentication** to protect endpoints
4. **Set up monitoring** for ingress controller
5. **Configure rate limiting** for API protection

---

## 📚 Related Documentation

- [Kubernetes Ingress Documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [Minikube Ingress Addon](https://minikube.sigs.k8s.io/docs/handbook/addons/ingress/)

---

## Quick Command Reference

```bash
# Enable ingress
minikube addons enable ingress

# Deploy with ingress
helm upgrade --install heart-disease-api ./heart-disease-api -n mlops --set ingress.enabled=true --set service.type=ClusterIP

# Get ingress info
kubectl get ingress -n mlops
kubectl describe ingress heart-disease-api -n mlops

# Test access
curl http://$(minikube ip)/health

# View ingress logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller -f
```

Your application is now accessible via **Ingress on standard HTTP port 80**! 🚀
