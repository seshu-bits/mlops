#!/bin/bash

# Heart Disease API - Helm Deployment Script for Minikube
# This script automates the deployment process

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="mlops"
RELEASE_NAME="heart-disease-api"
CHART_PATH="./heart-disease-api"
IMAGE_NAME="heart-disease-api:latest"

# Functions
print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

check_prerequisites() {
    print_header "Checking Prerequisites"

    # Check if Minikube is running
    if ! minikube status &> /dev/null; then
        print_error "Minikube is not running. Please start Minikube first."
        echo "Run: minikube start --driver=docker --cpus=2 --memory=4096"
        exit 1
    fi
    print_success "Minikube is running"

    # Check if Helm is installed
    if ! command -v helm &> /dev/null; then
        print_error "Helm is not installed"
        exit 1
    fi
    print_success "Helm is installed"

    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        exit 1
    fi
    print_success "kubectl is installed"
}

build_docker_image() {
    print_header "Building Docker Image"

    # Configure Docker to use Minikube's daemon
    eval $(minikube docker-env)
    print_success "Configured to use Minikube's Docker daemon"

    # Check if Dockerfile exists
    if [ ! -f "../Dockerfile" ]; then
        print_error "Dockerfile not found in parent directory"
        exit 1
    fi

    echo "Checking available base images..."
    AVAILABLE_IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}" 2>/dev/null || echo "")
    
    # Strategy: Try different Dockerfiles in order of preference
    # 1. If python:3.11-slim exists, use Dockerfile.offline
    # 2. If almalinux:8 exists, use Dockerfile.almalinux
    # 3. If local-python-base:3.11 exists, use main Dockerfile
    # 4. Try to build base image from Dockerfile.base
    # 5. Give up and provide instructions

    cd ..
    BUILD_SUCCESS=false
    
    # Option 1: Check for python:3.11-slim (best for offline)
    if echo "$AVAILABLE_IMAGES" | grep -q "python:3.11-slim"; then
        print_success "Found python:3.11-slim - using Dockerfile.offline"
        if docker build -t $IMAGE_NAME -f Dockerfile.offline . 2>&1 | tee /tmp/docker-build.log; then
            print_success "Docker image built successfully using offline Dockerfile"
            BUILD_SUCCESS=true
        fi
    fi
    
    # Option 2: Check for almalinux:8
    if [ "$BUILD_SUCCESS" = false ] && echo "$AVAILABLE_IMAGES" | grep -q "almalinux:8"; then
        print_warning "Found almalinux:8 - trying Dockerfile.almalinux"
        if docker build -t $IMAGE_NAME -f Dockerfile.almalinux . 2>&1 | tee /tmp/docker-build.log; then
            print_success "Docker image built successfully using Alma Linux Dockerfile"
            BUILD_SUCCESS=true
        fi
    fi
    
    # Option 3: Check for local-python-base:3.11
    if [ "$BUILD_SUCCESS" = false ] && echo "$AVAILABLE_IMAGES" | grep -q "local-python-base:3.11"; then
        print_warning "Found local-python-base:3.11 - using standard Dockerfile"
        if docker build -t $IMAGE_NAME . 2>&1 | tee /tmp/docker-build.log; then
            print_success "Docker image built successfully"
            BUILD_SUCCESS=true
        fi
    fi
    
    # Option 4: Try to build base image
    if [ "$BUILD_SUCCESS" = false ]; then
        print_warning "No suitable base image found. Attempting to build local-python-base..."
        
        # Check if any base image is available that Dockerfile.base can use
        DOCKERFILE_BASE_OPTIONS=("registry.access.redhat.com/ubi8/ubi-minimal:8.9" "almalinux:8" "rockylinux:8" "centos:8")
        BASE_FOUND=false
        
        for base_img in "${DOCKERFILE_BASE_OPTIONS[@]}"; do
            if echo "$AVAILABLE_IMAGES" | grep -q "${base_img}"; then
                print_success "Found base image: $base_img"
                BASE_FOUND=true
                break
            fi
        done
        
        if [ "$BASE_FOUND" = true ] && [ -f "Dockerfile.base" ]; then
            if docker build -t local-python-base:3.11 -f Dockerfile.base . 2>&1 | tee /tmp/base-build.log; then
                print_success "Base image built successfully"
                # Now try building the main image
                if docker build -t $IMAGE_NAME . 2>&1 | tee /tmp/docker-build.log; then
                    print_success "Docker image built successfully"
                    BUILD_SUCCESS=true
                fi
            fi
        fi
    fi
    
    # If all options failed, provide clear instructions
    if [ "$BUILD_SUCCESS" = false ]; then
        cd helm-charts
        print_error "Failed to build Docker image - no suitable base image available"
        echo ""
        echo "╔════════════════════════════════════════════════════════════════════╗"
        echo "║          OFFLINE DEPLOYMENT INSTRUCTIONS                           ║"
        echo "╚════════════════════════════════════════════════════════════════════╝"
        echo ""
        echo "Your system appears to be offline with no suitable base images."
        echo ""
        echo "📦 SOLUTION: Load a base image manually"
        echo ""
        echo "On a machine WITH internet access:"
        echo "  docker pull python:3.11-slim"
        echo "  docker save python:3.11-slim -o python-3.11-slim.tar"
        echo ""
        echo "Transfer python-3.11-slim.tar to this server, then run:"
        echo "  eval \$(minikube docker-env)"
        echo "  docker load -i python-3.11-slim.tar"
        echo "  docker images  # Verify it loaded"
        echo ""
        echo "Then re-run this deploy script: ./deploy.sh"
        echo ""
        echo "Available images currently in your system:"
        docker images --format "  • {{.Repository}}:{{.Tag}} ({{.Size}})" | head -10
        echo ""
        exit 1
    fi
    
    cd helm-charts

    # Verify image was built
    if docker images | grep -q "heart-disease-api"; then
        print_success "Docker image built and verified"
    else
        print_error "Failed to build Docker image"
        exit 1
    fi
}

