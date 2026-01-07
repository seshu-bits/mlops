# 📋 Alma Linux 8 Deployment Checklist

**Server IP:** 72.163.219.91  
**Date:** January 7, 2026  
**Deployment Method:** Automated Script

---

## Phase 1: Pre-Deployment ✅

### System Requirements
- [ ] Alma Linux 8 server with root/sudo access
- [ ] Minimum 4 CPU cores
- [ ] Minimum 8GB RAM
- [ ] Minimum 40GB free disk space
- [ ] Internet connectivity
- [ ] Server IP: 72.163.219.91 accessible

### Prerequisites Installation
- [ ] Docker CE installed and running
  ```bash
  docker --version
  docker run hello-world
  ```
- [ ] kubectl installed
  ```bash
  kubectl version --client
  ```
- [ ] Minikube installed
  ```bash
  minikube version
  ```
- [ ] Helm 3.x installed
  ```bash
  helm version
  ```
- [ ] Git installed
  ```bash
  git --version
  ```
- [ ] User added to docker group
  ```bash
  groups $USER | grep docker
  ```

### Network Configuration
- [ ] Firewall allows port 80 (HTTP)
- [ ] Firewall allows port 443 (HTTPS)
- [ ] Firewall allows port 3000 (Grafana)
- [ ] Firewall allows port 5000 (MLflow)
- [ ] Firewall allows port 9090 (Prometheus)
- [ ] SELinux configured (Permissive or disabled if needed)

---

## Phase 2: Repository Setup ✅

- [ ] Repository cloned successfully
  ```bash
  git clone https://github.com/seshu-bits/mlops.git
  ```
- [ ] Changed to Assignment directory
  ```bash
  cd mlops/Assignment
  ```
- [ ] Scripts are executable
  ```bash
  chmod +x deploy-complete-almalinux.sh test-deployment.sh cleanup-deployment.sh
  ls -l *.sh
  ```

---

## Phase 3: Deployment ✅

### Run Deployment Script
- [ ] Started deployment script
  ```bash
  ./deploy-complete-almalinux.sh
  ```
- [ ] No errors during prerequisite checks
- [ ] Minikube started successfully
- [ ] Minikube addons enabled (ingress, metrics-server, dashboard)
- [ ] Namespace 'mlops' created
- [ ] Docker image built successfully
- [ ] Prometheus deployed
- [ ] Grafana deployed
- [ ] MLflow deployed
- [ ] Heart Disease API deployed (2 replicas)
- [ ] Ingress configured
- [ ] Minikube tunnel started
- [ ] Nginx proxy configured
- [ ] Firewall rules applied

### Verify Kubernetes Resources
- [ ] All pods running
  ```bash
  kubectl get pods -n mlops
  ```
  Expected: 5+ pods in Running state
  
- [ ] All services created
  ```bash
  kubectl get svc -n mlops
  ```
  Expected: heart-disease-api, prometheus, grafana, mlflow
  
- [ ] Ingress configured
  ```bash
  kubectl get ingress -n mlops
  ```
  Expected: mlops-ingress, mlops-ingress-ip
  
- [ ] Persistent volumes bound
  ```bash
  kubectl get pvc -n mlops
  ```
  Expected: mlflow-pvc (Bound)

---

## Phase 4: Testing ✅

### Run Test Suite
- [ ] Test script executed successfully
  ```bash
  ./test-deployment.sh
  ```
- [ ] All Kubernetes resource tests passed
- [ ] All service availability tests passed
- [ ] All API endpoint tests passed
- [ ] Metrics collection working
- [ ] No test failures reported

### Manual API Testing
- [ ] Health endpoint responds
  ```bash
  curl http://72.163.219.91/health
  ```
  Expected: `{"status":"healthy"...}`
  
- [ ] API docs accessible
  ```bash
  curl http://72.163.219.91/docs
  ```
  Expected: HTML page
  
- [ ] Single prediction works
  ```bash
  curl -X POST http://72.163.219.91/predict -H "Content-Type: application/json" -d '{...}'
  ```
  Expected: JSON with prediction
  
- [ ] Batch prediction works
  ```bash
  curl -X POST http://72.163.219.91/predict/batch -H "Content-Type: application/json" -d '{...}'
  ```
  Expected: JSON with predictions array
  
- [ ] Metrics endpoint responds
  ```bash
  curl http://72.163.219.91/metrics
  ```
  Expected: Prometheus metrics

### Web Interface Testing
- [ ] Prometheus UI accessible
  - URL: http://72.163.219.91:9090
  - Targets show as UP
  - Can query metrics
  
- [ ] Grafana UI accessible
  - URL: http://72.163.219.91:3000
  - Login works (admin/admin)
  - Prometheus datasource configured
  
- [ ] MLflow UI accessible
  - URL: http://72.163.219.91:5000
  - Experiments visible
  - Can navigate interface
  
- [ ] API Swagger UI accessible
  - URL: http://72.163.219.91/docs
  - Can test endpoints interactively
  - All endpoints documented

---

## Phase 5: Monitoring Setup ✅

### Grafana Dashboard
- [ ] Logged into Grafana (admin/admin)
- [ ] Changed default password (recommended)
- [ ] Prometheus datasource verified
- [ ] Dashboard imported from `monitoring/grafana-dashboard.json`
- [ ] Dashboards showing data
- [ ] Panels updating with new data

### Prometheus Metrics
- [ ] Prometheus targets showing as UP
  - URL: http://72.163.219.91:9090/targets
  
