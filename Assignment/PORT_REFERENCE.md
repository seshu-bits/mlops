# 🔌 Port Configuration Reference

## Fixed Port Assignments

All services in this MLOps application use **fixed NodePort assignments** to ensure consistent access across deployments, restarts, and updates.

---

## 📊 Port Mapping Table

| Service | Internal Port | NodePort | Access URL | Purpose |
|---------|---------------|----------|------------|---------|
| **Heart Disease API** | 8000 | **30080** | `http://<node-ip>:30080` | ML prediction API |
| **Prometheus** | 9090 | **30090** | `http://<node-ip>:30090` | Metrics collection & monitoring |
| **Grafana** | 3000 | **30030** | `http://<node-ip>:30030` | Metrics visualization dashboard |

---

## 🎯 Why Fixed Ports?

### Benefits:
✅ **Consistency**: Same ports across all deployments  
✅ **Predictability**: No need to look up ports after each deployment  
✅ **Documentation**: Easy to document and share access URLs  
✅ **Automation**: Scripts and CI/CD can use fixed URLs  
✅ **Firewall Rules**: Configure once, works forever  
✅ **Integration Tests**: Tests can use fixed URLs  

### Without Fixed Ports:
❌ Kubernetes randomly assigns ports in range 30000-32767  
❌ Ports change after each deployment  
❌ Need to run `kubectl get svc` to find current ports  
❌ Firewall rules need constant updates  
❌ Documentation becomes outdated  

---

## 🔧 Configuration Files

### API Service (Helm)
**Location**: `helm-charts/heart-disease-api/values.yaml`
```yaml
service:
  type: NodePort
  port: 80
  targetPort: 8000
  nodePort: 30080  # FIXED PORT
```

**Dev Environment**: `values-dev.yaml`
```yaml
service:
  type: NodePort
  nodePort: 30080  # Same port for dev
```

### Prometheus Service
**Location**: `monitoring/prometheus-deployment.yaml`
```yaml
spec:
  type: NodePort
  ports:
    - port: 9090
      targetPort: 9090
      nodePort: 30090  # FIXED PORT
```

### Grafana Service
**Location**: `monitoring/grafana-deployment.yaml`
```yaml
spec:
  type: NodePort
  ports:
    - port: 3000
      targetPort: 3000
      nodePort: 30030  # FIXED PORT
```

---

## 🌐 Accessing Services

### From Local Machine (Minikube)

```bash
# Get Minikube IP
MINIKUBE_IP=$(minikube ip)

# Access services
echo "API:        http://$MINIKUBE_IP:30080"
echo "Prometheus: http://$MINIKUBE_IP:30090"
echo "Grafana:    http://$MINIKUBE_IP:30030"
```

### From Remote Machine

```bash
# Use AlmaLinux server IP
SERVER_IP=<your-server-ip>

# Access services
curl http://$SERVER_IP:30080/health
open http://$SERVER_IP:30090
open http://$SERVER_IP:30030
```

### From Browser

- **API Docs**: http://\<node-ip\>:30080/docs
- **API Health**: http://\<node-ip\>:30080/health
- **Prometheus**: http://\<node-ip\>:30090
- **Grafana**: http://\<node-ip\>:30030 (admin/admin)

---

## 🔒 Firewall Configuration

Since ports are fixed, configure firewall once:

### AlmaLinux/RHEL/CentOS
```bash
# Open fixed ports permanently
sudo firewall-cmd --permanent --add-port=30080/tcp  # API
sudo firewall-cmd --permanent --add-port=30090/tcp  # Prometheus
sudo firewall-cmd --permanent --add-port=30030/tcp  # Grafana
sudo firewall-cmd --reload

# Verify
sudo firewall-cmd --list-ports
```

### Ubuntu/Debian
```bash
# Using ufw
sudo ufw allow 30080/tcp  # API
sudo ufw allow 30090/tcp  # Prometheus
sudo ufw allow 30030/tcp  # Grafana
sudo ufw reload
```

---

## 🧪 Testing Fixed Ports

