# 📊 Complete Guide: Logs and Metrics in Prometheus & Grafana

## 🎯 Overview

Your MLOps system is already instrumented with **Prometheus metrics**! The `api_server.py` automatically exposes metrics that Prometheus scrapes and Grafana visualizes.

---

## 📈 How It Works

```
┌──────────────┐    Scrapes     ┌────────────┐    Queries    ┌──────────┐
│  API Server  │──────/metrics─→│ Prometheus │←──────────────│ Grafana  │
│ (Port 8000)  │   every 10s    │(Port 9090) │   Visualize   │(Port 3000)│
└──────────────┘                └────────────┘               └──────────┘
       │
       └─→ Exposes Prometheus metrics at /metrics endpoint
```

---

## 🚀 Quick Start on AlmaLinux Server

### Step 1: Deploy Monitoring Stack

SSH to your AlmaLinux server and run:

```bash
cd /home/admin/mlops/Assignment/monitoring

# Automated complete setup
bash setup-complete-monitoring.sh
```

This will:
- Deploy Prometheus
- Deploy Grafana
- Configure Prometheus to scrape your API
- Import pre-built Grafana dashboard
- Set up Nginx reverse proxy

### Step 2: Access the Services

After deployment:

- **Prometheus**: http://72.163.219.91:9090
- **Grafana**: http://72.163.219.91:3000 (login: admin/admin)
- **API Metrics**: http://72.163.219.91:80/metrics

---

## 📊 Available Metrics (Already Instrumented!)

Your `api_server.py` automatically collects these metrics:

### 1. **Request Metrics**
- `api_requests_total{method, endpoint, status_code}` - Total API requests
- `api_request_duration_seconds{method, endpoint}` - Request latency
- `active_requests` - Current concurrent requests

### 2. **Prediction Metrics**
- `predictions_total{prediction_result, model_name}` - Total predictions made
- `prediction_duration_seconds{endpoint}` - Time to make predictions
- `prediction_confidence_score{prediction_result}` - Confidence distribution

### 3. **Model Health Metrics**
- `model_loaded` - Whether model is loaded (1=yes, 0=no)
- `model_info` - Model metadata (name, version, accuracy)

### 4. **Error Metrics**
- `api_errors_total{error_type, endpoint}` - Total errors by type

---

## 🔧 How Metrics Are Collected

### In api_server.py (Already Done!)

Your API server uses `prometheus_client` library:

```python
from prometheus_client import Counter, Gauge, Histogram, Info

# Example: Track predictions
prediction_count = Counter(
    "predictions_total", 
    "Total predictions", 
    ["prediction_result", "model_name"]
)

# When prediction happens:
prediction_count.labels(
    prediction_result=result, 
    model_name="random_forest"
).inc()
```

### Prometheus Scraping (Automatic)

Prometheus is configured to scrape your API every 10 seconds:

```yaml
scrape_configs:
  - job_name: 'heart-disease-api'
    metrics_path: '/metrics'
    scrape_interval: 10s
    static_configs:
      - targets: ['heart-disease-api:80']
```

---

## 📊 Viewing Metrics in Prometheus

### 1. Access Prometheus UI
```
http://72.163.219.91:9090
```

### 2. Check Scraping Status
Go to: **Status → Targets**
- Should show `heart-disease-api` as "UP"
- Shows last scrape time and duration

### 3. Query Metrics

Try these queries in Prometheus:

#### Total requests per minute
```promql
rate(api_requests_total[1m])
```

#### Average request duration
```promql
rate(api_request_duration_seconds_sum[5m]) / rate(api_request_duration_seconds_count[5m])
```

#### Prediction success rate
```promql
sum(rate(predictions_total{prediction_result="positive"}[5m])) / sum(rate(predictions_total[5m]))
```

#### 95th percentile latency
```promql
histogram_quantile(0.95, rate(api_request_duration_seconds_bucket[5m]))
```

