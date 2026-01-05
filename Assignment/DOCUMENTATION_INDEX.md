# 📚 Minikube Deployment Documentation Index

This index helps you navigate all the documentation for deploying the Heart Disease Prediction API on Minikube (Alma Linux 8).

---

## 🎯 Start Here

### New to This Project?
1. **[DEPLOYMENT_SUMMARY.md](./DEPLOYMENT_SUMMARY.md)** ⭐ **START HERE!**
   - Complete overview of what has been created
   - Quick copy-paste deployment steps
   - Verification checklist

### Setting Up from Scratch?
2. **[MINIKUBE_SETUP_GUIDE.md](./MINIKUBE_SETUP_GUIDE.md)**
   - Complete installation guide for Alma Linux 8
   - Step-by-step instructions for Docker, Minikube, Helm
   - Detailed troubleshooting section
   - **Use this for first-time setup**

### Need Quick Commands?
3. **[QUICK_REFERENCE.md](./QUICK_REFERENCE.md)**
   - Essential commands in one place
   - Quick troubleshooting fixes
   - Copy-paste ready commands
   - **Perfect for daily operations**

---

## 📁 Documentation by Category

### 🏗️ Architecture & Design
- **[ARCHITECTURE.md](./ARCHITECTURE.md)**
  - System architecture diagrams
  - Network flow
  - Component relationships
  - Scaling architecture
  - Resource requirements

### 🚀 Deployment
- **[DEPLOYMENT_SUMMARY.md](./DEPLOYMENT_SUMMARY.md)**
  - Complete deployment overview
  - Phase-by-phase deployment steps
  - Testing procedures
  - Cleanup instructions

- **[MINIKUBE_SETUP_GUIDE.md](./MINIKUBE_SETUP_GUIDE.md)**
  - Prerequisites installation (Alma Linux 8)
  - Docker, Minikube, Helm setup
  - Build and deploy instructions
  - Access methods
  - Comprehensive troubleshooting

### 🎛️ Helm Charts
- **[helm-charts/README.md](./helm-charts/README.md)**
  - Helm chart overview
  - Chart structure
  - Configuration options
  - Multiple deployment methods
  - Monitoring and management

- **[helm-charts/heart-disease-api/README.md](./helm-charts/heart-disease-api/README.md)**
  - Chart-specific documentation
  - Parameter descriptions
  - Customization examples
  - Advanced features

### 🔧 Configuration
- **[helm-charts/heart-disease-api/values.yaml](./helm-charts/heart-disease-api/values.yaml)**
  - Default configuration values
  - Inline documentation
  - Common settings

- **[helm-charts/heart-disease-api/values-dev.yaml](./helm-charts/heart-disease-api/values-dev.yaml)**
  - Development environment settings
  - Lower resource limits
  - Debug mode enabled

- **[helm-charts/heart-disease-api/values-prod.yaml](./helm-charts/heart-disease-api/values-prod.yaml)**
  - Production environment settings
  - High availability configuration
  - Autoscaling enabled
  - Ingress configured

### 📖 Existing Documentation
- **[DOCKER_GUIDE.md](./DOCKER_GUIDE.md)**
  - Docker-specific deployment
  - Container management
  - Local testing with Docker

- **[README_API.md](./README_API.md)**
  - API documentation
  - Endpoint descriptions
  - Request/response examples

---

## 🛠️ Automation Scripts

### Deployment Scripts
Located in `helm-charts/`:

1. **[deploy.sh](./helm-charts/deploy.sh)** ✨
   - Automated deployment script
   - Checks prerequisites
   - Builds image in Minikube
   - Deploys with Helm
   - Verifies deployment
   - Tests API
   - Shows access information
   ```bash
   cd helm-charts && ./deploy.sh
   ```

2. **[test-api.sh](./helm-charts/test-api.sh)** 🧪
   - Comprehensive API testing
   - Tests all endpoints
   - Validates responses
   - Performance testing
   - Input validation tests
   ```bash
   cd helm-charts && ./test-api.sh
   ```

3. **[cleanup.sh](./helm-charts/cleanup.sh)** 🧹
   - Automated cleanup
   - Removes Helm release
   - Deletes namespace
   - Cleans Docker images
   ```bash
   cd helm-charts && ./cleanup.sh
   ```

---

