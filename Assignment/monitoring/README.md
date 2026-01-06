# 📊 Monitoring Stack - Prometheus + Grafana

Complete monitoring solution with Prometheus metrics collection and Grafana visualization.

---

## 🚀 Quick Setup

```bash
# Automated setup (recommended)
./setup-complete-monitoring.sh

# Manual setup
./deploy-monitoring.sh
```

---

## 📁 Files

- `setup-complete-monitoring.sh` - Complete automated setup
- `deploy-monitoring.sh` - Deploy monitoring stack only  
- `test-metrics.sh` - Generate test traffic
- `cleanup-monitoring.sh` - Remove monitoring stack
- `prometheus-config.yaml` - Prometheus configuration
- `prometheus-deployment.yaml` - Prometheus Kubernetes manifest
- `grafana-deployment.yaml` - Grafana Kubernetes manifest
- `grafana-dashboard.json` - Pre-configured dashboard

---

## 📊 Access

After deployment:

- **Prometheus**: http://\<server-ip\>:30090
- **Grafana**: http://\<server-ip\>:3000 (admin/admin)
- **API Metrics**: http://\<server-ip\>:30080/metrics

---

## 📈 Metrics Available

- `api_requests_total` - Total requests
- `api_request_duration_seconds` - Request latency
- `predictions_total` - Total predictions
- `prediction_duration_seconds` - Prediction latency
- `prediction_confidence_score` - Confidence scores
- `active_requests` - Current active requests
- `model_loaded` - Model health
- `api_errors_total` - Error count

---

## 🎨 Grafana Dashboard

Import the pre-configured dashboard:

1. Access Grafana: http://\<server-ip\>:3000
2. Login: admin/admin
3. Click "+" → "Import"
4. Upload `grafana-dashboard.json`
5. Select Prometheus datasource

Dashboard includes:
- API request rate and latency
- Prediction metrics
- Error rates
- Confidence distribution
- Model health status

---

## 🧪 Testing

Generate test traffic:

```bash
./test-metrics.sh
```

Then view metrics in Prometheus or Grafana dashboard.

---

## 🔧 Troubleshooting

### Prometheus Not Scraping

```bash
# Check Prometheus targets
open http://\<server-ip\>:30090/targets

# Check API metrics endpoint
curl http://\<minikube-ip\>:30080/metrics

# Restart Prometheus
kubectl rollout restart deployment/prometheus -n mlops
```

### Grafana Can't Connect to Prometheus

```bash
# Check datasource configuration
kubectl get configmap grafana-datasources -n mlops -o yaml

# Verify Prometheus service
kubectl get svc prometheus -n mlops

# Restart Grafana
kubectl rollout restart deployment/grafana -n mlops
```

---

For complete project documentation, see [../README.md](../README.md)
