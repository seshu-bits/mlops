# 🚀 Alma Linux 8 Complete Deployment Package

**MLOps Heart Disease Prediction Application**  
**Server:** 72.163.219.91  
**Stack:** Docker + Minikube + Kubernetes + Prometheus + Grafana + MLflow + Ingress

---

## 📦 What's Included

This package provides everything needed for a complete from-scratch deployment on Alma Linux 8:

### ✅ Automated Scripts
1. **`deploy-complete-almalinux.sh`** - One-command full deployment (~10-15 min)
2. **`test-deployment.sh`** - Comprehensive deployment verification
3. **`cleanup-deployment.sh`** - Safe removal of all resources

### ✅ Documentation
1. **`QUICKSTART_ALMALINUX.md`** - Quick reference guide
2. **`ALMA_LINUX_COMPLETE_DEPLOYMENT.md`** - Detailed step-by-step manual
3. **`DEPLOYMENT_SUMMARY.md`** - Complete technical reference
4. **`DEPLOYMENT_CHECKLIST.md`** - Verification checklist
5. **This README** - Overview and quick links

### ✅ Kubernetes Manifests
- Helm chart for API deployment
- Prometheus configuration and deployment
- Grafana configuration and deployment
- MLflow deployment with persistent storage
- Ingress rules for all services
- Service definitions and configurations

---

## 🎯 Quick Start (3 Commands)

```bash
# 1. Clone repository
git clone https://github.com/seshu-bits/mlops.git
cd mlops/Assignment

# 2. Deploy everything
chmod +x deploy-complete-almalinux.sh
./deploy-complete-almalinux.sh

# 3. Verify deployment
chmod +x test-deployment.sh
./test-deployment.sh
```

**That's it!** All services will be accessible at http://72.163.219.91

---

## 🌐 Access After Deployment

| Service | URL | Purpose |
|---------|-----|---------|
| **API** | http://72.163.219.91/ | Heart disease predictions |
| **Swagger Docs** | http://72.163.219.91/docs | Interactive API documentation |
| **Prometheus** | http://72.163.219.91:9090 | Metrics and monitoring |
| **Grafana** | http://72.163.219.91:3000 | Visualization dashboards |
| **MLflow** | http://72.163.219.91:5000 | Experiment tracking |

**Default Credentials:**
- Grafana: `admin` / `admin` (change on first login)

---

## 📚 Documentation Guide

### For First-Time Deployment
1. **Start here:** [QUICKSTART_ALMALINUX.md](QUICKSTART_ALMALINUX.md)
2. **If issues arise:** [ALMA_LINUX_COMPLETE_DEPLOYMENT.md](ALMA_LINUX_COMPLETE_DEPLOYMENT.md) - Section 9 (Troubleshooting)
3. **Verify deployment:** [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)

### For Understanding the System
1. **Architecture & components:** [DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md)
2. **Management commands:** [DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md) - Section "Management Commands"
3. **Troubleshooting:** [DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md) - Section "Troubleshooting"

### For Manual Deployment
1. **Complete guide:** [ALMA_LINUX_COMPLETE_DEPLOYMENT.md](ALMA_LINUX_COMPLETE_DEPLOYMENT.md)
2. **Follow sections 1-8** for step-by-step instructions

### For Testing & Verification
1. **Automated tests:** Run `./test-deployment.sh`
2. **Manual verification:** [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)

---

## 🏗️ Architecture Overview