## 🎓 Learning Path

### Beginner Path
Follow this order if you're new to Kubernetes/Helm:

1. Read **DEPLOYMENT_SUMMARY.md** for overview
2. Follow **MINIKUBE_SETUP_GUIDE.md** step-by-step
3. Run `deploy.sh` for automated deployment
4. Test with `test-api.sh`
5. Refer to **QUICK_REFERENCE.md** for commands

### Advanced Path
If you're familiar with Kubernetes:

1. Review **ARCHITECTURE.md** for design
2. Skim **helm-charts/README.md** for chart structure
3. Customize `values.yaml` for your needs
4. Deploy manually with `helm install`
5. Configure monitoring and autoscaling

---

## 📝 Quick Navigation

### By Task

| What do you want to do? | Where to look? |
|-------------------------|----------------|
| Install everything from scratch | [MINIKUBE_SETUP_GUIDE.md](./MINIKUBE_SETUP_GUIDE.md) |
| Deploy the API | [DEPLOYMENT_SUMMARY.md](./DEPLOYMENT_SUMMARY.md) or run `deploy.sh` |
| Test the API | Run `test-api.sh` or see [helm-charts/README.md](./helm-charts/README.md) |
| Troubleshoot issues | [MINIKUBE_SETUP_GUIDE.md#troubleshooting](./MINIKUBE_SETUP_GUIDE.md#9-troubleshooting) |
| Find a specific command | [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) |
| Understand architecture | [ARCHITECTURE.md](./ARCHITECTURE.md) |
| Configure Helm chart | [helm-charts/heart-disease-api/README.md](./helm-charts/heart-disease-api/README.md) |
| Customize deployment | Edit `values.yaml` or `values-dev.yaml` |
| Clean up everything | Run `cleanup.sh` |
| Monitor the application | [helm-charts/README.md#monitoring](./helm-charts/README.md#-monitoring) |
| Scale the application | [DEPLOYMENT_SUMMARY.md#monitoring--management](./DEPLOYMENT_SUMMARY.md#-monitoring--management) |
| Update/upgrade | [DEPLOYMENT_SUMMARY.md#upgrade--rollback](./DEPLOYMENT_SUMMARY.md#-upgrade--rollback) |

---

## 🔗 File Relationships

```
DEPLOYMENT_SUMMARY.md (Overview)
    │
    ├──► MINIKUBE_SETUP_GUIDE.md (Detailed Setup)
    │       │
    │       └──► helm-charts/deploy.sh (Automation)
    │
    ├──► ARCHITECTURE.md (System Design)
    │
    ├──► QUICK_REFERENCE.md (Commands)
    │
    └──► helm-charts/
            │
            ├──► README.md (Chart Overview)
            │       │
            │       └──► heart-disease-api/
            │               ├──► README.md (Chart Docs)
            │               ├──► values.yaml (Config)
            │               ├──► values-dev.yaml
            │               ├──► values-prod.yaml
            │               └──► templates/ (K8s Manifests)
            │
            ├──► deploy.sh (Deploy Automation)
            ├──► test-api.sh (Testing)
            └──► cleanup.sh (Cleanup)
```

---

## 🆘 Troubleshooting Guide Location

Different types of issues are covered in different documents:

| Issue Type | Document | Section |
|------------|----------|---------|
| Installation problems | [MINIKUBE_SETUP_GUIDE.md](./MINIKUBE_SETUP_GUIDE.md) | Section 9: Troubleshooting |
| Deployment errors | [DEPLOYMENT_SUMMARY.md](./DEPLOYMENT_SUMMARY.md) | Troubleshooting Guide |
| Quick fixes | [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) | Troubleshooting Quick Fixes |
| Helm chart issues | [helm-charts/README.md](./helm-charts/README.md) | Troubleshooting |
| Chart-specific | [helm-charts/heart-disease-api/README.md](./helm-charts/heart-disease-api/README.md) | Troubleshooting |

---

## 📊 Documentation Stats

```
Created Files:
├── 4 Markdown Documentation Files
├── 1 Complete Helm Chart (with 13 template files)
├── 3 Environment Configuration Files
├── 3 Automation Scripts
└── Total: 24 files

Lines of Documentation: ~3,500+
Lines of Configuration: ~800+
Lines of Scripts: ~600+
```

---

## 🎯 Recommended Reading Order

### First-Time Setup (Alma Linux 8)
1. ✅ **DEPLOYMENT_SUMMARY.md** - Get overview (10 min)
2. ✅ **MINIKUBE_SETUP_GUIDE.md** - Follow step-by-step (30 min)
3. ✅ Run **deploy.sh** - Automated deployment (5 min)
4. ✅ Run **test-api.sh** - Verify everything works (2 min)
5. ✅ **QUICK_REFERENCE.md** - Bookmark for daily use

### Already Deployed?
1. **QUICK_REFERENCE.md** - Daily commands
2. **helm-charts/README.md** - Management tasks
3. **DEPLOYMENT_SUMMARY.md** - Monitoring & scaling

### Planning Production Deployment?
1. **ARCHITECTURE.md** - Understand design
2. **values-prod.yaml** - Production config
3. **helm-charts/heart-disease-api/README.md** - Advanced features
4. **MINIKUBE_SETUP_GUIDE.md** - Production considerations

---

## 🔍 Search Guide

Can't find what you're looking for? Search these keywords:

| Looking for... | Search keyword | File |
|----------------|----------------|------|
| Installation | "install", "setup", "prerequisites" | MINIKUBE_SETUP_GUIDE.md |
| Commands | "command", "kubectl", "helm" | QUICK_REFERENCE.md |
| Configuration | "values", "configuration", "customize" | helm-charts/*/README.md |
| Errors | "error", "failed", "troubleshoot" | All guides - Section 9 |
| Testing | "test", "curl", "endpoint" | test-api.sh, helm-charts/README.md |
| Cleanup | "cleanup", "delete", "uninstall" | cleanup.sh, All guides - Section 10 |
| Scaling | "scale", "replicas", "autoscaling" | DEPLOYMENT_SUMMARY.md, values.yaml |
| Monitoring | "logs", "metrics", "monitor" | helm-charts/README.md |

---

## 📞 Getting Help

### Documentation Issues?
- Check the **Troubleshooting** sections in each guide
- Review **QUICK_REFERENCE.md** for common fixes
- Run `deploy.sh` or `test-api.sh` for automated diagnostics

### System Issues?
- Docker: [MINIKUBE_SETUP_GUIDE.md - Section 2](./MINIKUBE_SETUP_GUIDE.md#2-docker-setup)
- Minikube: [MINIKUBE_SETUP_GUIDE.md - Section 4](./MINIKUBE_SETUP_GUIDE.md#4-minikube-installation)
- Helm: [MINIKUBE_SETUP_GUIDE.md - Section 5](./MINIKUBE_SETUP_GUIDE.md#5-helm-installation)

### Application Issues?
- API errors: Check logs with `kubectl logs`
- Performance: Review resource usage with `kubectl top pods`
- Configuration: Verify with `helm get values`

---

## 🎉 Quick Start (TL;DR)

```bash
# 1. Read the overview
cat DEPLOYMENT_SUMMARY.md

# 2. Follow detailed setup
cat MINIKUBE_SETUP_GUIDE.md

# 3. Deploy automatically
cd helm-charts && ./deploy.sh

# 4. Test everything
./test-api.sh

# 5. Keep reference handy
cat QUICK_REFERENCE.md
```

---

## 📅 Document Versions

All documents in this collection are synchronized and refer to:
- **API Version**: 1.0.0
- **Helm Chart Version**: 1.0.0
- **Target Platform**: Alma Linux 8
- **Kubernetes**: 1.19+
- **Helm**: 3.0+
- **Docker**: 20.10+
- **Minikube**: Latest stable

---

## ✨ What Makes This Complete?

✅ **Installation** - Complete Alma Linux 8 setup  
✅ **Deployment** - Automated scripts  
✅ **Configuration** - Multiple environments  
✅ **Testing** - Comprehensive test suite  
✅ **Monitoring** - Logging and metrics  
✅ **Scaling** - Autoscaling configuration  
✅ **Security** - Best practices  
✅ **Documentation** - Extensive guides  
✅ **Troubleshooting** - Common issues covered  
✅ **Cleanup** - Automated removal  

---

**Ready to deploy? Start with [DEPLOYMENT_SUMMARY.md](./DEPLOYMENT_SUMMARY.md)!** 🚀