install_or_upgrade() {
    print_header "Installing/Upgrading Helm Release"

    # Check if release already exists
    if helm list -n $NAMESPACE | grep -q $RELEASE_NAME; then
        echo "Release $RELEASE_NAME already exists. Upgrading..."
        helm upgrade $RELEASE_NAME $CHART_PATH \
            --namespace $NAMESPACE \
            --set image.pullPolicy=Never \
            --wait \
            --timeout 5m
        print_success "Release upgraded successfully"
    else
        echo "Installing new release: $RELEASE_NAME"
        helm install $RELEASE_NAME $CHART_PATH \
            --namespace $NAMESPACE \
            --create-namespace \
            --set image.pullPolicy=Never \
            --wait \
            --timeout 5m
        print_success "Release installed successfully"
    fi
}

verify_deployment() {
    print_header "Verifying Deployment"

    # Wait for pods to be ready
    echo "Waiting for pods to be ready..."
    kubectl wait --for=condition=ready pod \
        -l app=heart-disease-api \
        -n $NAMESPACE \
        --timeout=300s

    print_success "Pods are ready"

    # Show pod status
    echo ""
    echo "Pod Status:"
    kubectl get pods -n $NAMESPACE -l app=heart-disease-api

    # Show service status
    echo ""
    echo "Service Status:"
    kubectl get svc -n $NAMESPACE
}

test_api() {
    print_header "Testing API"

    # Get service URL
    SERVICE_URL=$(minikube service $RELEASE_NAME -n $NAMESPACE --url)
    echo "Service URL: $SERVICE_URL"

    # Test health endpoint
    echo ""
    echo "Testing health endpoint..."
    if curl -s -f "$SERVICE_URL/health" > /dev/null; then
        print_success "Health endpoint is responding"
        curl -s "$SERVICE_URL/health" | jq '.' || curl -s "$SERVICE_URL/health"
    else
        print_warning "Health endpoint is not responding yet"
    fi
}

show_access_info() {
    print_header "Access Information"

    SERVICE_URL=$(minikube service $RELEASE_NAME -n $NAMESPACE --url)

    echo ""
    echo "API Endpoints:"
    echo "  • Health Check:   $SERVICE_URL/health"
    echo "  • API Docs:       $SERVICE_URL/docs"
    echo "  • ReDoc:          $SERVICE_URL/redoc"
    echo "  • Prediction:     $SERVICE_URL/predict"
    echo ""
    echo "Useful Commands:"
    echo "  • View logs:      kubectl logs -f -n $NAMESPACE -l app=heart-disease-api"
    echo "  • Get pods:       kubectl get pods -n $NAMESPACE"
    echo "  • Describe pod:   kubectl describe pod -n $NAMESPACE -l app=heart-disease-api"
    echo "  • Port forward:   kubectl port-forward -n $NAMESPACE service/$RELEASE_NAME 8000:80"
    echo "  • Open browser:   minikube service $RELEASE_NAME -n $NAMESPACE"
    echo ""
}

# Main execution
main() {
    print_header "Heart Disease API - Minikube Deployment"

    check_prerequisites
    build_docker_image
    install_or_upgrade
    verify_deployment
    test_api
    show_access_info

    print_header "Deployment Complete!"
    print_success "Your API is ready to use! 🚀"
}

# Run main function
main