```
Internet
    ↓
┌─────────────────────────────────────────────┐
│    Alma Linux Server (72.163.219.91)        │
│  ┌──────────────────────────────────────┐   │
│  │  Nginx Reverse Proxy                 │   │
│  │  • Port 80  → API                    │   │
│  │  • Port 3000 → Grafana               │   │
│  │  • Port 5000 → MLflow                │   │
│  │  • Port 9090 → Prometheus            │   │
│  └──────────────┬───────────────────────┘   │
│                 ↓                            │
│  ┌──────────────────────────────────────┐   │
│  │  Minikube (Docker Driver)            │   │
│  │  ┌────────────────────────────────┐  │   │
│  │  │ Kubernetes Cluster             │  │   │
│  │  │  ┌──────────────────────────┐  │  │   │
│  │  │  │ Namespace: mlops         │  │  │   │
│  │  │  │                          │  │  │   │
│  │  │  │  • API (x2 replicas)     │  │  │   │
│  │  │  │  • Prometheus            │  │  │   │
│  │  │  │  • Grafana               │  │  │   │
│  │  │  │  • MLflow (PVC)          │  │  │   │
│  │  │  │  • Ingress Controller    │  │  │   │
│  │  │  └──────────────────────────┘  │  │   │
│  │  └────────────────────────────────┘  │   │
│  └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

---

## 💡 Key Features

### Application
- ✅ FastAPI-based REST API
- ✅ Machine learning inference (heart disease prediction)
- ✅ Load balanced (2 replicas)
- ✅ Health checks and auto-healing
- ✅ Interactive API documentation (Swagger UI)

### Monitoring
- ✅ Prometheus metrics collection
- ✅ Grafana visualization dashboards
- ✅ Real-time metrics and alerts
- ✅ Custom ML-specific metrics
- ✅ Request/response tracking

### Experiment Tracking
- ✅ MLflow server with persistent storage
- ✅ Experiment comparison
- ✅ Model versioning
- ✅ Artifact storage

### Networking
- ✅ Ingress-based routing
- ✅ Host-based and path-based routing
- ✅ External access via reverse proxy
- ✅ Load balancing across replicas

### Infrastructure
- ✅ Container orchestration with Kubernetes
- ✅ Local Kubernetes via Minikube
- ✅ Docker for containerization
- ✅ Helm for package management
- ✅ Automated deployment scripts

---

## 🔧 Prerequisites

### System Requirements
- Alma Linux 8 server
- Minimum 4 CPU cores
- Minimum 8GB RAM
- Minimum 40GB disk space
- Internet connectivity
- Root or sudo access

### Software (Auto-installed by script if missing)
- Docker CE
- kubectl
- Minikube
- Helm 3.x
- Git

---

## 📖 Usage Examples

### Health Check
```bash
curl http://72.163.219.91/health
```

### Single Prediction
```bash
curl -X POST http://72.163.219.91/predict \
  -H "Content-Type: application/json" \
  -d '{
    "age": 63, "sex": 1, "cp": 3, "trestbps": 145,
    "chol": 233, "fbs": 1, "restecg": 0, "thalach": 150,
    "exang": 0, "oldpeak": 2.3, "slope": 0, "ca": 0, "thal": 1
  }'
```

### Batch Prediction
```bash
curl -X POST http://72.163.219.91/predict/batch \
  -H "Content-Type: application/json" \
  -d '{
    "instances": [
      {"age": 63, "sex": 1, "cp": 3, "trestbps": 145, "chol": 233, ...}
    ]
  }'
```

### Get Metrics
```bash
curl http://72.163.219.91/metrics
```

---

## 🎮 Management Commands

### View Status
```bash
# All pods
kubectl get pods -n mlops

# All services
kubectl get svc -n mlops

# Ingress rules
kubectl get ingress -n mlops
```

### View Logs
```bash
# API logs
kubectl logs -n mlops -l app.kubernetes.io/name=heart-disease-api -f

# All service logs
kubectl logs -n mlops --all-containers=true -f
```

### Scale Application
```bash
# Scale to 3 replicas
kubectl scale deployment heart-disease-api --replicas=3 -n mlops
```

### Restart Services
```bash
# Restart API
kubectl rollout restart deployment heart-disease-api -n mlops

# Restart all
kubectl rollout restart deployment -n mlops
```

### Update Application
```bash
# Rebuild and deploy
eval $(minikube docker-env)
docker build -t heart-disease-api:latest -f Dockerfile.almalinux .
kubectl rollout restart deployment heart-disease-api -n mlops
```

---

## 🐛 Troubleshooting

### Services not accessible from remote?
```bash
# Check tunnel
ps aux | grep "minikube tunnel"
minikube tunnel  # If not running

# Check Nginx
sudo systemctl status nginx
sudo systemctl restart nginx

# Check firewall
sudo firewall-cmd --list-all
```

### Pods not starting?
```bash
# Check pod details
kubectl describe pod <pod-name> -n mlops

# Check logs
kubectl logs <pod-name> -n mlops

