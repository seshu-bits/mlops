# 🎯 Alma Linux 8 Deployment - Complete Summary

**Project:** Heart Disease Prediction MLOps  
**Server IP:** 72.163.219.91  
**Deployment Type:** Docker + Minikube + Kubernetes + Ingress  
**Date:** January 7, 2026

---

## 📦 What You Have Now

### 1. **Complete Deployment Script**
- **File:** `deploy-complete-almalinux.sh`
- **Purpose:** One-command deployment of entire stack
- **Duration:** ~10-15 minutes
- **What it does:**
  - ✅ Checks prerequisites
  - ✅ Starts Minikube with Docker driver
  - ✅ Builds application Docker image
  - ✅ Deploys Prometheus monitoring
  - ✅ Deploys Grafana dashboards
  - ✅ Deploys MLflow tracking server
  - ✅ Deploys Heart Disease API (2 replicas)
  - ✅ Configures Kubernetes ingress
  - ✅ Sets up Nginx reverse proxy
  - ✅ Configures firewall rules

### 2. **Test Script**
- **File:** `test-deployment.sh`
- **Purpose:** Comprehensive deployment verification
- **Tests:**
  - ✅ Kubernetes resources (pods, services, ingress)
  - ✅ API endpoints (health, predict, batch, metrics)
  - ✅ Prometheus metrics collection
  - ✅ Remote accessibility
  - ✅ Service connectivity

### 3. **Cleanup Script**
- **File:** `cleanup-deployment.sh`
- **Purpose:** Safe removal of all resources
- **Options:**
  - Remove Kubernetes resources
  - Remove Helm releases
  - Delete Minikube cluster (optional)
  - Remove Docker images (optional)
  - Clean Nginx configuration

### 4. **Documentation**
- **ALMA_LINUX_COMPLETE_DEPLOYMENT.md** - Detailed manual deployment guide
- **QUICKSTART_ALMALINUX.md** - Quick reference guide
- This summary document

---

## 🚀 Deployment Instructions

### Option 1: Automated Deployment (Recommended)

```bash
# Step 1: Connect to your Alma Linux server
ssh user@72.163.219.91

# Step 2: Clone repository
git clone https://github.com/seshu-bits/mlops.git
cd mlops/Assignment

# Step 3: Run deployment script
chmod +x deploy-complete-almalinux.sh
./deploy-complete-almalinux.sh
```

**Expected Output:**
```
╔════════════════════════════════════════════════════════════════╗
║       MLOps Complete Deployment - Alma Linux 8                ║
║   API + Prometheus + Grafana + MLflow + Ingress                ║
╚════════════════════════════════════════════════════════════════╝

✓ Docker found
✓ kubectl found
✓ Minikube found
✓ Helm found
✓ Git found

... (deployment progress) ...

🎉 Deployment Complete!

Access Information:
  API:        http://72.163.219.91/
  Prometheus: http://72.163.219.91:9090
  Grafana:    http://72.163.219.91:3000 (admin/admin)
  MLflow:     http://72.163.219.91:5000
```

### Option 2: Manual Deployment

Follow the step-by-step guide in `ALMA_LINUX_COMPLETE_DEPLOYMENT.md`

---

## 🧪 Verification

### Run Automated Tests

```bash
chmod +x test-deployment.sh
./test-deployment.sh
```

### Manual Verification

```bash
# Check all pods are running
kubectl get pods -n mlops

# Expected output:
# NAME                                   READY   STATUS    RESTARTS   AGE
# heart-disease-api-xxx                  1/1     Running   0          5m
# heart-disease-api-yyy                  1/1     Running   0          5m
# prometheus-xxx                         1/1     Running   0          7m
# grafana-xxx                            1/1     Running   0          7m
# mlflow-xxx                             1/1     Running   0          6m

# Test API from server
curl http://72.163.219.91/health

# Test API from remote machine
curl http://72.163.219.91/docs
```

---

## 🌐 Access Details

### From Remote Machines

| Service | URL | Purpose | Credentials |
|---------|-----|---------|-------------|
| **API** | http://72.163.219.91/ | Prediction endpoint | - |
| **Swagger UI** | http://72.163.219.91/docs | Interactive API docs | - |
| **Prometheus** | http://72.163.219.91:9090 | Metrics & monitoring | - |
| **Grafana** | http://72.163.219.91:3000 | Dashboards & visualization | admin/admin |
| **MLflow** | http://72.163.219.91:5000 | Experiment tracking | - |

### API Usage Examples

#### Health Check
```bash
curl http://72.163.219.91/health
```

