# 🚀 Quick Start: Prometheus + Grafana Monitoring

## Complete Setup in 5 Minutes

### Prerequisites
- Minikube running
- Heart Disease API deployed
- kubectl configured

---

## Step-by-Step Setup

### 1. Navigate to Monitoring Directory

```bash
cd /Users/saghanta/Personal/Docs/Education/Seshu/BITS/Courses/SEM\ 3/MLOps/mlops/Assignment/monitoring
```

### 2. Deploy Monitoring Stack

```bash
./deploy-monitoring.sh
```

**Expected output:**
```
✓ Namespace ready
✓ Prometheus deployed
✓ Prometheus is ready
✓ Grafana deployed
✓ Grafana is ready

Access URLs:
  Prometheus: http://<MINIKUBE_IP>:30090
  Grafana:    http://<MINIKUBE_IP>:30030

Grafana Credentials:
  Username: admin
  Password: admin
```

### 3. Rebuild API with Monitoring Support

```bash
# Go back to Assignment directory
cd ..

# Use Minikube's Docker
eval $(minikube docker-env)

# Rebuild image with new dependencies
docker build -t heart-disease-api:latest .

# Upgrade Helm deployment
cd helm-charts
helm upgrade heart-disease-api ./heart-disease-api \
  --namespace mlops \
  --set image.pullPolicy=Never

# Wait for rollout
kubectl rollout status deployment/heart-disease-api -n mlops
```

### 4. Verify Metrics Endpoint

```bash
# Test metrics endpoint
curl http://$(minikube ip):30080/metrics

# You should see Prometheus metrics like:
# api_requests_total{...} 1.0
# prediction_duration_seconds_bucket{...} 0.0
```

### 5. Access Grafana

```bash
# Get Grafana URL
echo "Grafana: http://$(minikube ip):30030"

# Open in browser and login
# Username: admin
# Password: admin
```

### 6. Import Dashboard

In Grafana:
1. Click "+" → "Import" (left sidebar)
2. Click "Upload JSON file"
3. Select `grafana-dashboard.json` from the monitoring directory
4. Select "Prometheus" as the data source
5. Click "Import"

### 7. Generate Test Traffic

```bash
cd ../monitoring
./test-metrics.sh
```

This will:
- Make health checks
- Send single and batch predictions
- Generate 50 test requests
- Display metrics summary

### 8. View Metrics

**Prometheus:**
```bash
open http://$(minikube ip):30090
```

Try these queries:
- `rate(api_requests_total[5m])` - Request rate
- `rate(predictions_total[5m])` - Prediction rate
- `histogram_quantile(0.95, rate(prediction_duration_seconds_bucket[5m]))` - 95th percentile latency

**Grafana:**
```bash
open http://$(minikube ip):30030
```

View the imported dashboard to see:
- Real-time API metrics
- Prediction statistics
- Latency percentiles
- Error rates
- Model health

---

## Quick Commands

```bash
# Check all monitoring pods
kubectl get pods -n mlops

# Check Prometheus status
kubectl logs -n mlops -l app=prometheus --tail=20

# Check Grafana status
kubectl logs -n mlops -l app=grafana --tail=20

# Generate more traffic
./test-metrics.sh

# Access Prometheus
open http://$(minikube ip):30090

# Access Grafana
open http://$(minikube ip):30030
```

---

## Remote Access (AlmaLinux)

### Configure Firewall

```bash
# Open Prometheus and Grafana ports
sudo firewall-cmd --permanent --add-port=30090/tcp
sudo firewall-cmd --permanent --add-port=30030/tcp
sudo firewall-cmd --reload
```

### Access from Remote

```bash
# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

# Access URLs
echo "Prometheus: http://$SERVER_IP:30090"
echo "Grafana:    http://$SERVER_IP:30030"
```

---

## Troubleshooting

### Metrics Not Showing?

```bash
# 1. Check if API is exposing metrics
curl http://$(minikube ip):30080/metrics

# 2. Check Prometheus targets
# Open: http://$(minikube ip):30090/targets
# heart-disease-api should show as "UP"

# 3. Restart Prometheus if needed
kubectl rollout restart deployment/prometheus -n mlops
```

### Grafana Can't Connect?

```bash
# 1. Check Grafana logs
kubectl logs -n mlops -l app=grafana --tail=50

# 2. Verify datasource
kubectl get configmap grafana-datasources -n mlops -o yaml

# 3. Restart Grafana
kubectl rollout restart deployment/grafana -n mlops
```

### No Data in Dashboard?

1. Check time range (top-right in Grafana)
2. Generate some traffic with `./test-metrics.sh`
3. Refresh the dashboard
4. Verify Prometheus is collecting data

---

## Cleanup

```bash
# Remove monitoring stack
./cleanup-monitoring.sh
```

---

## What Metrics Are Tracked?

### Request Metrics
- **api_requests_total**: Total requests by endpoint, method, status
- **api_request_duration_seconds**: Request latency histogram
- **active_requests**: Current active requests

### Prediction Metrics
- **predictions_total**: Total predictions by result (disease/no_disease)
- **prediction_duration_seconds**: Prediction processing time
- **prediction_confidence_score**: Confidence score distribution

### Error Metrics
- **api_errors_total**: Total errors by type and endpoint

### Model Metrics
- **model_loaded**: Model status (1=loaded, 0=not loaded)
- **model_info**: Model metadata

---

## Success Criteria

✅ Prometheus is running and scraping metrics
✅ Grafana is accessible and connected to Prometheus
✅ Dashboard shows real-time metrics
✅ Metrics are being collected from API
✅ Test traffic generates visible metrics

---

## Next Steps

1. **Set up Alerts** - Configure alerting for high error rates
2. **Custom Dashboards** - Create business-specific dashboards
3. **Long-term Storage** - Set up persistent storage for metrics
4. **Export Dashboards** - Share dashboards with team
5. **Integrate Alerting** - Connect to Slack, email, or PagerDuty

---

## Summary

You now have:
- ✅ Prometheus collecting metrics from your API
- ✅ Grafana visualizing metrics in real-time
- ✅ Pre-configured dashboard with 11 panels
- ✅ Automatic tracking of all requests and predictions
- ✅ Error monitoring and model health tracking
- ✅ Remote access capability

**Total setup time: ~5 minutes** ⚡
