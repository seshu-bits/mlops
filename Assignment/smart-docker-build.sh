#!/bin/bash

# Smart Docker Build Script
# Automatically detects available base images and uses the appropriate Dockerfile

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║           Smart Docker Build - Base Image Detection           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Ensure we're using Minikube's Docker daemon
eval $(minikube docker-env) 2>/dev/null || true

# Get available images
echo "🔍 Checking available base images..."
AVAILABLE_IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}" 2>/dev/null || echo "")

# Display available images
echo ""
echo "Available images:"
docker images --format "  • {{.Repository}}:{{.Tag}} ({{.Size}})" | head -15
echo ""

BUILD_SUCCESS=false
DOCKERFILE_USED=""

# Strategy 1: Check for python:3.11-slim (best option)
if echo "$AVAILABLE_IMAGES" | grep -q "python:3.11-slim"; then
    echo "✓ Found python:3.11-slim"
    echo "  → Using Dockerfile.offline"
    if docker build -t heart-disease-api:latest -f Dockerfile.offline . 2>&1; then
        BUILD_SUCCESS=true
        DOCKERFILE_USED="Dockerfile.offline"
    fi
fi

# Strategy 2: Check for almalinux:8 (good for AlmaLinux systems)
if [ "$BUILD_SUCCESS" = false ] && echo "$AVAILABLE_IMAGES" | grep -q "almalinux:8"; then
    echo "✓ Found almalinux:8"
    echo "  → Using Dockerfile.almalinux"
    if docker build -t heart-disease-api:latest -f Dockerfile.almalinux . 2>&1; then
        BUILD_SUCCESS=true
        DOCKERFILE_USED="Dockerfile.almalinux"
    fi
fi

# Strategy 3: Check for rockylinux:8 (alternative RHEL-compatible)
if [ "$BUILD_SUCCESS" = false ] && echo "$AVAILABLE_IMAGES" | grep -q "rockylinux:8"; then
    echo "✓ Found rockylinux:8"
    echo "  → Building local base first..."
    if docker build -t local-python-base:3.11 -f Dockerfile.base . 2>&1; then
        echo "  → Using standard Dockerfile"
        if docker build -t heart-disease-api:latest . 2>&1; then
            BUILD_SUCCESS=true
            DOCKERFILE_USED="Dockerfile (with base built)"
        fi
    fi
fi

# Strategy 4: Check for local-python-base:3.11 (already built)
if [ "$BUILD_SUCCESS" = false ] && echo "$AVAILABLE_IMAGES" | grep -q "local-python-base:3.11"; then
    echo "✓ Found local-python-base:3.11"
    echo "  → Using standard Dockerfile"
    if docker build -t heart-disease-api:latest . 2>&1; then
        BUILD_SUCCESS=true
        DOCKERFILE_USED="Dockerfile"
    fi
fi

# Strategy 5: Try to pull python:3.11-slim (requires internet)
if [ "$BUILD_SUCCESS" = false ]; then
    echo "⚠ No suitable base image found. Attempting to pull python:3.11-slim..."
    if docker pull python:3.11-slim 2>&1; then
        echo "✓ Successfully pulled python:3.11-slim"
        echo "  → Using Dockerfile.offline"
        if docker build -t heart-disease-api:latest -f Dockerfile.offline . 2>&1; then
            BUILD_SUCCESS=true
            DOCKERFILE_USED="Dockerfile.offline"
        fi
    else
        echo "⚠ Unable to pull base image (offline or network issue)"
    fi
fi

# Strategy 6: Try to pull almalinux:8 (for AlmaLinux systems)
if [ "$BUILD_SUCCESS" = false ]; then
    echo "⚠ Attempting to pull almalinux:8..."
    if docker pull almalinux:8 2>&1; then
        echo "✓ Successfully pulled almalinux:8"
        echo "  → Using Dockerfile.almalinux"
        if docker build -t heart-disease-api:latest -f Dockerfile.almalinux . 2>&1; then
            BUILD_SUCCESS=true
            DOCKERFILE_USED="Dockerfile.almalinux"
        fi
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$BUILD_SUCCESS" = true ]; then
    echo "✅ BUILD SUCCESSFUL"
    echo "   Dockerfile used: $DOCKERFILE_USED"
    echo "   Image: heart-disease-api:latest"

    # Verify the image
    echo ""
    echo "📦 Image details:"
    docker images heart-disease-api:latest --format "   Size: {{.Size}}, Created: {{.CreatedSince}}"
    exit 0
else
    echo "❌ BUILD FAILED - NO SUITABLE BASE IMAGE"
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║                  MANUAL BASE IMAGE SETUP REQUIRED                  ║"
    echo "╚════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Your system needs a base Docker image. Choose ONE option below:"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "OPTION 1: Load from another machine (OFFLINE)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "On a machine WITH internet:"
    echo "  docker pull python:3.11-slim"
    echo "  docker save python:3.11-slim -o python-3.11-slim.tar"
    echo ""
    echo "Transfer python-3.11-slim.tar to this machine, then:"
    echo "  eval \$(minikube docker-env)"
    echo "  docker load -i python-3.11-slim.tar"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "OPTION 2: Pull directly (ONLINE - AlmaLinux compatible)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  eval \$(minikube docker-env)"
    echo "  docker pull almalinux:8"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "After loading a base image, re-run this script:"
    echo "  ./smart-docker-build.sh"
    echo ""
    exit 1
fi