#### Single Prediction
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

#### Batch Prediction
```bash
curl -X POST http://72.163.219.91/predict/batch \
  -H "Content-Type: application/json" \
  -d '{
    "instances": [
      {
        "age": 63, "sex": 1, "cp": 3, "trestbps": 145,
        "chol": 233, "fbs": 1, "restecg": 0, "thalach": 150,
        "exang": 0, "oldpeak": 2.3, "slope": 0, "ca": 0, "thal": 1
      }
    ]
  }'
```

#### Get Metrics
```bash
curl http://72.163.219.91/metrics
```

---

## 📊 Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                   Internet / Remote Users                    │
└────────────────────────────┬─────────────────────────────────┘
                             │
                             ▼
                  ┌──────────────────────┐
                  │   Alma Linux Server  │
                  │   72.163.219.91      │
                  └──────────┬───────────┘
                             │
                    ┌────────┴────────┐
                    │ Nginx Proxy     │
                    │ Ports:          │
                    │ - 80 (API)      │
                    │ - 3000 (Grafana)│
                    │ - 5000 (MLflow) │
                    │ - 9090 (Prom)   │
                    └────────┬────────┘
                             │
                    ┌────────┴────────┐
                    │ Minikube Tunnel │
                    └────────┬────────┘
                             │
                  ┌──────────┴──────────┐
                  │ Kubernetes Ingress  │
                  │ (nginx-controller)  │
                  └──────────┬──────────┘
                             │
        ┌────────────────────┼─────────────────────┐
        │                    │                     │
        ▼                    ▼                     ▼
┌──────────────┐    ┌──────────────┐      ┌──────────────┐
│ Heart Disease│    │ Prometheus   │      │   Grafana    │
│    API       │◄───┤ (Metrics)    │      │ (Dashboards) │
│  (2 replicas)│    └──────────────┘      └──────────────┘
└──────────────┘             │
        │                    ▼
        │            ┌──────────────┐
        └───────────►│   MLflow     │
                     │  (Tracking)  │
                     └──────────────┘

All components running in mlops namespace
Storage: Persistent volumes for MLflow
Network: Ingress-based routing with host headers
```

---

## 🔧 Components Breakdown

### 1. Application Container
- **Image:** `heart-disease-api:latest`
- **Base:** AlmaLinux 8 / Python 3.11
- **Framework:** FastAPI + Uvicorn
- **Replicas:** 2 (load balanced)
- **Resources:** 
  - Requests: 250m CPU, 512Mi RAM
  - Limits: 500m CPU, 1Gi RAM
- **Health Check:** `/health` endpoint every 30s

### 2. Prometheus
- **Version:** Latest stable
- **Purpose:** Metrics collection and storage
- **Scrape Interval:** 15s
- **Targets:** API `/metrics` endpoint
- **Port:** 9090
- **Storage:** Ephemeral (resets on restart)

### 3. Grafana
- **Version:** Latest stable
- **Purpose:** Metrics visualization
- **Datasource:** Prometheus (auto-configured)
- **Port:** 3000
- **Default Credentials:** admin/admin
- **Dashboards:** Pre-configured for ML metrics

### 4. MLflow
- **Version:** v2.9.2
- **Purpose:** Experiment tracking
- **Backend:** SQLite database
- **Artifacts:** File system storage
- **Port:** 5000
- **Storage:** 5Gi PersistentVolume

### 5. Ingress Controller
- **Type:** Nginx Ingress Controller
- **Purpose:** Route external traffic to services
- **Rules:** 
  - Host-based routing (api.mlops.local, etc.)
  - Path-based routing (/api, /prometheus, etc.)
  - Default routing to API
- **Annotations:** Timeouts, SSL options, body size limits

### 6. Minikube
- **Driver:** Docker
- **Resources:** 4 CPU, 8GB RAM, 40GB disk
- **Addons:** ingress, metrics-server, dashboard
- **Network:** Bridge mode with tunnel

### 7. Reverse Proxy (Nginx)
- **Purpose:** Expose services to external network
- **Configuration:** `/etc/nginx/conf.d/mlops-proxy.conf`
- **Mapping:**
  - Port 80 → API (Host: api.mlops.local)
  - Port 9090 → Prometheus
  - Port 3000 → Grafana
  - Port 5000 → MLflow

---

## 🔍 Management Commands

### View Resources
```bash
# All resources in mlops namespace
kubectl get all -n mlops

# Detailed pod information
kubectl get pods -n mlops -o wide

# Service endpoints
kubectl get svc -n mlops