#### Active requests right now
```promql
active_requests
```

---

## 🎨 Visualizing in Grafana

### 1. Login to Grafana
```
URL: http://72.163.219.91:3000
Username: admin
Password: admin
```

### 2. Import Dashboard (Automatic)

The `setup-complete-monitoring.sh` script automatically imports the dashboard!

**Manual import** (if needed):
1. Click "+" → "Import"
2. Upload: `/home/admin/mlops/Assignment/monitoring/grafana-dashboard.json`
3. Select Prometheus datasource
4. Click "Import"

### 3. Dashboard Features

Your pre-built dashboard includes:

- 📊 **Request Rate**: Requests per second over time
- ⏱️ **Latency**: P50, P95, P99 percentiles
- 🎯 **Predictions**: Total predictions and breakdown by result
- ❌ **Error Rate**: 4xx and 5xx errors
- 📈 **Confidence Scores**: Distribution histogram
- 🟢 **Model Health**: Is model loaded and healthy?
- 🔄 **Active Requests**: Current concurrent requests

---

## 🧪 Generate Test Traffic

To see metrics in action, generate some API traffic:

```bash
cd /home/admin/mlops/Assignment/monitoring
bash test-metrics.sh
```

This will:
- Send 50 API requests
- Include single and batch predictions
- Mix of success and error cases
- Immediately visible in Prometheus/Grafana

---

## 📝 Adding Custom Metrics

If you want to add more metrics to `api_server.py`:

### Counter (for counting events)
```python
from prometheus_client import Counter

my_counter = Counter('my_metric_total', 'Description', ['label1'])
my_counter.labels(label1='value').inc()  # Increment
```

### Gauge (for current values)
```python
from prometheus_client import Gauge

temperature = Gauge('temperature_celsius', 'Current temperature')
temperature.set(25.5)  # Set value
```

### Histogram (for distributions)
```python
from prometheus_client import Histogram

response_time = Histogram('response_time_seconds', 'Response time')
response_time.observe(0.5)  # Record observation
```

---

## 🔍 Troubleshooting

### Prometheus Not Seeing Metrics

**1. Check API is exposing metrics:**
```bash
curl http://72.163.219.91:80/metrics
```
Should return Prometheus format metrics.

**2. Check Prometheus targets:**
```
http://72.163.219.91:9090/targets
```
Should show `heart-disease-api` as "UP" with green status.

**3. Check Prometheus logs:**
```bash
kubectl logs -n mlops deployment/prometheus
```

**4. Restart Prometheus:**
```bash
kubectl rollout restart deployment/prometheus -n mlops
```

### Grafana Not Showing Data

**1. Check Prometheus datasource:**
- Go to Configuration → Data Sources
- Click on Prometheus
- URL should be: `http://prometheus:9090`
- Click "Save & Test" - should show green checkmark

**2. Check time range:**
- Top right corner: Make sure time range includes recent data
- Default is "Last 6 hours"

**3. Verify queries work in Prometheus first:**
- Copy query from Grafana panel
- Test in Prometheus UI at http://72.163.219.91:9090

### No Metrics Appearing

**1. Generate some traffic:**
```bash
# Simple test
curl http://72.163.219.91:80/health

# Generate load
cd /home/admin/mlops/Assignment/monitoring
bash test-metrics.sh
```

**2. Wait 10-15 seconds:**
Prometheus scrapes every 10 seconds, so new metrics take a moment.

**3. Check API is running:**
```bash
kubectl get pods -n mlops
kubectl logs -n mlops deployment/heart-disease-api
```

---

## 📚 Useful Prometheus Queries

### Request Rate
```promql
# Requests per second
rate(api_requests_total[1m])

# By endpoint
sum by (endpoint) (rate(api_requests_total[5m]))

# By status code
sum by (status_code) (rate(api_requests_total[5m]))
```

