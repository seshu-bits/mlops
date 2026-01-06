# Quick Reference: Offline Deployment on Alma Linux 8

## Your Situation
❌ No internet access on Alma Linux 8 server
❌ Cannot reach Docker Hub or any external registry
✅ Need to deploy Heart Disease API

---

## Fastest Solution (2 Steps)

### On Machine WITH Internet:
```bash
docker pull python:3.11-slim
docker save python:3.11-slim -o python-3.11-slim.tar
# Transfer python-3.11-slim.tar to your Alma Linux server
```

### On Your Alma Linux 8 Server:
```bash
eval $(minikube docker-env)
docker load -i python-3.11-slim.tar
cd /path/to/mlops/Assignment/helm-charts
./deploy.sh
```

**Done!** The deploy script will automatically detect the pre-loaded image and build offline.

---

## What If I Don't Have Access to an Internet Machine?

### Option A: Pre-Built Complete Image
Ask someone with internet to build the complete app image:

```bash
# They run:
git clone <your-repo>
cd mlops/Assignment
docker build -t heart-disease-api:latest .
docker save heart-disease-api:latest -o heart-disease-api.tar
# They give you: heart-disease-api.tar
```

Then you just load and deploy:
```bash
eval $(minikube docker-env)
docker load -i heart-disease-api.tar
cd /path/to/mlops/Assignment/helm-charts
helm install heart-disease-api ./heart-disease-api \
    --namespace mlops --create-namespace \
    --set image.pullPolicy=Never --wait
```

---

## Check What You Have

```bash
cd /path/to/mlops/Assignment
./check-base-images.sh
```

This tells you what base images are available and what to do next.

---

## Files You Need (Pick ONE)

| File | Size | What It's For |
|------|------|---------------|
| `python-3.11-slim.tar` | ~200MB | Base Python image - simplest |
| `almalinux-8.tar` | ~150MB | Alma native base - installs Python during build |
| `heart-disease-api.tar` | ~500MB | Complete app - no build needed |

---

## Error You're Seeing vs Fix

| Error | Fix |
|-------|-----|
| `lookup registry-1.docker.io: i/o timeout` | Pre-load base image with `docker load` |
| `FROM almalinux:8` fails | Use `python:3.11-slim` instead (see above) |
| `apt-get update` fails during build | Build image on internet machine, transfer complete tar |

---

## Full Documentation

- **Detailed Guide:** `OFFLINE_DEPLOYMENT.md`
- **Alma Linux Guide:** `ALMA_LINUX_DEPLOYMENT.md`
- **Check Available Images:** `./check-base-images.sh`

---

## Still Stuck?

```bash
# Show available images
docker images

# Show deploy script will try
cd helm-charts && ./deploy.sh 2>&1 | tee deploy.log

# Share deploy.log for help
```
