#!/bin/bash

# Quick Fix for AlmaLinux 8 - Base Image Setup
# This script helps set up the required base image for Docker builds

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     AlmaLinux 8 - Docker Base Image Quick Setup               ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Ensure we're using Minikube's Docker daemon
echo "Configuring Docker to use Minikube's daemon..."
eval $(minikube docker-env)

echo ""
echo "Current available images in Minikube:"
docker images --format "  • {{.Repository}}:{{.Tag}} ({{.Size}})" | head -10

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Choose your setup method:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Pull almalinux:8 (requires internet, best for AlmaLinux systems)"
echo "2. Pull python:3.11-slim (requires internet, smaller and faster)"
echo "3. Load from file (offline method)"
echo "4. Check current status and exit"
echo ""
read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        echo ""
        echo "Pulling almalinux:8..."
        docker pull almalinux:8
        echo "✓ Successfully pulled almalinux:8"
        echo ""
        echo "Now you can build using Dockerfile.almalinux:"
        echo "  docker build -t heart-disease-api:latest -f Dockerfile.almalinux ."
        echo ""
        echo "Or run the monitoring setup:"
        echo "  cd monitoring && ./setup-complete-monitoring.sh"
        ;;
    2)
        echo ""
        echo "Pulling python:3.11-slim..."
        docker pull python:3.11-slim
        echo "✓ Successfully pulled python:3.11-slim"
        echo ""
        echo "Now you can build using Dockerfile.offline:"
        echo "  docker build -t heart-disease-api:latest -f Dockerfile.offline ."
        echo ""
        echo "Or run the monitoring setup:"
        echo "  cd monitoring && ./setup-complete-monitoring.sh"
        ;;
    3)
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "OFFLINE METHOD - Instructions"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Step 1: On a machine WITH internet access, run:"
        echo "  docker pull python:3.11-slim"
        echo "  docker save python:3.11-slim -o python-3.11-slim.tar"
        echo ""
        echo "Step 2: Transfer the .tar file to this machine"
        echo ""
        echo "Step 3: Load the image:"
        read -p "Enter the path to the .tar file: " tarfile
        if [ -f "$tarfile" ]; then
            echo "Loading image from $tarfile..."
            docker load -i "$tarfile"
            echo "✓ Image loaded successfully"
            docker images python:3.11-slim
            echo ""
            echo "Now you can build using Dockerfile.offline:"
            echo "  docker build -t heart-disease-api:latest -f Dockerfile.offline ."
        else
            echo "❌ File not found: $tarfile"
            exit 1
        fi
        ;;
    4)
        echo ""
        echo "Current Docker images in Minikube:"
        docker images
        echo ""

        # Check for required images
        if docker images | grep -q "python.*3.11"; then
            echo "✓ Python 3.11 base image found"
            echo "  → You can use Dockerfile.offline"
        fi

        if docker images | grep -q "almalinux.*8"; then
            echo "✓ AlmaLinux 8 base image found"
            echo "  → You can use Dockerfile.almalinux"
        fi

        if docker images | grep -q "local-python-base"; then
            echo "✓ Local Python base image found"
            echo "  → You can use standard Dockerfile"
        fi

        if ! docker images | grep -qE "(python.*3.11|almalinux.*8|local-python-base)"; then
            echo "⚠ No suitable base image found"
            echo "  → Run this script again and choose option 1 or 2"
        fi
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Setup complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
