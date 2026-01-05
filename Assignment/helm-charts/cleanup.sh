#!/bin/bash

# Cleanup script for Heart Disease API Kubernetes deployment

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

NAMESPACE="mlops"
RELEASE_NAME="heart-disease-api"

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

confirm_action() {
    echo -e "${YELLOW}WARNING: This will delete all resources in the $NAMESPACE namespace!${NC}"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Cleanup cancelled."
        exit 0
    fi
}

uninstall_helm_release() {
    print_header "Uninstalling Helm Release"
    
    if helm list -n $NAMESPACE | grep -q $RELEASE_NAME; then
        helm uninstall $RELEASE_NAME -n $NAMESPACE
        print_success "Helm release uninstalled"
    else
        print_warning "Helm release not found"
    fi
}

delete_namespace() {
    print_header "Deleting Namespace"
    
    if kubectl get namespace $NAMESPACE &> /dev/null; then
        kubectl delete namespace $NAMESPACE
        print_success "Namespace deleted"
    else
        print_warning "Namespace not found"
    fi
}

cleanup_docker_images() {
    print_header "Cleaning Up Docker Images"
    
    read -p "Do you want to remove Docker images? (yes/no): " remove_images
    if [ "$remove_images" = "yes" ]; then
        # Use Minikube's Docker daemon
        eval $(minikube docker-env)
        
        if docker images | grep -q "heart-disease-api"; then
            docker rmi heart-disease-api:latest -f
            print_success "Docker images removed"
        else
            print_warning "No Docker images found"
        fi
    else
        print_warning "Skipping Docker image cleanup"
    fi
}

verify_cleanup() {
    print_header "Verifying Cleanup"
    
    # Check Helm releases
    if helm list -n $NAMESPACE 2>/dev/null | grep -q $RELEASE_NAME; then
        print_error "Helm release still exists"
    else
        print_success "No Helm releases found"
    fi
    
    # Check namespace
    if kubectl get namespace $NAMESPACE &> /dev/null; then
        print_warning "Namespace still exists (may take time to terminate)"
    else
        print_success "Namespace deleted"
    fi
}

main() {
    print_header "Heart Disease API - Cleanup"
    
    confirm_action
    uninstall_helm_release
    delete_namespace
    cleanup_docker_images
    verify_cleanup
    
    print_header "Cleanup Complete!"
    print_success "All resources have been cleaned up! 🧹"
    
    echo ""
    echo "If you want to stop Minikube:"
    echo "  minikube stop"
    echo ""
    echo "If you want to delete Minikube cluster:"
    echo "  minikube delete"
}

main