# Restart deployment
kubectl rollout restart deployment <name> -n mlops
```

### Complete troubleshooting guide:
See [DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md) - Section "Troubleshooting"

---

## 🧹 Cleanup

To remove all deployed resources:

```bash
chmod +x cleanup-deployment.sh
./cleanup-deployment.sh
```

Options:
- Remove Kubernetes resources ✅
- Remove Helm releases ✅
- Delete Minikube cluster (optional)
- Remove Docker images (optional)
- Clean Nginx config ✅

---

## 📋 Deployment Checklist

Follow the comprehensive checklist to ensure successful deployment:

[DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)

Phases:
1. ✅ Pre-Deployment (prerequisites)
2. ✅ Repository Setup
3. ✅ Deployment Execution
4. ✅ Testing & Verification
5. ✅ Monitoring Setup
6. ✅ Remote Access Verification
7. ⚠️ Production Readiness (optional)
8. ✅ Documentation
9. 📤 Handover

---

## 🎓 Learning Resources

### Kubernetes
- Official Docs: https://kubernetes.io/docs/
- Minikube: https://minikube.sigs.k8s.io/docs/

### Helm
- Official Docs: https://helm.sh/docs/

### Monitoring
- Prometheus: https://prometheus.io/docs/
- Grafana: https://grafana.com/docs/

### MLOps
- MLflow: https://mlflow.org/docs/
- FastAPI: https://fastapi.tiangolo.com/

---

## 📞 Support

### Documentation
- **Quick Start:** [QUICKSTART_ALMALINUX.md](QUICKSTART_ALMALINUX.md)
- **Complete Guide:** [ALMA_LINUX_COMPLETE_DEPLOYMENT.md](ALMA_LINUX_COMPLETE_DEPLOYMENT.md)
- **Technical Reference:** [DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md)
- **Checklist:** [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)

### Automated Help
- **Test Deployment:** `./test-deployment.sh`
- **View Logs:** `kubectl logs -n mlops <pod-name>`
- **Check Status:** `kubectl get all -n mlops`

### Repository
- **GitHub:** https://github.com/seshu-bits/mlops
- **Issues:** Open an issue on GitHub

---

## 🔐 Security Considerations

For production deployments, consider:

1. **TLS/SSL Certificates**
   - Use Let's Encrypt or commercial certificates
   - Configure ingress for HTTPS
   
2. **Authentication**
   - Add API key authentication
   - Secure Prometheus and Grafana
   - Add MLflow authentication
   
3. **Network Security**
   - Implement network policies
   - Use firewalls effectively
   - Consider VPN access
   
4. **RBAC**
   - Configure Kubernetes RBAC
   - Limit service account permissions
   
5. **Secrets Management**
   - Use Kubernetes secrets
   - Consider external secret management

---

## 🚦 Deployment Status

After running the deployment script, you should see:

```
🎉 Deployment Complete!

Access Information:
  API:        http://72.163.219.91/
  Prometheus: http://72.163.219.91:9090
  Grafana:    http://72.163.219.91:3000 (admin/admin)
  MLflow:     http://72.163.219.91:5000

✓ All services deployed and accessible!
```

---

## 📊 What Gets Deployed

| Component | Replicas | Resources | Storage |
|-----------|----------|-----------|---------|
| Heart Disease API | 2 | 250m CPU, 512Mi RAM | Ephemeral |
| Prometheus | 1 | 200m CPU, 512Mi RAM | Ephemeral |
| Grafana | 1 | 100m CPU, 256Mi RAM | Ephemeral |
| MLflow | 1 | 250m CPU, 512Mi RAM | 5Gi PVC |
| Ingress Controller | 1 | Auto | - |

**Total Resources Required:**
- **CPU:** ~2 cores (minimum)
- **RAM:** ~4GB (minimum)
- **Storage:** ~10GB (including images)

---

## ✅ Success Criteria

Your deployment is successful when:

- ✅ All pods are in `Running` state
- ✅ API health endpoint responds: http://72.163.219.91/health
- ✅ Predictions work: http://72.163.219.91/docs
- ✅ Prometheus accessible: http://72.163.219.91:9090
- ✅ Grafana accessible: http://72.163.219.91:3000
- ✅ MLflow accessible: http://72.163.219.91:5000
- ✅ Metrics being collected: http://72.163.219.91/metrics
- ✅ Test script passes: `./test-deployment.sh` returns 0 failures

---

## 🎉 You're All Set!

This package contains everything needed for a production-ready MLOps deployment on Alma Linux 8. 

**Start here:** Run `./deploy-complete-almalinux.sh`

**Questions?** Check the comprehensive documentation in the links above.

**Issues?** Run `./test-deployment.sh` to diagnose problems.

**Happy deploying! 🚀**

---

## 📅 Maintenance

### Regular Tasks
- Monitor resource usage: `kubectl top pods -n mlops`
- Check logs regularly: `kubectl logs -n mlops <pod-name>`
- Update application when needed
- Backup MLflow data periodically

### After Server Reboot
```bash
# Start Minikube
minikube start

# Start tunnel (in background)
nohup minikube tunnel > /tmp/minikube-tunnel.log 2>&1 &

# Verify services
kubectl get pods -n mlops
```

### Updates
```bash
# Pull latest code
cd ~/mlops
git pull origin main

# Rebuild and deploy
cd Assignment
./deploy-complete-almalinux.sh
```

---

**Last Updated:** January 7, 2026  
**Version:** 1.0.0  
**Server:** 72.163.219.91  
**Status:** ✅ Ready for Deployment