- [ ] Can query metrics:
  - [ ] `api_requests_total`
  - [ ] `predictions_total`
  - [ ] `prediction_duration_seconds`
  - [ ] `active_requests`
  - [ ] `model_loaded`

### Generate Test Traffic
- [ ] Made several API calls
- [ ] Metrics updated in Prometheus
- [ ] Dashboards showing activity in Grafana
- [ ] Request counts increasing
- [ ] Latency metrics recorded

---

## Phase 6: Remote Access Verification ✅

### From Remote Machine
- [ ] Can access API: `curl http://72.163.219.91/health`
- [ ] Can access Prometheus: Browse to http://72.163.219.91:9090
- [ ] Can access Grafana: Browse to http://72.163.219.91:3000
- [ ] Can access MLflow: Browse to http://72.163.219.91:5000
- [ ] Can make predictions via API
- [ ] Can view Swagger docs

### From Different Networks
- [ ] Tested from public internet (if applicable)
- [ ] Tested from VPN connection (if applicable)
- [ ] Tested from mobile device (if applicable)

---

## Phase 7: Production Readiness (Optional) ⚠️

### Security
- [ ] Changed default Grafana password
- [ ] Consider adding API authentication
- [ ] Consider adding TLS/SSL certificates
- [ ] Review firewall rules
- [ ] Review network policies
- [ ] Review RBAC permissions

### Performance
- [ ] Adjust replica counts based on load
  ```bash
  kubectl scale deployment heart-disease-api --replicas=3 -n mlops
  ```
- [ ] Monitor resource usage
  ```bash
  kubectl top nodes
  kubectl top pods -n mlops
  ```
- [ ] Consider resource limits/requests adjustments
- [ ] Test under expected load

### Backup & Recovery
- [ ] Backup MLflow data
  ```bash
  kubectl cp mlops/mlflow-xxx:/mlflow /backup/mlflow
  ```
- [ ] Backup Prometheus configuration
- [ ] Backup Grafana dashboards
- [ ] Document recovery procedures
- [ ] Test restore procedure

### Monitoring & Alerting
- [ ] Setup Prometheus alert rules
- [ ] Configure Grafana alerts
- [ ] Setup notification channels (email, Slack, etc.)
- [ ] Define alert thresholds
- [ ] Test alert notifications

---

## Phase 8: Documentation ✅

- [ ] Deployment summary documented
- [ ] Access URLs documented and shared with team
- [ ] Credentials documented securely
- [ ] Troubleshooting procedures documented
- [ ] Maintenance procedures documented
- [ ] Escalation contacts defined

---

## Phase 9: Handover 📤

### Team Training
- [ ] Team trained on accessing services
- [ ] Team trained on basic Kubernetes commands
- [ ] Team trained on viewing logs
- [ ] Team trained on restarting services
- [ ] Team trained on scaling applications

### Knowledge Transfer
- [ ] Shared deployment documentation
- [ ] Shared access credentials
- [ ] Shared troubleshooting guide
- [ ] Shared monitoring dashboards
- [ ] Shared update procedures

---

## Quick Reference Commands

### Check Status
```bash
# All pods
kubectl get pods -n mlops

# All services
kubectl get svc -n mlops

# View logs
kubectl logs -n mlops -l app.kubernetes.io/name=heart-disease-api --tail=100

# Check ingress
kubectl get ingress -n mlops
```

### Restart Services
```bash
# Restart API
kubectl rollout restart deployment heart-disease-api -n mlops

# Restart monitoring
kubectl rollout restart deployment prometheus grafana -n mlops
```

### Scale Application
```bash
# Scale to 3 replicas
kubectl scale deployment heart-disease-api --replicas=3 -n mlops
```

### Update Application
```bash
# Rebuild image
eval $(minikube docker-env)
docker build -t heart-disease-api:latest -f Dockerfile.almalinux .

# Restart deployment
kubectl rollout restart deployment heart-disease-api -n mlops
```

### Cleanup
```bash
# Remove everything
./cleanup-deployment.sh
```

---

## Access Summary

| Service | URL | Purpose | Credentials |
|---------|-----|---------|-------------|
| API | http://72.163.219.91/ | Predictions | - |
| Swagger | http://72.163.219.91/docs | API Docs | - |
| Prometheus | http://72.163.219.91:9090 | Metrics | - |
| Grafana | http://72.163.219.91:3000 | Dashboards | admin/admin |
| MLflow | http://72.163.219.91:5000 | Experiments | - |

---

## Support Contacts

- **Repository:** https://github.com/seshu-bits/mlops
- **Documentation:** See `DEPLOYMENT_SUMMARY.md`
- **Issues:** Check `ALMA_LINUX_COMPLETE_DEPLOYMENT.md` troubleshooting section

---

## Notes

- Minikube tunnel must run continuously: Check with `ps aux | grep "minikube tunnel"`
- Nginx must be running: Check with `sudo systemctl status nginx`
- After server reboot: Run `minikube start` and `minikube tunnel`
- For updates: Pull latest code, rebuild image, restart deployment

---

## ✅ Deployment Complete!

**Date Completed:** _______________  
**Deployed By:** _______________  
**Verified By:** _______________  
**Notes:** _______________________________________________

---

**Status:** 🟢 DEPLOYED | 🟡 IN PROGRESS | 🔴 ISSUES

All checks completed successfully? Your MLOps application is ready for use! 🎉
