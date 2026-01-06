# 📊 Prometheus + Grafana Monitoring Integration

## Overview

This directory contains the complete monitoring setup for the Heart Disease Prediction API using Prometheus for metrics collection and Grafana for visualization.

## What's Included

### Enhanced API Server
- **Prometheus Metrics**: Integrated into `api_server.py`
  - Request counters (total requests by endpoint, method, status code)
  - Request duration histograms (latency tracking)
  - Prediction counters (by result: disease/no_disease)
  - Prediction latency histograms
  - Confidence score histograms
  - Error counters (by error type and endpoint)
  - Active requests gauge
  - Model status gauge
  - Model information metric

### Monitoring Components
1. **Prometheus** - Metrics collection and storage
2. **Grafana** - Metrics visualization
3. **Pre-configured Dashboard** - Ready-to-use monitoring dashboard

## Quick Start

### 1. Deploy Monitoring Stack

```bash
cd monitoring

# Make script executable
chmod +x deploy-monitoring.sh

# Deploy Prometheus and Grafana
./deploy-monitoring.sh
```

### 2. Rebuild and Redeploy API

```bash
# Navigate to project root
cd ..

# Point to Minikube Docker
eval $(minikube docker-env)

# Rebuild with new dependencies
docker build -t heart-disease-api:latest .

# Upgrade Helm release
cd helm-charts
helm upgrade heart-disease-api ./heart-disease-api \
  --namespace mlops \
  --set image.pullPolicy=Never

# Wait for rollout
kubectl rollout status deployment/heart-disease-api -n mlops
```

### 3. Access Grafana

```bash
# Get Minikube IP
MINIKUBE_IP=$(minikube ip)

# Get Grafana port
GRAFANA_PORT=$(kubectl get svc grafana -n mlops -o jsonpath='{.spec.ports[0].nodePort}')

echo "Grafana URL: http://$MINIKUBE_IP:$GRAFANA_PORT"

# Default credentials:
# Username: admin
# Password: admin
```

### 4. Import Dashboard

1. Login to Grafana
2. Click on "+" → "Import"
3. Upload `grafana-dashboard.json` or paste its content
4. Select "Prometheus" as the data source
5. Click "Import"

### 5. Generate Test Traffic

```bash
# Single prediction
curl -X POST http://$(minikube ip):30080/predict \
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

# Generate load for testing (install apache-bench if needed)
for i in {1..100}; do
  curl -X POST http://$(minikube ip):30080/predict \
    -H "Content-Type: application/json" \
    -d '{"age":63,"sex":1,"cp":3,"trestbps":145,"chol":233,"fbs":1,"restecg":0,"thalach":150,"exang":0,"oldpeak":2.3,"slope":0,"ca":0,"thal":1}' &
done
wait
```

## Architecture

```
┌─────────────────┐
│  API Requests   │
└────────┬────────┘
         │
         v
┌─────────────────┐     /metrics      ┌──────────────┐
│  Heart Disease  │ ◄─────────────────┤  Prometheus  │
│      API        │                    │   (scrape)   │
│   (FastAPI)     │                    └──────┬───────┘
└─────────────────┘                           │
                                              │ query
                                              v
                                    ┌──────────────────┐
                                    │     Grafana      │
                                    │  (visualization) │
                                    └──────────────────┘
```

## Available Metrics

### Request Metrics
- `api_requests_total` - Counter of all API requests
- `api_request_duration_seconds` - Histogram of request durations
- `active_requests` - Gauge of currently processing requests

### Prediction Metrics
- `predictions_total` - Counter of predictions by result (disease/no_disease)
- `prediction_duration_seconds` - Histogram of prediction processing time
- `prediction_confidence_score` - Histogram of confidence scores

### Error Metrics
- `api_errors_total` - Counter of errors by type and endpoint

### Model Metrics
- `model_loaded` - Gauge indicating if model is loaded (1 = loaded, 0 = not loaded)
- `model_info` - Info metric with model details

## Dashboard Panels

The pre-configured Grafana dashboard includes:

1. **Total API Requests** - Request rate over time
2. **Request Duration (95th Percentile)** - API latency
3. **Predictions by Result** - Disease vs. No Disease predictions
4. **Prediction Confidence Distribution** - Heatmap of confidence scores
5. **Active Requests** - Current load
6. **Error Rate** - Errors over time
7. **Model Status** - Model health indicator
8. **Prediction Latency** - p50, p95, p99 latencies
9. **Total Predictions** - Cumulative prediction count
10. **Total Errors** - Cumulative error count
11. **Success Rate** - Percentage of successful requests

## Configuration

### Prometheus Configuration

Edit `prometheus-config.yaml` to customize:
- Scrape intervals
- Retention periods
- Alert rules
- Target endpoints

### Grafana Configuration

Edit `grafana-deployment.yaml` to customize:
- Admin credentials (via environment variables)
- Resource limits
- Storage settings

## Remote Access

### Configure Firewall (AlmaLinux)

```bash
# Get NodePorts
PROMETHEUS_PORT=$(kubectl get svc prometheus -n mlops -o jsonpath='{.spec.ports[0].nodePort}')
GRAFANA_PORT=$(kubectl get svc grafana -n mlops -o jsonpath='{.spec.ports[0].nodePort}')

# Open ports
sudo firewall-cmd --permanent --add-port=${PROMETHEUS_PORT}/tcp
sudo firewall-cmd --permanent --add-port=${GRAFANA_PORT}/tcp
sudo firewall-cmd --reload
```