### Latency
```promql
# Average latency
rate(api_request_duration_seconds_sum[5m]) / rate(api_request_duration_seconds_count[5m])

# P95 latency
histogram_quantile(0.95, rate(api_request_duration_seconds_bucket[5m]))

# P99 latency
histogram_quantile(0.99, rate(api_request_duration_seconds_bucket[5m]))
```

### Error Rate
```promql
# 5xx errors per minute
sum(rate(api_requests_total{status_code=~"5.."}[1m]))

# Error percentage
sum(rate(api_requests_total{status_code=~"[45].."}[5m])) / sum(rate(api_requests_total[5m])) * 100
```

### Predictions
```promql
# Predictions per minute
rate(predictions_total[1m])

# Positive predictions
sum(rate(predictions_total{prediction_result="positive"}[5m]))

# Prediction success rate (if you have labels)
sum(rate(predictions_total{prediction_result="positive"}[5m])) / sum(rate(predictions_total[5m]))
```

### Model Health
```promql
# Is model loaded? (1=yes, 0=no)
model_loaded

# Prediction latency
rate(prediction_duration_seconds_sum[5m]) / rate(prediction_duration_seconds_count[5m])
```

---

## 🎯 Best Practices

### 1. **Use Labels Wisely**
```python
# Good: Bounded cardinality
prediction_count.labels(prediction_result="positive", model_name="rf").inc()

# Bad: Unbounded cardinality (creates too many time series)
# Don't use patient_id, request_id, etc. as labels
```

### 2. **Use Appropriate Metric Types**
- **Counter**: Cumulative values (requests, errors)
- **Gauge**: Point-in-time values (temperature, memory usage)
- **Histogram**: Distributions (latency, response size)

### 3. **Set Meaningful Buckets for Histograms**
```python
# Latency buckets in seconds
latency = Histogram(
    'request_duration_seconds',
    'Request duration',
    buckets=[0.01, 0.05, 0.1, 0.5, 1.0, 5.0, 10.0]
)
```

### 4. **Use Rates for Counters**
Always use `rate()` when querying counters:
```promql
# Good
rate(api_requests_total[5m])

# Bad (raw counter value is not meaningful)
api_requests_total
```

---

## 📊 Logs vs Metrics

### Logs (Not in Prometheus/Grafana)
Your application logs (from `logging` module) go to:
- **Container stdout/stderr**
- View with: `kubectl logs -n mlops deployment/heart-disease-api`
- For centralized logging, consider ELK Stack or Loki

### Metrics (In Prometheus/Grafana)
Prometheus collects **numeric time-series data**:
- Request counts, durations, rates
- NOT for detailed logs or individual events
- Great for dashboards, alerting, trends

---

## 🚀 Quick Command Reference

```bash
# Deploy monitoring
cd ~/mlops/Assignment/monitoring
bash setup-complete-monitoring.sh

# Generate test traffic
bash test-metrics.sh

# Check Prometheus targets
curl http://72.163.219.91:9090/targets

# Check API metrics endpoint
curl http://72.163.219.91:80/metrics

# View API logs
kubectl logs -n mlops deployment/heart-disease-api -f

# Restart services
kubectl rollout restart deployment/prometheus -n mlops
kubectl rollout restart deployment/grafana -n mlops
kubectl rollout restart deployment/heart-disease-api -n mlops

# Check service status
kubectl get pods -n mlops
kubectl get svc -n mlops
```

---

## 🎓 Next Steps

1. **Deploy monitoring stack** on AlmaLinux
2. **Generate test traffic** with test-metrics.sh
3. **Explore Grafana dashboard** at http://72.163.219.91:3000
4. **Learn PromQL** (Prometheus Query Language)
5. **Set up alerts** (Prometheus Alertmanager)
6. **Add custom metrics** to your application

---

## 📖 Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [PromQL Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Python prometheus_client](https://github.com/prometheus/client_python)

---

**Your metrics are already instrumented and ready to go! 🎉**

Just deploy the monitoring stack and start making API requests to see data flowing in!
