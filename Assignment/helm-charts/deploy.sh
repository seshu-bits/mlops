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

    # Detect if we're on Alma Linux or similar RHEL-based system
    if [ -f /etc/almalinux-release ] || [ -f /etc/redhat-release ]; then
        print_warning "Detected RHEL-based system (Alma Linux/RHEL/CentOS)"
        
        # Check if we can use the Alma Linux native Dockerfile
        if [ -f "../Dockerfile.almalinux" ]; then
            echo "Using Alma Linux optimized Dockerfile..."
            cd ..
            
            # Try to build with Alma Linux Dockerfile directly
            if docker build -t $IMAGE_NAME -f Dockerfile.almalinux . 2>&1 | tee /tmp/docker-build.log; then
                print_success "Docker image built successfully using Alma Linux Dockerfile"
                cd helm-charts
                return 0
            else
                print_warning "Alma Linux Dockerfile failed, trying fallback methods..."
            fi
            cd helm-charts
        fi
    fi

    # Build the base image first (if not already present)
    echo "Checking for local Python base image..."
    if ! docker images | grep -q "local-python-base.*3.11"; then
        echo "Base image not found. Building local-python-base:3.11..."
        cd ..
        if [ -f "Dockerfile.base" ]; then
            echo "Attempting to build base image (this may take a while on first run)..."
            if docker build -t local-python-base:3.11 -f Dockerfile.base . 2>&1 | tee /tmp/base-build.log; then
                print_success "Base image built successfully"
            else
                print_error "Failed to build base image"
                echo "Error log saved to /tmp/base-build.log"
                print_warning "You may need to manually load a Python base image"
                print_warning "See Dockerfile.base and Dockerfile.almalinux for alternatives"
                exit 1
            fi
        else
            print_error "Dockerfile.base not found"
            exit 1
        fi
        cd helm-charts
    else
        print_success "Base image already exists"
    fi

    # Build the application image
    echo "Building Docker image: $IMAGE_NAME"
    cd ..
    if docker build -t $IMAGE_NAME . 2>&1 | tee /tmp/docker-build.log; then
        print_success "Docker image built successfully"
    else
        print_error "Failed to build Docker image"
        echo "Error log saved to /tmp/docker-build.log"
        echo ""
        print_warning "Troubleshooting tips for Alma Linux 8:"
        echo "  1. Check if base images are available: docker images"
        echo "  2. Try building with Alma-specific Dockerfile:"
        echo "     docker build -t $IMAGE_NAME -f Dockerfile.almalinux ."
        echo "  3. Check network connectivity: curl -I https://registry.access.redhat.com"
        echo "  4. For completely offline setup, pre-load required images"
        exit 1
    fi
    cd helm-charts

    # Verify image was built
    if docker images | grep -q "heart-disease-api"; then
        print_success "Docker image built successfully"
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
