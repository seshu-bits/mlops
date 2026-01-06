#!/bin/bash

# Remove Prometheus and Grafana monitoring stack

set -e

echo "=========================================="
echo "Removing Monitoring Stack"
echo "=========================================="
echo ""

echo "Removing Grafana..."
kubectl delete -f grafana-deployment.yaml --ignore-not-found=true
echo "✓ Grafana removed"
echo ""

echo "Removing Prometheus..."
kubectl delete -f prometheus-deployment.yaml --ignore-not-found=true
kubectl delete -f prometheus-config.yaml --ignore-not-found=true
echo "✓ Prometheus removed"
echo ""

echo "=========================================="
echo "Cleanup Complete!"
echo "=========================================="