# Ingress rules
kubectl get ingress -n mlops
kubectl describe ingress mlops-ingress -n mlops
```

### Check Logs
```bash
# API logs
kubectl logs -n mlops -l app.kubernetes.io/name=heart-disease-api --tail=100

# Follow logs in real-time
kubectl logs -n mlops -l app.kubernetes.io/name=heart-disease-api -f

# Prometheus logs
kubectl logs -n mlops -l app=prometheus --tail=50

# Grafana logs
kubectl logs -n mlops -l app=grafana --tail=50

# MLflow logs
kubectl logs -n mlops -l app=mlflow --tail=50
```

### Scale Application
```bash
# Scale API to 3 replicas
kubectl scale deployment heart-disease-api --replicas=3 -n mlops

# Verify scaling
kubectl get pods -n mlops -l app.kubernetes.io/name=heart-disease-api
```

### Update Application
```bash
# Rebuild image
eval $(minikube docker-env)
cd ~/mlops/Assignment
docker build -t heart-disease-api:latest -f Dockerfile.almalinux .

# Restart deployment
kubectl rollout restart deployment heart-disease-api -n mlops

# Check rollout status
kubectl rollout status deployment heart-disease-api -n mlops
```

### Restart Services
```bash
# Restart all services
kubectl rollout restart deployment -n mlops

# Restart specific service
kubectl rollout restart deployment prometheus -n mlops
kubectl rollout restart deployment grafana -n mlops
kubectl rollout restart deployment mlflow -n mlops
```

---

## 🐛 Troubleshooting

### Issue 1: Services not accessible from remote

**Symptoms:** Can access from server but not from remote machines

**Solutions:**
```bash
# Check Minikube tunnel
ps aux | grep "minikube tunnel"
# If not running:
minikube tunnel

# Check Nginx
sudo systemctl status nginx
sudo nginx -t
sudo systemctl restart nginx

# Check firewall
sudo firewall-cmd --list-all
# Open required ports:
sudo firewall-cmd --permanent --add-port={80,3000,5000,9090}/tcp
sudo firewall-cmd --reload
```

### Issue 2: Pods not starting

**Symptoms:** Pods stuck in Pending or CrashLoopBackOff

**Solutions:**
```bash
# Check pod details
kubectl describe pod <pod-name> -n mlops

# Check events
kubectl get events -n mlops --sort-by='.lastTimestamp'

# Check logs
kubectl logs <pod-name> -n mlops

# Restart deployment
kubectl rollout restart deployment <deployment-name> -n mlops
```

### Issue 3: Image pull errors

**Symptoms:** ErrImagePull or ImagePullBackOff

**Solutions:**
```bash
# Ensure using Minikube's Docker
eval $(minikube docker-env)

# Rebuild image
docker build -t heart-disease-api:latest -f Dockerfile.almalinux .

# Verify image exists
docker images | grep heart-disease-api

# Check image pull policy in deployment
kubectl get deployment heart-disease-api -n mlops -o yaml | grep -A2 image
```

### Issue 4: Ingress not routing correctly

**Symptoms:** 404 errors or service not found

**Solutions:**
```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress rules
kubectl describe ingress mlops-ingress -n mlops

# Test with curl and host header
MINIKUBE_IP=$(minikube ip)
curl -H "Host: api.mlops.local" http://$MINIKUBE_IP/health

# Restart ingress addon
minikube addons disable ingress
minikube addons enable ingress
```

### Issue 5: Out of resources

**Symptoms:** Pods evicted or not scheduling

**Solutions:**
```bash
# Check resource usage
kubectl top nodes
kubectl top pods -n mlops

# Increase Minikube resources
minikube stop
minikube start --cpus=6 --memory=12288

# Reduce replica count
kubectl scale deployment heart-disease-api --replicas=1 -n mlops
```

---

## 🧹 Maintenance

### Backup Important Data

```bash
# Backup MLflow data
kubectl cp mlops/mlflow-xxx:/mlflow /path/to/backup/mlflow-backup

# Backup Prometheus data (if needed)
kubectl get configmap prometheus-config -n mlops -o yaml > prometheus-config-backup.yaml
```

### Update Application

```bash
# Pull latest code
cd ~/mlops
git pull origin main

# Rebuild and deploy
cd Assignment
eval $(minikube docker-env)
docker build -t heart-disease-api:latest -f Dockerfile.almalinux .
kubectl rollout restart deployment heart-disease-api -n mlops
```

### Monitor System Health

```bash
# Check cluster health
kubectl cluster-info
kubectl get componentstatuses

# Check node status
kubectl describe node minikube

