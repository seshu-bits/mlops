# 🚀 Quick Start Guide - Alma Linux 8 Deployment

Complete deployment of MLOps application on Alma Linux 8 with Docker, Minikube, Prometheus, Grafana, and MLflow.

**Server IP:** 72.163.219.91

---

## 📦 One-Command Deployment

```bash
# Clone and deploy everything
git clone https://github.com/seshu-bits/mlops.git
cd mlops/Assignment
chmod +x deploy-complete-almalinux.sh
./deploy-complete-almalinux.sh
```

That's it! The script will:
1. ✅ Check prerequisites (Docker, kubectl, Minikube, Helm)
2. ✅ Start Minikube with Docker driver
3. ✅ Build the application image
4. ✅ Deploy Prometheus & Grafana
5. ✅ Deploy MLflow tracking server
6. ✅ Deploy Heart Disease API
7. ✅ Configure ingress networking
8. ✅ Setup Nginx reverse proxy for remote access
9. ✅ Configure firewall rules

---

## 🌐 Access URLs

After deployment completes (5-10 minutes):

| Service | Local Access | Remote Access | Credentials |
|---------|--------------|---------------|-------------|
| **API** | http://\<minikube-ip\>/health | http://72.163.219.91/ | - |
| **API Docs** | http://\<minikube-ip\>/docs | http://72.163.219.91/docs | - |
| **Prometheus** | http://\<minikube-ip\>/ | http://72.163.219.91:9090 | - |
| **Grafana** | http://\<minikube-ip\>/ | http://72.163.219.91:3000 | admin/admin |
| **MLflow** | http://\<minikube-ip\>/ | http://72.163.219.91:5000 | - |

---

## 🧪 Test Deployment

```bash
# Run comprehensive tests
chmod +x test-deployment.sh
./test-deployment.sh
```

This will test:
- ✅ All Kubernetes resources
- ✅ Service availability
- ✅ API endpoints (health, prediction, batch)
- ✅ Prometheus metrics
- ✅ Remote accessibility

---

## 🗑️ Cleanup

```bash
# Remove all resources
chmod +x cleanup-deployment.sh
./cleanup-deployment.sh
```

Options to cleanup:
- Kubernetes resources
- Helm releases
- Minikube cluster (optional)
- Docker images (optional)
- Nginx configuration

---

## 📋 Prerequisites

If you haven't installed prerequisites, run:

```bash
# Update system
sudo dnf update -y

# Install Docker
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/kubectl

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Logout and login to apply docker group
```

---

## 🔧 Manual Steps

If you prefer manual deployment, see:
- **[ALMA_LINUX_COMPLETE_DEPLOYMENT.md](ALMA_LINUX_COMPLETE_DEPLOYMENT.md)** - Detailed step-by-step guide

---

## 📊 Using the API

### Single Prediction

```bash
curl -X POST http://72.163.219.91/predict \
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

### Batch Prediction

```bash
curl -X POST http://72.163.219.91/predict/batch \
  -H "Content-Type: application/json" \
  -d @sample_batch_input.json
```

### Health Check

```bash
curl http://72.163.219.91/health
```

### Metrics

```bash
curl http://72.163.219.91/metrics
```

---

## 📈 Monitoring

### Grafana Dashboard

1. Access: http://72.163.219.91:3000
2. Login: admin/admin
3. Go to Dashboards → Import
4. Upload: `monitoring/grafana-dashboard.json`
5. Select Prometheus datasource

### Prometheus Queries

Access Prometheus at http://72.163.219.91:9090 and try:

```promql
# Request rate
rate(api_requests_total[5m])

# Average prediction latency
rate(prediction_duration_seconds_sum[5m]) / rate(prediction_duration_seconds_count[5m])

# Error rate
rate(api_errors_total[5m])

# Active requests
active_requests
```

---

## 🔍 Troubleshooting

### Check Status

```bash
# Check all pods
kubectl get pods -n mlops

# Check services
kubectl get svc -n mlops

# Check ingress
kubectl get ingress -n mlops

# Check logs
kubectl logs -n mlops -l app.kubernetes.io/name=heart-disease-api --tail=100
```

### Common Issues

**Problem:** Services not accessible remotely

```bash
# Check Minikube tunnel
ps aux | grep "minikube tunnel"

# Start tunnel if not running
minikube tunnel

# Check Nginx
sudo systemctl status nginx
sudo nginx -t
```

**Problem:** Pods not starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n mlops

# Check events
kubectl get events -n mlops --sort-by='.lastTimestamp'

# Rebuild and redeploy
eval $(minikube docker-env)
docker build -t heart-disease-api:latest -f Dockerfile.almalinux .
kubectl rollout restart deployment heart-disease-api -n mlops
```

**Problem:** Ingress not working

```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Restart ingress
minikube addons disable ingress
minikube addons enable ingress
```

---

## 📚 Additional Resources

- **[ALMA_LINUX_COMPLETE_DEPLOYMENT.md](ALMA_LINUX_COMPLETE_DEPLOYMENT.md)** - Complete manual deployment guide
- **[README.md](README.md)** - Project documentation
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System architecture
- **[monitoring/README.md](monitoring/README.md)** - Monitoring setup guide

---

## 🔄 Quick Commands

```bash
# View all resources
kubectl get all -n mlops

# Scale API replicas
kubectl scale deployment heart-disease-api --replicas=3 -n mlops

# Update API image
eval $(minikube docker-env)
docker build -t heart-disease-api:latest -f Dockerfile.almalinux .
kubectl rollout restart deployment heart-disease-api -n mlops

# View logs in real-time
kubectl logs -n mlops -l app.kubernetes.io/name=heart-disease-api -f

# Port forward for testing
kubectl port-forward -n mlops svc/heart-disease-api 8080:80

# Access Minikube dashboard
minikube dashboard

# Check tunnel status
tail -f /tmp/minikube-tunnel.log
```

---

## 🎯 Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Remote Users                             │
│              (http://72.163.219.91:*)                       │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  Nginx Reverse Proxy                        │
│         (Port 80, 3000, 5000, 9090)                         │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                 Minikube Ingress                            │
│              (nginx-ingress-controller)                     │
└────────────────────────┬────────────────────────────────────┘
                         │
          ┌──────────────┼──────────────┬───────────┐
          │              │              │           │
          ▼              ▼              ▼           ▼
    ┌─────────┐   ┌───────────┐  ┌─────────┐ ┌─────────┐
    │   API   │   │Prometheus │  │ Grafana │ │ MLflow  │
    │  (x2)   │   │           │  │         │ │         │
    └─────────┘   └───────────┘  └─────────┘ └─────────┘
          │              ▲
          └──────────────┘
           (scrapes metrics)
```

---

## 📞 Support

If you encounter issues:

1. Check the [Troubleshooting](#-troubleshooting) section
2. Review logs: `kubectl logs -n mlops <pod-name>`
3. Run test suite: `./test-deployment.sh`
4. Check system resources: `kubectl top nodes` and `kubectl top pods -n mlops`

---

**Deployment completed successfully! 🎉**

Access your MLOps application at http://72.163.219.91
