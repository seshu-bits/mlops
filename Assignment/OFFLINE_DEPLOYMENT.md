# Offline Deployment Guide for Air-Gapped Environments

This guide is specifically for deploying the Heart Disease API in **completely offline** or **air-gapped** environments where Docker cannot reach external registries.

## Problem

When you see errors like:
```
ERROR: failed to solve: DeadlineExceeded: almalinux:8: failed to resolve source metadata
dial tcp: lookup registry-1.docker.io: i/o timeout
```

This means your environment cannot reach Docker Hub or other container registries.

## Solution Overview

The solution is to **pre-load base images** into your Docker/Minikube environment before building your application.

---

## Step-by-Step Offline Deployment

### Phase 1: Preparation (On Internet-Connected Machine)

On a machine **with internet access**:

```bash
# Pull the Python base image
docker pull python:3.11-slim

# Save it to a tar file
docker save python:3.11-slim -o python-3.11-slim.tar

# Verify the tar file was created
ls -lh python-3.11-slim.tar
```

The tar file will be about 200-300 MB.

### Phase 2: Transfer

Transfer `python-3.11-slim.tar` to your offline Alma Linux 8 server using:
- USB drive
- SCP/SFTP (if internal network allows)
- Any approved file transfer method in your environment

### Phase 3: Load on Offline Server

On your **offline Alma Linux 8 server**:

```bash
# Navigate to where you transferred the tar file
cd /path/to/transferred/files

# If using Minikube, configure shell to use its Docker daemon
eval $(minikube docker-env)

# Load the image into Docker
docker load -i python-3.11-slim.tar

# Verify it loaded successfully
docker images | grep python

# You should see:
# python       3.11-slim   <image-id>   <created>   <size>
```

### Phase 4: Build and Deploy

Now you can build and deploy normally:

```bash
cd /path/to/mlops/Assignment/helm-charts
./deploy.sh
```

The `deploy.sh` script will automatically:
1. Detect that `python:3.11-slim` is available
2. Use `Dockerfile.offline` which references the pre-loaded image
3. Build your application without needing internet
4. Deploy to Kubernetes

---

## Alternative Base Images

If `python:3.11-slim` doesn't work, you can use alternative base images:

### Option A: AlmaLinux Base

**On internet machine:**
```bash
docker pull almalinux:8
docker save almalinux:8 -o almalinux-8.tar
```

**On offline server:**
```bash
eval $(minikube docker-env)
docker load -i almalinux-8.tar
cd /path/to/mlops/Assignment
eval $(minikube docker-env)
docker build -t heart-disease-api:latest -f Dockerfile.almalinux .
```

### Option B: Red Hat UBI (Universal Base Image)

**On internet machine:**
```bash
docker pull registry.access.redhat.com/ubi8/ubi-minimal:8.9
docker save registry.access.redhat.com/ubi8/ubi-minimal:8.9 -o ubi8-minimal.tar
```

**On offline server:**
```bash
eval $(minikube docker-env)
docker load -i ubi8-minimal.tar
cd /path/to/mlops/Assignment
eval $(minikube docker-env)
docker build -t local-python-base:3.11 -f Dockerfile.base .
docker build -t heart-disease-api:latest .
```

---

## Checking Available Images

Run this script to see what base images you already have:

```bash
cd /path/to/mlops/Assignment
chmod +x check-base-images.sh
./check-base-images.sh
```

This will show you all available images and recommend the best approach.

---

## Manual Build Process (If deploy.sh Fails)

If the deploy script fails, you can build manually:

```bash
# 1. Configure Docker for Minikube
eval $(minikube docker-env)

# 2. Check what images you have
docker images

# 3. Choose the appropriate Dockerfile based on available images:

# If you have python:3.11-slim:
cd /path/to/mlops/Assignment
docker build -t heart-disease-api:latest -f Dockerfile.offline .

# If you have almalinux:8:
docker build -t heart-disease-api:latest -f Dockerfile.almalinux .

# If you have registry.access.redhat.com/ubi8/ubi-minimal:8.9:
docker build -t local-python-base:3.11 -f Dockerfile.base .
docker build -t heart-disease-api:latest .

# 4. Verify the image was built
docker images | grep heart-disease-api

# 5. Deploy with Helm
cd helm-charts
helm install heart-disease-api ./heart-disease-api \
    --namespace mlops \
    --create-namespace \
    --set image.pullPolicy=Never \
    --wait
```

---

## Troubleshooting

### Issue: "No such file or directory: python-3.11-slim.tar"
**Solution:** Verify the tar file was transferred correctly:
```bash
ls -lh python-3.11-slim.tar
file python-3.11-slim.tar  # Should say "POSIX tar archive"
```

### Issue: "docker load" fails with "invalid tar header"
**Solution:** The tar file may be corrupted. Re-create it on the internet machine and transfer again.

### Issue: Image loads but build still tries to pull from internet
**Solution:** Check that you're using Minikube's Docker daemon:
```bash
eval $(minikube docker-env)
docker images  # Should show your loaded images
```

### Issue: "apt-get update" fails during build
**Solution:** The base image needs internet to install packages. Use a pre-built image with all dependencies, or:
1. Build the image on an internet-connected machine
2. Save the **built** application image as tar
3. Load it on the offline server

**On internet machine:**
```bash
cd /path/to/mlops/Assignment
docker build -t heart-disease-api:latest -f Dockerfile.offline .
docker save heart-disease-api:latest -o heart-disease-api.tar
```

**On offline server:**
```bash
eval $(minikube docker-env)
docker load -i heart-disease-api.tar
# Now just deploy with Helm (skip the build step)
```

---

## Complete Offline Workflow (Pre-Built Image)

For maximum reliability in air-gapped environments, build everything on an internet machine:

**On internet machine:**
```bash
# 1. Build the complete application image
cd /path/to/mlops/Assignment
docker build -t heart-disease-api:latest .

# 2. Save it
docker save heart-disease-api:latest -o heart-disease-api.tar

# 3. Transfer heart-disease-api.tar to offline server
```

**On offline server:**
```bash
# 1. Load the pre-built image
eval $(minikube docker-env)
docker load -i heart-disease-api.tar

# 2. Verify
docker images | grep heart-disease-api

# 3. Deploy (Helm will use the local image)
cd /path/to/mlops/Assignment/helm-charts
helm install heart-disease-api ./heart-disease-api \
    --namespace mlops \
    --create-namespace \
    --set image.pullPolicy=Never \
    --wait
```

This approach bypasses all build steps on the offline server.

---

## Summary

✅ **Recommended for Alma Linux 8 Offline:**

1. Use `python:3.11-slim` as the base image
2. Pre-load it on internet machine: `docker save python:3.11-slim -o python-3.11-slim.tar`
3. Transfer tar to offline server
4. Load it: `docker load -i python-3.11-slim.tar`
5. Run `./deploy.sh` - it will automatically detect and use the offline Dockerfile

**OR for maximum simplicity:**

1. Build complete image on internet machine
2. Save it: `docker save heart-disease-api:latest -o heart-disease-api.tar`
3. Transfer and load on offline server
4. Deploy with Helm (no build needed)

---

## Need Help?

If you're still stuck:
1. Run `./check-base-images.sh` and share the output
2. Check `/tmp/docker-build.log` for build errors
3. Verify Minikube is running: `minikube status`
4. Verify Docker daemon access: `docker ps`
