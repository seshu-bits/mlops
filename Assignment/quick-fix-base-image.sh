#!/bin/bash

# Quick Fix Script - Pull Base Image for AlmaLinux 8
# Run this if setup-complete-monitoring.sh fails with "local-python-base:3.11 not found"

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              AlmaLinux 8 - Quick Base Image Fix               ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Ensure Minikube is running
if ! minikube status &> /dev/null; then
    echo "❌ Minikube is not running"
    echo "Starting Minikube..."
    minikube start --driver=docker --cpus=2 --memory=4096
fi

echo "✓ Minikube is running"
echo ""

# Configure Docker
echo "Configuring Docker to use Minikube's daemon..."
eval $(minikube docker-env)

# Show current images
echo ""
echo "Current base images in Minikube:"
docker images | grep -E "(python|almalinux|rocky)" | head -5 || echo "  (none found)"
echo ""

# Try to pull almalinux:8 (native for AlmaLinux systems)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Attempting to pull almalinux:8 (recommended for AlmaLinux)..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if docker pull almalinux:8; then
    echo ""
    echo "✅ SUCCESS! almalinux:8 pulled successfully"
    echo ""
    echo "Verification:"
    docker images almalinux:8
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✓ Base image ready!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Next steps:"
    echo "  1. Run: cd monitoring && ./setup-complete-monitoring.sh"
    echo "  OR"
    echo "  2. Run: ./smart-docker-build.sh"
    echo ""
    exit 0
else
    echo ""
    echo "⚠ Failed to pull almalinux:8 (offline or network issue?)"
    echo ""
    echo "Trying alternative: python:3.11-slim..."
    echo ""

    if docker pull python:3.11-slim; then
        echo ""
        echo "✅ SUCCESS! python:3.11-slim pulled successfully"
        echo ""
        echo "Verification:"
        docker images python:3.11-slim
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "✓ Base image ready!"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Next steps:"
        echo "  1. Run: cd monitoring && ./setup-complete-monitoring.sh"
        echo "  OR"
        echo "  2. Run: ./smart-docker-build.sh"
        echo ""
        exit 0
    else
        echo ""
        echo "╔════════════════════════════════════════════════════════════════════╗"
        echo "║                    ❌ OFFLINE SYSTEM DETECTED                      ║"
        echo "╚════════════════════════════════════════════════════════════════════╝"
        echo ""
        echo "Your system appears to be offline. Use the offline method:"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "OFFLINE SETUP - 3 STEPS"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Step 1: On a machine WITH internet, run:"
        echo "  docker pull python:3.11-slim"
        echo "  docker save python:3.11-slim -o python-3.11-slim.tar"
        echo ""
        echo "Step 2: Transfer python-3.11-slim.tar to this machine"
        echo ""
        echo "Step 3: Load the image on this machine:"
        echo "  eval \$(minikube docker-env)"
        echo "  docker load -i python-3.11-slim.tar"
        echo ""
        echo "Then re-run this script: ./quick-fix-base-image.sh"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "For detailed help, see: DOCKER_BUILD_TROUBLESHOOTING.md"
        echo ""
        exit 1
    fi
fi
