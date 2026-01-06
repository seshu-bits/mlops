# 📊 Monitoring Integration - Complete Package

## Quick Links

| Document | Purpose | Use When |
|----------|---------|----------|
| [QUICKSTART.md](QUICKSTART.md) | 5-minute setup guide | First time setup |
| [README.md](README.md) | Complete documentation | Need detailed info |
| [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) | Technical overview | Understanding implementation |
| This file | Navigation & overview | Starting point |

## Quick Commands

```bash
# Complete automated setup (recommended)
./setup-complete-monitoring.sh

# Manual deployment (step-by-step control)
./deploy-monitoring.sh

# Generate test traffic
./test-metrics.sh

# Remove monitoring
./cleanup-monitoring.sh
```

## What's Included

### ✅ Enhanced API Server
- Prometheus metrics integration
- Automatic request tracking
- Prediction monitoring
- Error tracking
- Model health monitoring

### ✅ Monitoring Infrastructure
- **Prometheus** - Metrics collection (Port 30090)
- **Grafana** - Visualization (Port 30030)
- Pre-configured dashboard with 11 panels
- Kubernetes deployments (RBAC-enabled)

### ✅ Automation Scripts
- `setup-complete-monitoring.sh` - All-in-one setup
- `deploy-monitoring.sh` - Deploy monitoring stack
- `test-metrics.sh` - Generate traffic & test
- `cleanup-monitoring.sh` - Remove everything

### ✅ Documentation
- Complete setup guide
- Troubleshooting section
- PromQL query examples
- Architecture diagrams

## Metrics Tracked

| Category | Metrics | Description |
|----------|---------|-------------|
| **Requests** | `api_requests_total` | All API requests by endpoint, method, status |
| | `api_request_duration_seconds` | Request latency histogram |
| | `active_requests` | Current concurrent requests |
| **Predictions** | `predictions_total` | Predictions by result (disease/no_disease) |
| | `prediction_duration_seconds` | Prediction processing time |
| | `prediction_confidence_score` | Confidence score distribution |
| **Errors** | `api_errors_total` | Errors by type and endpoint |
| **Model** | `model_loaded` | Model status (1=loaded, 0=not) |
| | `model_info` | Model metadata |

## Dashboard Panels

1. **Total API Requests** - Request rate over time
2. **Request Duration (p95)** - API latency tracking
3. **Predictions by Result** - Disease vs No Disease
4. **Confidence Distribution** - Heatmap of scores
5. **Active Requests** - Current load
6. **Error Rate** - Errors over time
7. **Model Status** - Health indicator
8. **Prediction Latency** - p50, p95, p99
9. **Total Predictions** - Cumulative count
10. **Total Errors** - Error count with alerts
11. **Success Rate** - SLA compliance gauge

## File Structure

```
monitoring/
├── INDEX.md                          # This file - navigation
├── QUICKSTART.md                     # 5-minute setup guide
├── README.md                         # Complete documentation
├── IMPLEMENTATION_SUMMARY.md         # Technical details
│
├── setup-complete-monitoring.sh      # ⭐ All-in-one setup
├── deploy-monitoring.sh              # Deploy stack
├── test-metrics.sh                   # Test & generate traffic
├── cleanup-monitoring.sh             # Remove everything
│
├── prometheus-config.yaml            # Prometheus config
├── prometheus-deployment.yaml        # Prometheus K8s manifests
├── grafana-deployment.yaml           # Grafana K8s manifests
└── grafana-dashboard.json            # Pre-configured dashboard
```

## Getting Started (3 Options)

### Option 1: Automated Setup (Recommended)
```bash
cd monitoring
./setup-complete-monitoring.sh
```
**Time:** ~3 minutes  
**Result:** Everything deployed and configured

### Option 2: Manual Step-by-Step
Follow [QUICKSTART.md](QUICKSTART.md)  
**Time:** ~5 minutes  
**Result:** Full control over each step

### Option 3: Individual Components
```bash
# Just deploy monitoring
./deploy-monitoring.sh

# Rebuild API separately
cd .. && eval $(minikube docker-env)
docker build -t heart-disease-api:latest .
cd helm-charts
helm upgrade heart-disease-api ./heart-disease-api -n mlops
```
**Time:** Variable  
**Result:** Maximum flexibility

## Verification Checklist

After setup, verify these items:

- [ ] Prometheus is running: `kubectl get pods -n mlops -l app=prometheus`
- [ ] Grafana is running: `kubectl get pods -n mlops -l app=grafana`
- [ ] API is updated: `kubectl get pods -n mlops -l app.kubernetes.io/name=heart-disease-api`
- [ ] Metrics endpoint works: `curl http://$(minikube ip):30080/metrics`
- [ ] Prometheus is scraping: Open http://$(minikube ip):30090/targets
- [ ] Grafana connects: Login at http://$(minikube ip):30030
- [ ] Dashboard imported: See metrics flowing in Grafana
- [ ] Test traffic generated: Run `./test-metrics.sh`

## Common Tasks

### View Live Metrics
```bash
# Prometheus UI
open http://$(minikube ip):30090

# Grafana dashboard
open http://$(minikube ip):30030

# Raw metrics
curl http://$(minikube ip):30080/metrics
```

### Generate Test Load
```bash
# Quick test
./test-metrics.sh

# Custom load
for i in {1..100}; do
  curl -X POST http://$(minikube ip):30080/predict \
    -H "Content-Type: application/json" \
    -d '{"age":63,"sex":1,"cp":3,"trestbps":145,"chol":233,"fbs":1,"restecg":0,"thalach":150,"exang":0,"oldpeak":2.3,"slope":0,"ca":0,"thal":1}' &
done
wait
```

