# 🛠️ Helper Scripts Reference

Quick reference for all helper scripts in this project.

---

## 🚀 Deployment Scripts

### `monitoring/setup-complete-monitoring.sh`
**Complete automated deployment with monitoring**

```bash
cd monitoring
./setup-complete-monitoring.sh
```

**What it does:**
- ✅ Checks prerequisites (Minikube, Docker, kubectl, Helm)
- ✅ Builds Docker image with smart base image detection
- ✅ Deploys Prometheus for metrics
- ✅ Deploys Grafana for visualization
- ✅ Deploys/upgrades the API
- ✅ Displays access URLs

**Use when:** You want complete setup in one command

---

### `helm-charts/deploy.sh`
**Deploy only the API (without monitoring)**

```bash
cd helm-charts
./deploy.sh
```

**What it does:**
- ✅ Checks prerequisites
- ✅ Builds Docker image
- ✅ Deploys API via Helm
- ✅ Tests the API
- ✅ Shows access information

**Use when:** You only need the API, no monitoring

---

## 🐳 Docker Build Scripts

### `quick-fix-base-image.sh` ⭐ **RECOMMENDED FOR ERRORS**
**Quick fix for "local-python-base:3.11 not found" error**

```bash
./quick-fix-base-image.sh
```

**What it does:**
- ✅ Checks if base image exists
- ✅ Attempts to pull `almalinux:8`
- ✅ Falls back to `python:3.11-slim` if needed
- ✅ Provides offline instructions if no internet
- ✅ Verifies the image loaded correctly

**Use when:** 
- `setup-complete-monitoring.sh` fails with base image error
- Docker build fails
- First time setup

---

### `smart-docker-build.sh`
**Intelligent Docker build with automatic base image detection**

```bash
./smart-docker-build.sh
```

**What it does:**
- ✅ Detects available base images
- ✅ Chooses the best Dockerfile automatically:
  - `python:3.11-slim` → Uses `Dockerfile.offline`
  - `almalinux:8` → Uses `Dockerfile.almalinux`
  - `rockylinux:8` → Builds `Dockerfile.base` first
  - `local-python-base:3.11` → Uses standard `Dockerfile`
- ✅ Tries to pull base images if needed
- ✅ Shows detailed build information

**Use when:** 
- Manual Docker build needed
- Want to see which Dockerfile is being used
- Testing different base images

---

### `setup-base-image.sh`
**Interactive base image setup**

```bash
./setup-base-image.sh
```

**What it does:**
- ✅ Shows current available images
- ✅ Provides menu to choose:
  1. Pull almalinux:8 (online)
  2. Pull python:3.11-slim (online)
  3. Load from file (offline)
  4. Check status
- ✅ Guides through offline setup
- ✅ Verifies image loaded

**Use when:**
- Need interactive guidance
- Want to choose specific base image
- Setting up offline

---

## 🧪 Testing Scripts

### `helm-charts/test-api.sh`
**Comprehensive API testing**

```bash
cd helm-charts
./test-api.sh
```

**What it does:**
- ✅ Tests health endpoint
- ✅ Tests single prediction
- ✅ Tests batch prediction
- ✅ Shows response times
- ✅ Validates responses

**Use when:** Verifying API works correctly

---

### `monitoring/test-metrics.sh`
**Generate test traffic for monitoring**

```bash
cd monitoring
./test-metrics.sh
```

**What it does:**
- ✅ Sends 100 test predictions
- ✅ Varies input data
- ✅ Shows metrics being generated
- ✅ Useful for testing Prometheus/Grafana

**Use when:** 
- Testing monitoring setup
- Want to see metrics in Grafana
- Demo purposes

---

### `run_integration_tests.sh`
**Run integration tests**

```bash
./run_integration_tests.sh
```

**What it does:**
- ✅ Runs all integration tests
- ✅ Tests API endpoints
- ✅ Validates predictions
- ✅ Checks error handling

**Use when:** Running full test suite

---

## 🧹 Cleanup Scripts

### `helm-charts/cleanup.sh`
**Remove API deployment**

```bash
cd helm-charts
./cleanup.sh
```

**What it does:**
- ✅ Uninstalls Helm release
- ✅ Deletes namespace (optional)
- ✅ Cleans up resources

---

### `monitoring/cleanup-monitoring.sh`
**Remove monitoring stack**

```bash
cd monitoring
./cleanup-monitoring.sh
```

**What it does:**
- ✅ Removes Prometheus
- ✅ Removes Grafana
- ✅ Cleans up ConfigMaps

---

## 🌐 Remote Access Scripts

### `setup-nginx-proxy.sh`
**Setup nginx reverse proxy for remote access**

