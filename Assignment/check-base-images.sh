#!/bin/bash
# Script to check available base images in Minikube/Docker

echo "=== Checking Available Base Images ==="
echo ""

# Configure to use Minikube's Docker if available
if command -v minikube &> /dev/null && minikube status &> /dev/null; then
    echo "Configuring for Minikube's Docker daemon..."
    eval $(minikube docker-env)
fi

echo "Available images in local Docker daemon:"
echo "========================================="
docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | head -20

echo ""
echo "Looking for suitable base images..."
echo "===================================="

# Check for common base images
for img in \
    "alpine:latest" "alpine:3.19" "alpine:3.18" \
    "busybox:latest" \
    "almalinux:8" "almalinux:9" \
    "rockylinux:8" "rockylinux:9" \
    "centos:7" "centos:8" \
    "registry.access.redhat.com/ubi8/ubi-minimal:8.9" \
    "scratch"
do
    if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${img}$"; then
        echo "✓ Found: $img"
    fi
done

echo ""
echo "Recommendation:"
echo "==============="
echo "If no suitable base image is found above, you have two options:"
echo ""
echo "1. Load a base image from a tar file:"
echo "   docker load -i /path/to/base-image.tar"
echo ""
echo "2. Use the Dockerfile.scratch which builds Python from source"
echo "   (requires build-essential tools in the environment)"
