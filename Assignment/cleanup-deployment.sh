#!/bin/bash

# Cleanup Script for MLOps Deployment
# Removes all deployed resources

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              MLOps Deployment Cleanup                          ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

echo -e "${YELLOW}This will remove:${NC}"
echo "  - All Kubernetes resources in mlops namespace"
echo "  - Helm releases"
echo "  - Minikube tunnel"
echo "  - Nginx configuration"
echo "  - (Optional) Minikube cluster"
echo ""

read -p "Are you sure you want to continue? (yes/no) " -r
echo
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

# Stop Minikube tunnel
echo -e "\n${BLUE}Stopping Minikube tunnel...${NC}"
pkill -f "minikube tunnel" || true
echo -e "${GREEN}✓ Tunnel stopped${NC}"

# Delete Helm releases
echo -e "\n${BLUE}Removing Helm releases...${NC}"
if helm list -n mlops | grep -q heart-disease-api; then
    helm uninstall heart-disease-api -n mlops || true
    echo -e "${GREEN}✓ Helm release removed${NC}"
else
    echo "No Helm releases found"
fi

# Delete namespace (this will delete all resources)
echo -e "\n${BLUE}Deleting mlops namespace...${NC}"
if kubectl get namespace mlops &> /dev/null; then
    kubectl delete namespace mlops --timeout=60s || true
    echo -e "${GREEN}✓ Namespace deleted${NC}"
else
    echo "Namespace not found"
fi

# Remove Nginx configuration
echo -e "\n${BLUE}Removing Nginx configuration...${NC}"
if [ -f /etc/nginx/conf.d/mlops-proxy.conf ]; then
    sudo rm -f /etc/nginx/conf.d/mlops-proxy.conf
    sudo systemctl reload nginx || true
    echo -e "${GREEN}✓ Nginx config removed${NC}"
else
    echo "Nginx config not found"
fi

# Optional: Delete Minikube
echo -e "\n${YELLOW}Do you want to delete the Minikube cluster? (yes/no)${NC}"
read -p "This will remove all Minikube data: " -r
echo
if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${BLUE}Deleting Minikube cluster...${NC}"
    minikube delete || true
    echo -e "${GREEN}✓ Minikube cluster deleted${NC}"
else
    echo "Minikube cluster preserved"
fi

# Optional: Clean Docker images
echo -e "\n${YELLOW}Do you want to remove Docker images? (yes/no)${NC}"
read -p "This will remove heart-disease-api images: " -r
echo
if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${BLUE}Removing Docker images...${NC}"
    docker rmi heart-disease-api:latest 2>/dev/null || true
    docker rmi local-python-base:3.11 2>/dev/null || true
    docker image prune -f || true
    echo -e "${GREEN}✓ Docker images removed${NC}"
else
    echo "Docker images preserved"
fi

# Clean temporary files
echo -e "\n${BLUE}Cleaning temporary files...${NC}"
rm -f /tmp/mlflow-deployment.yaml
rm -f /tmp/ingress-complete.yaml
rm -f /tmp/minikube-tunnel.log
echo -e "${GREEN}✓ Temporary files cleaned${NC}"

# Summary
echo -e "\n${GREEN}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    Cleanup Complete                            ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo "Cleanup completed successfully!"
echo ""
echo "To redeploy, run:"
echo "  ./deploy-complete-almalinux.sh"
echo ""