### Verify Ports After Deployment

```bash
# Check API service
kubectl get svc heart-disease-api -n mlops -o jsonpath='{.spec.ports[0].nodePort}'
# Should always return: 30080

# Check Prometheus service
kubectl get svc prometheus -n mlops -o jsonpath='{.spec.ports[0].nodePort}'
# Should always return: 30090

# Check Grafana service
kubectl get svc grafana -n mlops -o jsonpath='{.spec.ports[0].nodePort}'
# Should always return: 30030
```

### Quick Test Script

```bash
#!/bin/bash
# Test all services on fixed ports

MINIKUBE_IP=$(minikube ip)

echo "Testing fixed ports..."
echo ""

# Test API
echo -n "API (30080): "
curl -s http://$MINIKUBE_IP:30080/health > /dev/null && echo "✅ OK" || echo "❌ FAIL"

# Test Prometheus
echo -n "Prometheus (30090): "
curl -s http://$MINIKUBE_IP:30090/-/healthy > /dev/null && echo "✅ OK" || echo "❌ FAIL"

# Test Grafana
echo -n "Grafana (30030): "
curl -s http://$MINIKUBE_IP:30030/api/health > /dev/null && echo "✅ OK" || echo "❌ FAIL"
```

---

## 📝 Port Allocation Strategy

### Why These Specific Ports?

| Port | Service | Reason |
|------|---------|--------|
| 30080 | API | Easy to remember (80 → 30080), main service |
| 30090 | Prometheus | Matches internal port 9090 pattern |
| 30030 | Grafana | Matches internal port 3000 pattern |

### Port Ranges

- **NodePort Range**: 30000-32767 (Kubernetes default)
- **Our Allocation**: 30030, 30080, 30090
- **Spacing**: Intentional gaps to avoid conflicts

---

## 🔄 Updating Deployments

Ports remain fixed even when updating deployments:

```bash
# Update API
helm upgrade heart-disease-api ./helm-charts/heart-disease-api -n mlops
# Port 30080 remains unchanged

# Restart Prometheus
kubectl rollout restart deployment/prometheus -n mlops
# Port 30090 remains unchanged

# Restart Grafana
kubectl rollout restart deployment/grafana -n mlops
# Port 30030 remains unchanged
```

---

## 🚨 Troubleshooting

### Port Already in Use

If you get "port already allocated" error:

```bash
# Check what's using the port
kubectl get svc --all-namespaces | grep 30080

# Delete conflicting service
kubectl delete svc <service-name> -n <namespace>

# Redeploy with fixed port
helm upgrade --install heart-disease-api ./helm-charts/heart-disease-api -n mlops
```

### Port Not Accessible

```bash
# 1. Check service has correct NodePort
kubectl get svc -n mlops

# 2. Check firewall
sudo firewall-cmd --list-ports

# 3. Check pods are running
kubectl get pods -n mlops

# 4. Check Minikube IP
minikube ip

# 5. Test from inside cluster
kubectl exec -it <pod-name> -n mlops -- curl http://localhost:8000/health
```

---

## 📚 Related Documentation

- [ALMALINUX_DEPLOYMENT.md](./ALMALINUX_DEPLOYMENT.md) - Full deployment guide
- [INGRESS_REMOTE_ACCESS.md](./INGRESS_REMOTE_ACCESS.md) - Remote access configuration
- [monitoring/README.md](./monitoring/README.md) - Monitoring setup

---

## ✅ Verification Checklist

After deployment, verify fixed ports:

- [ ] API accessible on port 30080
- [ ] Prometheus accessible on port 30090
- [ ] Grafana accessible on port 30030
- [ ] Firewall rules configured for all three ports
- [ ] Services show correct NodePort in `kubectl get svc`
- [ ] Ports remain same after pod restarts
- [ ] Integration tests pass using fixed URLs

---

## 🎯 Quick Reference

**Remember these three ports:**
```
30080 - API
30090 - Prometheus  
30030 - Grafana
```

All services will **always** be accessible on these ports! 🚀