# Check storage
kubectl get pv
kubectl get pvc -n mlops
```

---

## 📝 Important Notes

1. **Minikube Tunnel:** Must run continuously for external access. If server reboots, restart with `minikube tunnel`

2. **Docker Daemon:** Always use Minikube's Docker daemon when building images: `eval $(minikube docker-env)`

3. **Firewall:** Ensure ports 80, 3000, 5000, 9090 are open in firewall

4. **SELinux:** If issues occur, check SELinux status: `getenforce`. May need to set to Permissive mode.

5. **Resources:** Minikube requires at least 4 CPUs and 8GB RAM. Adjust based on your server capacity.

6. **Persistence:** MLflow data is persisted using PVC. Other services use ephemeral storage.

7. **Security:** For production, add:
   - TLS/SSL certificates
   - Authentication for Prometheus/MLflow
   - Network policies
   - RBAC configurations

8. **Monitoring:** Regularly check logs and metrics to ensure healthy operation

---

## 📚 File Reference

```
Assignment/
├── deploy-complete-almalinux.sh       # Main deployment script
├── test-deployment.sh                 # Testing script
├── cleanup-deployment.sh              # Cleanup script
├── ALMA_LINUX_COMPLETE_DEPLOYMENT.md  # Detailed manual guide
├── QUICKSTART_ALMALINUX.md           # Quick reference
├── DEPLOYMENT_SUMMARY.md              # This file
├── api_server.py                      # FastAPI application
├── MLOps_Assignment.py                # ML training code
├── Dockerfile.almalinux               # Alma Linux Dockerfile
├── requirements.txt                   # Python dependencies
├── helm-charts/
│   └── heart-disease-api/            # Helm chart
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
├── monitoring/
│   ├── prometheus-config.yaml
│   ├── prometheus-deployment.yaml
│   ├── grafana-deployment.yaml
│   └── grafana-dashboard.json
└── artifacts/
    ├── model.pkl                      # Trained model
    ├── scaler.pkl                     # Data scaler
    └── feature_names.pkl              # Feature info
```

---

## ✅ Success Criteria

Your deployment is successful if:

- [ ] All pods are in Running state
- [ ] All services have endpoints
- [ ] Ingress rules are configured
- [ ] API health endpoint responds: `curl http://72.163.219.91/health`
- [ ] Prediction endpoint works: `curl -X POST http://72.163.219.91/predict ...`
- [ ] Prometheus UI accessible: http://72.163.219.91:9090
- [ ] Grafana UI accessible: http://72.163.219.91:3000
- [ ] MLflow UI accessible: http://72.163.219.91:5000
- [ ] Metrics being collected: `curl http://72.163.219.91/metrics`
- [ ] Test script passes: `./test-deployment.sh` returns 0 failures

---

## 🎯 Next Steps

After successful deployment:

1. **Import Grafana Dashboard**
   - Access http://72.163.219.91:3000
   - Go to Dashboards → Import
   - Upload `monitoring/grafana-dashboard.json`

2. **Generate Traffic for Metrics**
   - Run sample predictions
   - View metrics in Prometheus
   - View dashboards in Grafana

3. **Configure Alerts** (Optional)
   - Setup Prometheus alert rules
   - Configure Grafana alerts
   - Setup notification channels

4. **SSL/TLS** (Production)
   - Obtain SSL certificates
   - Configure ingress for HTTPS
   - Update Nginx configuration

5. **Authentication** (Production)
   - Add API key authentication
   - Secure Prometheus/Grafana
   - Configure MLflow authentication

6. **CI/CD Integration**
   - Setup GitHub Actions
   - Automate deployments
   - Add testing pipelines

---

## 📞 Support

For issues or questions:
1. Check troubleshooting section above
2. Review logs: `kubectl logs -n mlops <pod-name>`
3. Run diagnostics: `./test-deployment.sh`
4. Check official docs:
   - Kubernetes: https://kubernetes.io/docs/
   - Minikube: https://minikube.sigs.k8s.io/docs/
   - Helm: https://helm.sh/docs/

---

**Deployment Package Complete! 🚀**

You have everything needed to deploy and manage the MLOps application on Alma Linux 8 with full monitoring and tracking capabilities accessible from remote servers via ingress-based networking.

**Key Command:**
```bash
./deploy-complete-almalinux.sh
```

**Access:**
- http://72.163.219.91/ (API)
- http://72.163.219.91:9090 (Prometheus)
- http://72.163.219.91:3000 (Grafana)
- http://72.163.219.91:5000 (MLflow)
