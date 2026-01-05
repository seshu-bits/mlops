# Heart Disease Prediction API - Helm Chart

This Helm chart deploys the Heart Disease Prediction API on Kubernetes.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- Docker image built and available (either in Docker Hub or Minikube's local registry)

## Installation

### Using Minikube's Docker Daemon (Recommended for local development)

```bash
# 1. Configure shell to use Minikube's Docker daemon
eval $(minikube docker-env)

# 2. Build the image
cd ../
docker build -t heart-disease-api:latest .

# 3. Install the chart
helm install heart-disease-api ./heart-disease-api \
  --namespace mlops \
  --create-namespace \
  --set image.pullPolicy=Never
```

### Using Docker Hub

```bash
# 1. Update values.yaml with your Docker Hub username
# repository: yourusername/heart-disease-api

# 2. Install the chart
helm install heart-disease-api ./heart-disease-api \
  --namespace mlops \
  --create-namespace
```

## Configuration

The following table lists the configurable parameters of the chart and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of pod replicas | `2` |
| `image.repository` | Image repository | `heart-disease-api` |
| `image.pullPolicy` | Image pull policy | `Never` |
| `image.tag` | Image tag | `latest` |
| `service.type` | Service type | `NodePort` |
| `service.port` | Service port | `80` |
| `service.targetPort` | Container port | `8000` |
| `service.nodePort` | NodePort (if type is NodePort) | `30080` |
| `resources.limits.cpu` | CPU limit | `500m` |
| `resources.limits.memory` | Memory limit | `512Mi` |
| `resources.requests.cpu` | CPU request | `250m` |
| `resources.requests.memory` | Memory request | `256Mi` |
| `autoscaling.enabled` | Enable horizontal pod autoscaling | `false` |
| `ingress.enabled` | Enable ingress | `false` |

## Usage

### Accessing the API

After installation, get the service URL:

```bash
# Method 1: Minikube service
minikube service heart-disease-api -n mlops --url

# Method 2: Port forward
kubectl port-forward -n mlops service/heart-disease-api 8000:80
```

### Testing the API

```bash
# Health check
curl http://localhost:8000/health

# Make a prediction
curl -X POST "http://localhost:8000/predict" \
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
```

### Monitoring

```bash
# View logs
kubectl logs -f -n mlops -l app=heart-disease-api

# Check pod status
kubectl get pods -n mlops

# Describe pods
kubectl describe pod -n mlops -l app=heart-disease-api

# Get metrics (if metrics-server is enabled)
kubectl top pods -n mlops
```

## Customization

### Custom Values File

Create a custom values file:

```yaml
# custom-values.yaml
replicaCount: 3

image:
  repository: myregistry/heart-disease-api
  tag: "v1.0.0"
  pullPolicy: IfNotPresent

service:
  type: LoadBalancer

resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

Install with custom values:

```bash
helm install heart-disease-api ./heart-disease-api \
  -f custom-values.yaml \
  --namespace mlops \
  --create-namespace
```

### Command Line Overrides

```bash
helm install heart-disease-api ./heart-disease-api \
  --namespace mlops \
  --create-namespace \
  --set replicaCount=3 \
  --set image.tag=v1.0.0 \
  --set resources.limits.memory=1Gi
```

## Upgrade

```bash
# Upgrade with new values
helm upgrade heart-disease-api ./heart-disease-api \
  -f custom-values.yaml \
  --namespace mlops

# Upgrade with specific values
helm upgrade heart-disease-api ./heart-disease-api \
  --namespace mlops \
  --set image.tag=v2.0.0
```

## Rollback

```bash
# List revisions
helm history heart-disease-api -n mlops

# Rollback to previous version
helm rollback heart-disease-api -n mlops

# Rollback to specific revision
helm rollback heart-disease-api 1 -n mlops
```

## Uninstallation

```bash
# Uninstall the release
helm uninstall heart-disease-api -n mlops

# Delete the namespace (optional)
kubectl delete namespace mlops
```

## Troubleshooting

### ImagePullBackOff

If you see `ImagePullBackOff` error:

```bash
# Check pod events
kubectl describe pod -n mlops -l app=heart-disease-api

# Ensure image is built in Minikube's Docker daemon
eval $(minikube docker-env)
docker images | grep heart-disease-api

# Set imagePullPolicy to Never
helm upgrade heart-disease-api ./heart-disease-api \
  -n mlops \
  --set image.pullPolicy=Never
```

### CrashLoopBackOff

If pods are crashing:

```bash
# Check logs
kubectl logs -n mlops -l app=heart-disease-api

# Check if model file exists in the image
kubectl exec -it -n mlops $(kubectl get pod -n mlops -l app=heart-disease-api -o jsonpath='{.items[0].metadata.name}') -- ls -la /app/artifacts/
```

### Service Not Accessible

```bash
# Check service
kubectl get svc -n mlops

# Check endpoints
kubectl get endpoints -n mlops

# Test from within cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n mlops -- \
  curl http://heart-disease-api/health
```

## Advanced Features

### Enable Ingress

```yaml
# values.yaml
ingress:
  enabled: true
  className: nginx
  hosts:
    - host: heart-disease-api.local
      paths:
        - path: /
          pathType: Prefix
```

### Enable Autoscaling

```yaml
# values.yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
```

### Enable Persistence

```yaml
# values.yaml
persistence:
  enabled: true
  storageClass: "standard"
  size: 1Gi
  mountPath: /data
```

### Add Environment Variables

```yaml
# values.yaml
env:
  - name: LOG_LEVEL
    value: "DEBUG"
  - name: MODEL_PATH
    value: "/app/artifacts/logistic_regression.pkl"
```

## Chart Structure

```
heart-disease-api/
├── Chart.yaml              # Chart metadata
├── values.yaml            # Default configuration values
├── templates/
│   ├── _helpers.tpl       # Template helpers
│   ├── NOTES.txt         # Post-installation notes
│   ├── deployment.yaml   # Deployment manifest
│   ├── service.yaml      # Service manifest
│   ├── serviceaccount.yaml
│   ├── ingress.yaml      # Ingress manifest
│   ├── hpa.yaml          # HorizontalPodAutoscaler
│   ├── configmap.yaml    # ConfigMap
│   ├── secret.yaml       # Secret
│   ├── pvc.yaml          # PersistentVolumeClaim
│   ├── pdb.yaml          # PodDisruptionBudget
│   ├── networkpolicy.yaml
│   └── servicemonitor.yaml
└── .helmignore
```

## License

This chart is part of the MLOps Assignment project.