### Check Status
```bash
# All pods
kubectl get pods -n mlops

# Prometheus logs
kubectl logs -n mlops -l app=prometheus --tail=50

# Grafana logs
kubectl logs -n mlops -l app=grafana --tail=50

# API logs
kubectl logs -n mlops -l app.kubernetes.io/name=heart-disease-api --tail=50
```

### Troubleshoot
```bash
# Check Prometheus targets
open http://$(minikube ip):30090/targets

# Test metrics endpoint
curl http://$(minikube ip):30080/metrics | head -20

# Restart components
kubectl rollout restart deployment/prometheus -n mlops
kubectl rollout restart deployment/grafana -n mlops
kubectl rollout restart deployment/heart-disease-api -n mlops
```

## PromQL Query Examples

Try these in Prometheus UI (http://$(minikube ip):30090/graph):

```promql
# Request rate (requests per second)
rate(api_requests_total[5m])

# Average latency
rate(api_request_duration_seconds_sum[5m]) / rate(api_request_duration_seconds_count[5m])

# 95th percentile latency
histogram_quantile(0.95, rate(api_request_duration_seconds_bucket[5m]))

# Error rate
rate(api_errors_total[5m])

# Success rate (percentage)
sum(rate(api_requests_total{status_code=~"2.."}[5m])) / sum(rate(api_requests_total[5m])) * 100

# Predictions per second
rate(predictions_total[5m])

# Disease prediction rate
rate(predictions_total{prediction_result="disease"}[5m])

# Average confidence for disease predictions
rate(prediction_confidence_score_sum{prediction_result="disease"}[5m]) / rate(prediction_confidence_score_count{prediction_result="disease"}[5m])
```

## Remote Access (AlmaLinux)

### Get Ports
```bash
API_PORT=$(kubectl get svc heart-disease-api -n mlops -o jsonpath='{.spec.ports[0].nodePort}')
PROM_PORT=$(kubectl get svc prometheus -n mlops -o jsonpath='{.spec.ports[0].nodePort}')
GRAF_PORT=$(kubectl get svc grafana -n mlops -o jsonpath='{.spec.ports[0].nodePort}')

echo "API: $API_PORT"
echo "Prometheus: $PROM_PORT"
echo "Grafana: $GRAF_PORT"
```

### Configure Firewall
```bash
sudo firewall-cmd --permanent --add-port=$API_PORT/tcp
sudo firewall-cmd --permanent --add-port=$PROM_PORT/tcp
sudo firewall-cmd --permanent --add-port=$GRAF_PORT/tcp
sudo firewall-cmd --reload
```

### Access from Remote
```bash
SERVER_IP=<your-almalinux-ip>

# Access URLs
echo "API: http://$SERVER_IP:$API_PORT"
echo "Prometheus: http://$SERVER_IP:$PROM_PORT"
echo "Grafana: http://$SERVER_IP:$GRAF_PORT"
```

## Support & Troubleshooting

### Issue: Metrics endpoint returns 404
**Solution:** API not rebuilt with monitoring support
```bash
cd .. && eval $(minikube docker-env)
docker build -t heart-disease-api:latest .
cd helm-charts
helm upgrade heart-disease-api ./heart-disease-api -n mlops --set image.pullPolicy=Never
```

### Issue: Prometheus not scraping
**Solution:** Check targets and service
```bash
# Check targets (should show heart-disease-api as UP)
open http://$(minikube ip):30090/targets

# Verify service endpoints
kubectl get endpoints -n mlops heart-disease-api

# Test from Prometheus pod
kubectl exec -n mlops -it deployment/prometheus -- wget -O- http://heart-disease-api:80/metrics
```

### Issue: Grafana shows no data
**Solution:** Check connection and generate traffic
```bash
# Test Grafana can reach Prometheus
kubectl exec -n mlops -it deployment/grafana -- wget -O- http://prometheus:9090/-/healthy

# Generate traffic
./test-metrics.sh

# Check time range in Grafana (top-right corner)
```

### Issue: Dashboard not showing
**Solution:** Import manually
1. Access Grafana
2. Click "+" → "Import"
3. Upload `grafana-dashboard.json`
4. Select "Prometheus" datasource
5. Click "Import"

## Resources

- **Prometheus Docs:** https://prometheus.io/docs/
- **Grafana Docs:** https://grafana.com/docs/
- **prometheus-client:** https://github.com/prometheus/client_python
- **PromQL Guide:** https://prometheus.io/docs/prometheus/latest/querying/basics/

## Next Steps

1. ✅ Complete setup with `./setup-complete-monitoring.sh`
2. ✅ Import Grafana dashboard
3. ✅ Generate test traffic with `./test-metrics.sh`
4. ✅ Explore metrics in Prometheus and Grafana
5. 🔜 Set up alerting for critical metrics
6. 🔜 Create custom dashboards for your needs
7. 🔜 Configure persistent storage for metrics
8. 🔜 Integrate with external alerting (Slack, email)

## Summary

| Component | Status | Access |
|-----------|--------|--------|
| **API with Metrics** | ✅ Enhanced | Port 30080 |
| **Prometheus** | ✅ Ready | Port 30090 |
| **Grafana** | ✅ Ready | Port 30030 |
| **Dashboard** | ✅ Configured | Import JSON |
| **Documentation** | ✅ Complete | This directory |
| **Automation** | ✅ Ready | Shell scripts |

---

**Setup Time:** 3-5 minutes  
**Documentation:** Complete  
**Status:** Production Ready ✅

Start monitoring your API now with:
```bash
./setup-complete-monitoring.sh
```