```bash
./setup-nginx-proxy.sh
```

**What it does:**
- ✅ Installs nginx
- ✅ Configures reverse proxy
- ✅ Sets up authentication
- ✅ Opens firewall ports

**Use when:** Need to access services remotely

---

## 📊 Monitoring Scripts

### `monitoring/deploy-monitoring.sh`
**Deploy only monitoring stack**

```bash
cd monitoring
./deploy-monitoring.sh
```

**What it does:**
- ✅ Deploys Prometheus
- ✅ Deploys Grafana
- ✅ Does NOT rebuild API

**Use when:** API already deployed, just need monitoring

---

## 🔍 Troubleshooting Workflow

### When Docker Build Fails:

```bash
# Step 1: Quick fix (recommended)
./quick-fix-base-image.sh

# If that fails, try interactive setup:
./setup-base-image.sh

# Or manually check available images:
eval $(minikube docker-env)
docker images | grep -E "(python|almalinux)"

# Then run smart build:
./smart-docker-build.sh
```

### When Monitoring Setup Fails:

```bash
# Check Minikube status
minikube status

# Fix base image first
./quick-fix-base-image.sh

# Try monitoring setup again
cd monitoring
./setup-complete-monitoring.sh

# Check logs if still failing
kubectl logs -l app=heart-disease-api -n mlops
```

---

## 📝 Complete Deployment Sequence

### First Time Setup (AlmaLinux 8):

```bash
# 1. Start Minikube
minikube start --driver=docker --cpus=2 --memory=4096

# 2. Fix base image (if online)
./quick-fix-base-image.sh

# 3. Deploy everything
cd monitoring
./setup-complete-monitoring.sh

# 4. Verify
kubectl get pods -n mlops

# 5. Test
./test-metrics.sh

# 6. Access Grafana
echo "http://$(minikube ip):3000"
```

### Offline Setup:

```bash
# 1. On machine with internet
docker pull python:3.11-slim
docker save python:3.11-slim -o python-3.11-slim.tar

# 2. Transfer to AlmaLinux machine

# 3. On AlmaLinux machine
minikube start --driver=docker --cpus=2 --memory=4096
eval $(minikube docker-env)
docker load -i python-3.11-slim.tar

# 4. Deploy
cd monitoring
./setup-complete-monitoring.sh
```

---

## 🎯 Quick Command Reference

```bash
# Fix base image issues
./quick-fix-base-image.sh

# Full deployment
cd monitoring && ./setup-complete-monitoring.sh

# Just build Docker image
./smart-docker-build.sh

# Just deploy API
cd helm-charts && ./deploy.sh

# Test API
cd helm-charts && ./test-api.sh

# Test monitoring
cd monitoring && ./test-metrics.sh

# Check deployment
kubectl get pods -n mlops
kubectl get svc -n mlops

# Get URLs
MINIKUBE_IP=$(minikube ip)
echo "API: http://$MINIKUBE_IP:30080"
echo "Prometheus: http://$MINIKUBE_IP:30090"
echo "Grafana: http://$MINIKUBE_IP:3000"

# View logs
kubectl logs -l app=heart-disease-api -n mlops --tail=50

# Cleanup
cd helm-charts && ./cleanup.sh
cd monitoring && ./cleanup-monitoring.sh
```

---

## 📚 Documentation Files

- **`DEPLOYMENT_AND_TESTING_GUIDE.md`** - Complete deployment guide
- **`DOCKER_BUILD_TROUBLESHOOTING.md`** - Docker build issues and solutions
- **`README.md`** - Main project documentation
- **`ARCHITECTURE.md`** - System architecture
- **`monitoring/README.md`** - Monitoring setup details
- **`helm-charts/README.md`** - Helm deployment details

---

## 🆘 Getting Help

1. **Docker build fails?** → `DOCKER_BUILD_TROUBLESHOOTING.md`
2. **Deployment fails?** → `DEPLOYMENT_AND_TESTING_GUIDE.md`
3. **API not working?** → Check logs: `kubectl logs -l app=heart-disease-api -n mlops`
4. **Monitoring not working?** → `monitoring/README.md`

---

## ✅ Success Indicators

- [ ] `./quick-fix-base-image.sh` succeeds
- [ ] `./smart-docker-build.sh` builds image
- [ ] `kubectl get pods -n mlops` shows all Running
- [ ] `curl http://$(minikube ip):30080/health` returns OK
- [ ] Prometheus shows targets: `http://$(minikube ip):30090/targets`
- [ ] Grafana accessible: `http://$(minikube ip):3000`

When all checks pass, your deployment is successful! 🎉
