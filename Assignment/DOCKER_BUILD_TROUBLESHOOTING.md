# 🔧 Docker Build Issues - Troubleshooting Guide for AlmaLinux 8

This guide addresses the common "local-python-base:3.11 not found" error and provides solutions.

---

## 🎯 Problem

When running `setup-complete-monitoring.sh` or building Docker images, you encounter:

```
ERROR: failed to solve: local-python-base:3.11: failed to resolve source metadata 
for docker.io/library/local-python-base:3.11: pull access denied, repository does 
not exist or may require authorization
```

**Root Cause:** The default `Dockerfile` expects a local base image (`local-python-base:3.11`) that doesn't exist in your Docker environment.

---

## ✅ Solution Overview

You have **3 solutions** (choose the one that fits your situation):

1. **Quick Fix** - Pull a base image (requires internet)
2. **Offline Fix** - Load a base image from file
3. **Automated Fix** - Use the smart build script

---

## 🚀 Solution 1: Quick Fix (Internet Required)

### For AlmaLinux 8 Systems (Recommended)

```bash
# Navigate to project
cd /path/to/mlops/Assignment

# Configure to use Minikube's Docker
eval $(minikube docker-env)

# Pull AlmaLinux base image
docker pull almalinux:8

# Verify it's loaded
docker images | grep almalinux
```

**Expected output:**
```
almalinux    8    abc123def456    2 weeks ago    200MB
```

**Now run the monitoring setup:**
```bash
cd monitoring
./setup-complete-monitoring.sh
```

### Alternative: Use Python Slim Image (Faster, Smaller)

```bash
# Configure to use Minikube's Docker
eval $(minikube docker-env)

# Pull Python base image
docker pull python:3.11-slim

# Verify it's loaded
docker images | grep python

# Run monitoring setup
cd monitoring
./setup-complete-monitoring.sh
```

---

## 📦 Solution 2: Offline Fix (No Internet)

If your AlmaLinux machine has **no internet access**:

### Step 1: On a Machine WITH Internet

```bash
# Pull the base image
docker pull python:3.11-slim

# Save it to a tar file
docker save python:3.11-slim -o python-3.11-slim.tar

# Check file size (should be ~100-150MB)
ls -lh python-3.11-slim.tar
```

### Step 2: Transfer to AlmaLinux Machine

Use SCP, USB drive, or any transfer method:

```bash
# Example using SCP
scp python-3.11-slim.tar user@almalinux-server:/tmp/
```

### Step 3: Load on AlmaLinux Machine

```bash
# Navigate to where you transferred the file
cd /tmp

# Configure Docker for Minikube
eval $(minikube docker-env)

# Load the image
docker load -i python-3.11-slim.tar

# Verify
docker images | grep python
```

**Expected output:**
```
python    3.11-slim    xyz789abc123    3 weeks ago    125MB
```

### Step 4: Run Setup

```bash
cd /path/to/mlops/Assignment/monitoring
./setup-complete-monitoring.sh
```

---

## 🤖 Solution 3: Automated Interactive Setup

We've created helper scripts to automate this:

### Option A: Interactive Base Image Setup

```bash
cd /path/to/mlops/Assignment
./setup-base-image.sh
```

This interactive script will:
- Show available images
- Let you choose: pull online, load from file, or check status
- Guide you through the process

### Option B: Smart Docker Build

```bash
cd /path/to/mlops/Assignment
./smart-docker-build.sh
```

This script:
- Automatically detects available base images
- Chooses the best Dockerfile
- Tries to pull base images if needed
- Provides clear instructions if manual setup is required

---

## 🔍 Verify Your Setup

After loading a base image, verify everything is ready:

```bash
# Configure Docker
eval $(minikube docker-env)

# Check available images
docker images

# You should see ONE of these:
# - python:3.11-slim
# - almalinux:8
# - rockylinux:8
# - local-python-base:3.11

# Test build
cd /path/to/mlops/Assignment
./smart-docker-build.sh
```

---

## 📝 Which Dockerfile Gets Used?

The system will automatically choose based on available images:

| Available Base Image | Dockerfile Used | Notes |
|---------------------|----------------|-------|
| `python:3.11-slim` | `Dockerfile.offline` | ✅ Fastest, smallest |
| `almalinux:8` | `Dockerfile.almalinux` | ✅ Native AlmaLinux |
| `rockylinux:8` | Builds `Dockerfile.base`, then `Dockerfile` | Compatible RHEL |
| `local-python-base:3.11` | `Dockerfile` | Pre-built custom base |

---

## 🎯 Complete Step-by-Step for AlmaLinux 8

Here's the **complete workflow** from scratch:

### Step 1: Ensure Minikube is Running

```bash
minikube status

# If not running:
minikube start --driver=docker --cpus=2 --memory=4096
```

### Step 2: Load Base Image

**Option A - Online (Recommended):**
```bash
cd /path/to/mlops/Assignment
eval $(minikube docker-env)
docker pull almalinux:8
```

