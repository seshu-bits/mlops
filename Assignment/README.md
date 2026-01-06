# 🏥 Heart Disease Prediction MLOps Project

Complete MLOps implementation with FastAPI, Kubernetes deployment, Prometheus monitoring, and Grafana visualization.

---

## 📋 Table of Contents

- [Quick Start](#-quick-start)
- [Data Acquisition & EDA](#-data-acquisition--eda)
- [Project Overview](#-project-overview)
- [Architecture](#-architecture)
- [Deployment](#-deployment)
- [Monitoring](#-monitoring)
- [API Usage](#-api-usage)
- [Testing](#-testing)
- [Remote Access](#-remote-access)
- [Troubleshooting](#-troubleshooting)

---

## 🚀 Quick Start

### Prerequisites
- AlmaLinux 8 / RHEL 8
- Minikube with Docker driver
- kubectl and Helm 3.x
- Python 3.11+

### Deploy Everything (3 Commands)

```bash
# 1. Clone and navigate
git clone https://github.com/seshu-bits/mlops.git
cd mlops/Assignment

# 2. Setup monitoring and deploy
cd monitoring
./setup-complete-monitoring.sh

# 3. Setup remote access (optional)
cd ..
./setup-nginx-proxy.sh
```

**Access URLs:**
- **API**: http://\<server-ip\>/health
- **API Docs**: http://\<server-ip\>/docs
- **Prometheus**: http://\<server-ip\>:9090
- **Grafana**: http://\<server-ip\>:3000 (admin/admin)

---

## � Data Acquisition & EDA

### Dataset Information

**Source**: UCI Machine Learning Repository - Heart Disease Dataset  
**URL**: https://archive.ics.uci.edu/dataset/45/heart+disease  
**Citation**: 
- Hungarian Institute of Cardiology. Budapest: Andras Janosi, M.D.
- University Hospital, Zurich, Switzerland: William Steinbrunn, M.D.
- University Hospital, Basel, Switzerland: Matthias Pfisterer, M.D.
- V.A. Medical Center, Long Beach and Cleveland Clinic Foundation: Robert Detrano, M.D., Ph.D.

### Dataset Statistics

- **Instances**: 303 (Cleveland dataset)
- **Features**: 14 attributes (age, sex, cp, trestbps, chol, fbs, restecg, thalach, exang, oldpeak, slope, ca, thal, target)
- **Target**: Binary classification (0 = no disease, 1 = disease present)
- **Missing Values**: Present (marked as '?'), handled during preprocessing

### Download Dataset

**Option 1: Automated Download (Recommended)**

Use the Jupyter notebook which includes automated download:

```python
from pathlib import Path
from MLOps_Assignment import download_heart_disease_dataset

# Downloads from UCI and extracts to ./data
dataset_path = download_heart_disease_dataset(save_dir="./data")
```

**Option 2: Manual Download**

```bash
cd Assignment/data
wget https://archive.ics.uci.edu/static/public/45/heart+disease.zip
unzip heart+disease.zip
```

The dataset is already included in this repository at `Assignment/data/processed.cleveland.data`.

### Data Preprocessing Pipeline

Our preprocessing includes:

1. **Missing Value Handling**: Replace '?' markers with NaN and drop rows
2. **Type Conversion**: Convert numeric columns to proper dtypes
3. **Target Binarization**: Convert multi-class target (0-4) to binary (0/1)
4. **Feature Encoding**: One-hot encoding for categorical features
5. **Feature Scaling**: StandardScaler for numeric features
6. **Stratified Split**: 80/20 train-test split maintaining class balance

### Exploratory Data Analysis

The project includes comprehensive EDA with:

- **Distribution Analysis**: Histograms with KDE for all numeric features
- **Correlation Analysis**: Heatmap showing feature relationships
- **Class Balance**: Visualization of target distribution
- **Outlier Detection**: IQR-based outlier identification
- **Feature Comparison**: Box plots comparing features by target class

**Run EDA**:

```python
from MLOps_Assignment import load_raw_heart_data, clean_and_preprocess_heart_data, perform_eda_heart_data

# Load and clean data
raw_df = load_raw_heart_data("./data")
cleaned_df = clean_and_preprocess_heart_data(raw_df)

# Generate EDA visualizations
eda_results = perform_eda_heart_data(cleaned_df, output_dir="./artifacts/eda")
print(f"EDA plots saved: {eda_results['plots']}")
```

**EDA Artifacts in MLflow**:

All EDA visualizations are automatically logged to MLflow during training:
- Histograms of feature distributions
- Correlation heatmap
- Class balance plot
- Box plots by target
- Outlier detection plots

### Data Validation

Automated data validation includes:

- **Schema Validation**: Ensures expected columns are present
- **Range Validation**: Checks numeric features are within expected ranges
  - Age: 0-120 years
  - Blood Pressure: 50-250 mmHg
  - Cholesterol: 100-600 mg/dl
  - Max Heart Rate: 50-250 bpm
- **Quality Metrics**: Missing values, duplicates, outliers
- **Class Distribution**: Target class balance

**Run Validation**:

```python
from MLOps_Assignment import validate_heart_data

validation_results = validate_heart_data(raw_df)
print(f"Valid: {validation_results['is_valid']}")
print(f"Errors: {validation_results['errors']}")
print(f"Warnings: {validation_results['warnings']}")
```

---

## �📖 Project Overview

### What This Project Does

1. **Machine Learning**: Trains models to predict heart disease
2. **API Service**: FastAPI server for predictions
3. **Containerization**: Docker image with all dependencies
4. **Orchestration**: Kubernetes deployment with Helm
5. **Monitoring**: Prometheus metrics + Grafana dashboards
6. **CI/CD**: Automated testing and deployment

### Key Features

✅ **Production-Ready API** - FastAPI with automatic documentation  
✅ **Kubernetes Native** - Helm charts for easy deployment  
✅ **Full Observability** - Prometheus + Grafana monitoring  
✅ **Automated Testing** - Unit and integration tests  
✅ **Remote Access** - NGINX reverse proxy for external access  
✅ **Fixed Ports** - Consistent access across deployments  

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Remote Clients                        │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ↓
            ┌──────────────────────┐
            │   NGINX Reverse Proxy │
            │   (Port 80, 3000,    │
            │    9090)             │
            └──────────┬───────────┘
                       │
                       ↓
            ┌──────────────────────┐
            │   Kubernetes Ingress  │
            │   (NGINX Controller)  │
            └──────────┬───────────┘
                       │
       ┌───────────────┼───────────────┐
       │               │               │
       ↓               ↓               ↓
┌─────────────┐ ┌──────────┐ ┌──────────┐
│ API Service │ │Prometheus│ │ Grafana  │
│  (ClusterIP)│ │(NodePort)│ │(NodePort)│
│  Port: 80   │ │Port: 9090│ │Port: 3000│
└──────┬──────┘ └────┬─────┘ └────┬─────┘
       │             │            │
       ↓             ↓            ↓
┌─────────────┐ ┌──────────┐ ┌──────────┐
│   API Pods  │ │Prometheus│ │ Grafana  │
│  (2 replicas│ │   Pod    │ │   Pod    │
│   Port 8000)│ └──────────┘ └──────────┘
└─────────────┘
       │
       ↓
┌─────────────┐
│ ML Model    │
│ (Logistic   │
│  Regression)│
└─────────────┘
```

### Technology Stack

- **ML**: scikit-learn, pandas, numpy
- **API**: FastAPI, Uvicorn
- **Containerization**: Docker
- **Orchestration**: Kubernetes (Minikube)
- **Package Management**: Helm
- **Monitoring**: Prometheus, Grafana
- **CI/CD**: GitHub Actions
- **Reverse Proxy**: NGINX

---

## 🚀 Deployment

### Option 1: Automated Deployment (Recommended)

```bash
cd Assignment/monitoring
./setup-complete-monitoring.sh
```

This script:
1. Checks prerequisites
2. Rebuilds Docker image with monitoring
3. Deploys Prometheus and Grafana
4. Upgrades API deployment
5. Verifies everything is working

### Option 2: Manual Deployment

#### Step 1: Start Minikube

```bash
minikube start --driver=docker --cpus=2 --memory=4096
minikube addons enable ingress
```

#### Step 2: Build Docker Image

```bash
cd Assignment
eval $(minikube docker-env)
docker build -t heart-disease-api:latest .
```

#### Step 3: Deploy with Helm

```bash
cd helm-charts
helm upgrade --install heart-disease-api ./heart-disease-api \
  --namespace mlops \
  --create-namespace \
  --set image.pullPolicy=Never \
  --set image.tag=latest
```

#### Step 4: Deploy Monitoring

```bash
cd ../monitoring
kubectl apply -f prometheus-deployment.yaml
kubectl apply -f grafana-deployment.yaml
```

#### Step 5: Verify Deployment

```bash
kubectl get pods -n mlops
kubectl get svc -n mlops
```

### Fixed Port Assignments

All services use fixed ports for consistency:

| Service | NodePort | Internal Port |
|---------|----------|---------------|
| API | 30080 | 8000 |
| Prometheus | 30090 | 9090 |
| Grafana | 30030 | 3000 |

---

## 📊 Monitoring

### Prometheus Metrics

The API exposes these metrics at `/metrics`:

- `api_requests_total` - Total API requests by endpoint and status
- `api_request_duration_seconds` - Request latency histogram
- `predictions_total` - Total predictions by result
- `prediction_duration_seconds` - Prediction latency
- `prediction_confidence_score` - Confidence score distribution
- `active_requests` - Current active requests
- `model_loaded` - Model health status
- `api_errors_total` - Error count by type

### Grafana Dashboard

Pre-configured dashboard with 11 panels:
1. Total API Requests (graph)
2. Request Duration p95 (graph)
3. Predictions by Result (pie chart)
4. Prediction Latency (graph)
5. Confidence Distribution (heatmap)
6. Total Predictions (stat)
7. Total Errors (stat)
8. Model Status (stat)
9. Success Rate (gauge)
10. Active Requests (graph)
11. Error Rate (graph)

**Import Dashboard:**
1. Access Grafana: http://\<server-ip\>:3000
2. Login: admin/admin
3. Click "+" → "Import"
4. Upload `monitoring/grafana-dashboard.json`
5. Select Prometheus datasource

### Generate Test Traffic

```bash
cd monitoring
./test-metrics.sh
```

---

## 🔌 API Usage

### Health Check

```bash
curl http://<server-ip>/health

# Response:
# {
#   "status": "healthy",
#   "model_loaded": true,
#   "model_name": "logistic_regression"
# }
```

### Single Prediction

```bash
curl -X POST http://<server-ip>/predict \
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

# Response:
# {
#   "prediction": 1,
#   "confidence": 0.85,
#   "model_name": "logistic_regression"
# }
```

### Batch Prediction

```bash
curl -X POST http://<server-ip>/predict/batch \
  -H "Content-Type: application/json" \
  -d @sample_batch_input.json
```

### API Documentation

Interactive API docs available at:
- **Swagger UI**: http://\<server-ip\>/docs
- **ReDoc**: http://\<server-ip\>/redoc

---

## 🧪 Testing

### Run Unit Tests

```bash
cd Assignment
pytest tests/ -v
```

Unit tests run automatically in CI/CD.

### Run Integration Tests

Requires running API server:

```bash
# Terminal 1: Start API
uvicorn api_server:app --host 0.0.0.0 --port 8000

# Terminal 2: Run tests
./run_integration_tests.sh
```

### Test CI/CD Locally

```bash
cd Assignment
./test_ci_locally.sh
```

This simulates the entire CI/CD pipeline locally.

---

## 🌐 Remote Access

### Problem
Minikube IP (192.168.49.2) is internal and not accessible from remote machines.

### Solution: NGINX Reverse Proxy

```bash
cd Assignment
./setup-nginx-proxy.sh
```

This script:
1. Installs NGINX
2. Configures reverse proxy to Minikube services
3. Opens firewall ports
4. Starts NGINX

**After setup, access from anywhere:**
- API: http://\<almalinux-server-ip\>/
- Prometheus: http://\<almalinux-server-ip\>:9090
- Grafana: http://\<almalinux-server-ip\>:3000

---

## 🔧 Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n mlops

# Describe pod for details
kubectl describe pod <pod-name> -n mlops

# Check logs
kubectl logs -n mlops <pod-name>
```

### Cannot Access Services

```bash
# Check services
kubectl get svc -n mlops

# Verify firewall
sudo firewall-cmd --list-ports

# Check NGINX status (if using reverse proxy)
sudo systemctl status nginx
sudo tail -f /var/log/nginx/error.log
```

### Docker Build Fails

```bash
# Ensure using Minikube's Docker
eval $(minikube docker-env)
docker info | grep Name  # Should show "minikube"

# Build with no cache
docker build --no-cache -t heart-disease-api:latest .
```

### Integration Tests Failing

Integration tests require running API server. They are automatically skipped if server is not available.

```bash
# Start API first
uvicorn api_server:app --host 0.0.0.0 --port 8000

# Then run tests
python integration_tests/test_api.py
```

### CI/CD Failing

Check the GitHub Actions log for specific errors:
1. Go to GitHub repository
2. Click "Actions" tab
3. Click on failing workflow
4. Review error logs

Common issues:
- Import errors → Check PYTHONPATH
- Collection errors → Ensure pytest finds correct tests
- Integration test errors → Should be skipped automatically

---

## 📁 Project Structure

```
Assignment/
├── MLOps_Assignment.py          # Core ML pipeline
├── api_server.py                # FastAPI server
├── ci_train.py                  # CI/CD training script
├── Dockerfile                   # Container image
├── requirements.txt             # Python dependencies
├── requirements-dev.txt         # Dev dependencies
│
├── tests/                       # Unit tests
│   ├── test_models.py
│   └── test_data_pipeline.py
│
├── integration_tests/           # Integration tests
│   ├── test_api.py
│   └── conftest.py
│
├── helm-charts/                 # Kubernetes deployment
│   └── heart-disease-api/
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── values-dev.yaml
│       └── templates/
│
├── monitoring/                  # Monitoring stack
│   ├── prometheus-config.yaml
│   ├── prometheus-deployment.yaml
│   ├── grafana-deployment.yaml
│   ├── grafana-dashboard.json
│   ├── setup-complete-monitoring.sh
│   ├── deploy-monitoring.sh
│   ├── test-metrics.sh
│   └── README.md
│
├── data/                        # Training data
├── artifacts/                   # Model artifacts
├── mlruns/                      # MLflow tracking
│
├── setup-nginx-proxy.sh         # Remote access setup
├── run_integration_tests.sh     # Integration test runner
├── test_ci_locally.sh           # Local CI/CD simulator
└── README.md                    # This file
```

---

## 📚 Additional Resources

### Configuration Files
- `pytest.ini` - Test configuration
- `Dockerfile` - Container build instructions
- `.dockerignore` - Docker build exclusions
- `.github/workflows/ci.yml` - CI/CD pipeline

### Sample Files
- `sample_input.json` - Single prediction example
- `sample_batch_input.json` - Batch prediction example

### Scripts
- `run_docker.sh` - Docker container management
- `helm-charts/deploy.sh` - Helm deployment
- `helm-charts/cleanup.sh` - Remove deployment
- `monitoring/cleanup-monitoring.sh` - Remove monitoring

---

## 🔄 Update Workflow

When code changes:

```bash
# 1. Pull latest code
git pull origin main

# 2. Rebuild Docker image
eval $(minikube docker-env)
docker build -t heart-disease-api:latest .

# 3. Restart deployment
kubectl rollout restart deployment/heart-disease-api -n mlops

# 4. Verify
kubectl rollout status deployment/heart-disease-api -n mlops
curl http://$(minikube ip):30080/health
```

---

## 🎯 Production Checklist

Before going to production:

- [ ] Configure SSL/TLS for HTTPS
- [ ] Set up proper authentication
- [ ] Configure resource limits
- [ ] Enable horizontal pod autoscaling
- [ ] Set up proper logging
- [ ] Configure backup for persistent data
- [ ] Set up alerting rules in Prometheus
- [ ] Configure network policies
- [ ] Set up pod disruption budgets
- [ ] Use production values (values-prod.yaml)

---

## 📊 Metrics Summary

- **Endpoint**: `/metrics`
- **Format**: Prometheus exposition format
- **Scrape Interval**: 15 seconds
- **Retention**: 15 days (Prometheus default)

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes with tests
4. Run local CI/CD: `./test_ci_locally.sh`
5. Submit pull request

---

## 📄 License

This project is for educational purposes as part of BITS MLOps course.

---

## 🆘 Support

For issues or questions:
1. Check troubleshooting section above
2. Review GitHub Issues
3. Check CI/CD logs
4. Review Kubernetes logs: `kubectl logs -n mlops <pod-name>`

---

## 🎉 Quick Commands Reference

```bash
# Deployment
minikube start
./monitoring/setup-complete-monitoring.sh
./setup-nginx-proxy.sh

# Access
curl http://<ip>/health
open http://<ip>/docs

# Monitoring
curl http://<ip>/metrics
open http://<ip>:9090          # Prometheus
open http://<ip>:3000          # Grafana

# Testing
pytest tests/
./run_integration_tests.sh
./test_ci_locally.sh

# Troubleshooting
kubectl get pods -n mlops
kubectl logs -n mlops <pod-name>
kubectl describe pod <pod-name> -n mlops

# Updates
git pull
eval $(minikube docker-env)
docker build -t heart-disease-api:latest .
kubectl rollout restart deployment/heart-disease-api -n mlops
```

---

**Ready to deploy? Start with the [Quick Start](#-quick-start) section!** 🚀