### Access from Remote Machine

```bash
# Get server IP
SERVER_IP=<your-almalinux-ip>

# Access Prometheus
curl http://$SERVER_IP:30090

# Access Grafana
# Open in browser: http://$SERVER_IP:30030
```

## Verification

### Check Metrics Endpoint

```bash
# From within cluster
kubectl port-forward -n mlops svc/heart-disease-api 8080:80 &
curl http://localhost:8080/metrics

# You should see output like:
# api_requests_total{endpoint="/predict",method="POST",status_code="200"} 42.0
# prediction_duration_seconds_bucket{endpoint="/predict",le="0.1"} 35.0
```

### Check Prometheus Targets

```bash
# Access Prometheus UI
MINIKUBE_IP=$(minikube ip)
PROMETHEUS_PORT=$(kubectl get svc prometheus -n mlops -o jsonpath='{.spec.ports[0].nodePort}')

echo "Open: http://$MINIKUBE_IP:$PROMETHEUS_PORT/targets"
```

The `heart-disease-api` target should show as "UP".

### Test Queries in Prometheus

Try these PromQL queries in Prometheus UI:

```promql
# Request rate
rate(api_requests_total[5m])

# Average prediction latency
rate(prediction_duration_seconds_sum[5m]) / rate(prediction_duration_seconds_count[5m])

# Error rate
rate(api_errors_total[5m])

# Success rate percentage
sum(rate(api_requests_total{status_code=~"2.."}[5m])) / sum(rate(api_requests_total[5m])) * 100
```

## Troubleshooting

### Prometheus Not Scraping Metrics

```bash
# Check Prometheus logs
kubectl logs -n mlops -l app=prometheus

# Check if service is reachable
kubectl exec -n mlops -it deployment/prometheus -- \
  wget -O- http://heart-disease-api:80/metrics

# Verify service endpoints
kubectl get endpoints -n mlops heart-disease-api
```

### Grafana Can't Connect to Prometheus

```bash
# Check Grafana logs
kubectl logs -n mlops -l app=grafana

# Verify datasource configuration
kubectl get configmap grafana-datasources -n mlops -o yaml

# Test connection from Grafana pod
kubectl exec -n mlops -it deployment/grafana -- \
  wget -O- http://prometheus:9090/-/healthy
```

### No Metrics Appearing

```bash
# Verify API is exposing metrics
curl http://$(minikube ip):30080/metrics

# Check if prometheus-client is installed
kubectl exec -n mlops -it deployment/heart-disease-api -- \
  python -c "import prometheus_client; print('OK')"

# Force a request to generate metrics
curl http://$(minikube ip):30080/health
```

### Dashboard Shows No Data

1. Check time range in Grafana (top-right corner)
2. Verify Prometheus is receiving data (check Prometheus UI)
3. Make some API requests to generate metrics
4. Refresh the dashboard

## Advanced Configuration

### Enable Alert Manager

Add alerting rules to `prometheus-config.yaml`:

```yaml
rule_files:
  - "alerts.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']
```

### Add More Metrics

In `api_server.py`, add custom metrics:

```python
from prometheus_client import Summary

# Example: Track specific feature distributions
age_distribution = Histogram(
    'patient_age_distribution',
    'Distribution of patient ages',
    buckets=[20, 30, 40, 50, 60, 70, 80, 90, 100]
)

# In predict function:
age_distribution.observe(patient.age)
```

### Persistent Storage

Modify deployments to use PersistentVolumeClaims:

```yaml
volumes:
  - name: prometheus-storage
    persistentVolumeClaim:
      claimName: prometheus-pvc
```

## Cleanup

```bash
# Remove monitoring stack
./cleanup-monitoring.sh

# Or manually:
kubectl delete -f grafana-deployment.yaml
kubectl delete -f prometheus-deployment.yaml
kubectl delete -f prometheus-config.yaml
```

## Resources

- **Prometheus**: https://prometheus.io/docs/
- **Grafana**: https://grafana.com/docs/
- **prometheus-client Python**: https://github.com/prometheus/client_python
- **PromQL**: https://prometheus.io/docs/prometheus/latest/querying/basics/

## Next Steps

1. **Set up alerting** - Configure alerts for high error rates, latency spikes
2. **Add more dashboards** - Create dashboards for business metrics
3. **Integrate with other tools** - Connect to Slack, PagerDuty, etc.
4. **Enable authentication** - Secure Grafana with OAuth or LDAP
5. **Set up long-term storage** - Use Thanos or Cortex for metrics retention

---

## Summary

You now have a complete monitoring solution with:
- ✅ Prometheus collecting metrics from your API
- ✅ Grafana visualizing metrics in real-time
- ✅ Pre-configured dashboard showing key metrics
- ✅ Request tracking (rate, duration, status)
- ✅ Prediction tracking (results, confidence, latency)
- ✅ Error tracking and alerting capabilities
- ✅ Model health monitoring

The monitoring stack automatically tracks all API requests and provides insights into:
- API performance and availability
- Prediction patterns and accuracy
- Error rates and types
- Resource utilization
- Model health status