**Option B - Offline:**
```bash
# (After transferring python-3.11-slim.tar)
cd /path/to/mlops/Assignment
eval $(minikube docker-env)
docker load -i /path/to/python-3.11-slim.tar
```

### Step 3: Verify Image Loaded

```bash
docker images | grep -E "(python|almalinux)"
```

Should show something like:
```
almalinux    8           abc123    2 weeks ago    200MB
```
OR
```
python       3.11-slim   xyz789    3 weeks ago    125MB
```

### Step 4: Run Monitoring Setup

```bash
cd monitoring
./setup-complete-monitoring.sh
```

### Step 5: Verify Deployment

```bash
# Check pods
kubectl get pods -n mlops

# All should show Running status
```

---

## 🔧 Manual Build (If Scripts Fail)

If automated scripts don't work, build manually:

### With AlmaLinux:8

```bash
cd /path/to/mlops/Assignment
eval $(minikube docker-env)
docker build -t heart-disease-api:latest -f Dockerfile.almalinux .
```

### With Python:3.11-slim

```bash
cd /path/to/mlops/Assignment
eval $(minikube docker-env)
docker build -t heart-disease-api:latest -f Dockerfile.offline .
```

### Then Deploy with Helm

```bash
cd helm-charts
helm install heart-disease-api ./heart-disease-api \
  --namespace mlops \
  --create-namespace \
  --set image.pullPolicy=Never
```

---

## ❓ FAQ

### Q: Why doesn't the default Dockerfile work?

**A:** The default `Dockerfile` requires a custom base image (`local-python-base:3.11`) that must be built separately. The alternative Dockerfiles (`Dockerfile.offline`, `Dockerfile.almalinux`) use publicly available base images.

### Q: Which base image should I use?

**A:** For AlmaLinux 8:
- **Best**: `almalinux:8` (native compatibility)
- **Fastest**: `python:3.11-slim` (smaller, pre-configured Python)

### Q: Can I use a different base image?

**A:** Yes! You can use:
- `rockylinux:8`
- `centos:8`
- `registry.access.redhat.com/ubi8/ubi-minimal:8.9`

Just make sure to pull/load it first.

### Q: Do I need to reload the image every time?

**A:** No! Once loaded into Minikube's Docker, it persists until you delete Minikube or the image.

### Q: How do I check if I have the right image?

```bash
eval $(minikube docker-env)
docker images | grep -E "(python:3.11|almalinux:8)"
```

If you see output, you're good!

---

## 🆘 Still Having Issues?

### Check Docker Configuration

```bash
# Ensure using Minikube's Docker
eval $(minikube docker-env)
docker info | grep -i name
# Should show: Name: minikube
```

### Check Minikube Status

```bash
minikube status
# All should be "Running"
```

### Check Disk Space

```bash
df -h
# Ensure you have at least 2GB free
```

### Clean Up and Retry

```bash
# Remove old images
eval $(minikube docker-env)
docker system prune -a -f

# Pull fresh base image
docker pull almalinux:8

# Retry setup
cd monitoring
./setup-complete-monitoring.sh
```

---

## 📚 Related Files

- `Dockerfile` - Default (requires local-python-base:3.11)
- `Dockerfile.offline` - Uses python:3.11-slim
- `Dockerfile.almalinux` - Uses almalinux:8
- `Dockerfile.base` - Builds local-python-base:3.11
- `smart-docker-build.sh` - Automated build with detection
- `setup-base-image.sh` - Interactive base image setup
- `monitoring/setup-complete-monitoring.sh` - Complete deployment

---

## ✅ Success Checklist

- [ ] Minikube is running (`minikube status`)
- [ ] Docker is configured for Minikube (`eval $(minikube docker-env)`)
- [ ] Base image is loaded (`docker images | grep -E "python|almalinux"`)
- [ ] Smart build script runs successfully (`./smart-docker-build.sh`)
- [ ] Image `heart-disease-api:latest` exists (`docker images | grep heart-disease`)
- [ ] Monitoring setup completes (`cd monitoring && ./setup-complete-monitoring.sh`)
- [ ] All pods are running (`kubectl get pods -n mlops`)

---

## 🎉 Quick Command Reference

```bash
# Check base images
eval $(minikube docker-env) && docker images | grep -E "(python|almalinux|rocky)"

# Pull AlmaLinux base
eval $(minikube docker-env) && docker pull almalinux:8

# Pull Python base
eval $(minikube docker-env) && docker pull python:3.11-slim

# Run smart build
cd /path/to/mlops/Assignment && ./smart-docker-build.sh

# Run monitoring setup
cd /path/to/mlops/Assignment/monitoring && ./setup-complete-monitoring.sh

# Check deployment
kubectl get pods -n mlops
```

---

**Need more help?** Check the deployment guide: `DEPLOYMENT_AND_TESTING_GUIDE.md`
