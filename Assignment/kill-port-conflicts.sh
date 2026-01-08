#!/bin/bash

# Aggressive Port Cleanup Script for Nginx Deployment
# Use this if ports are persistently blocked

set +e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          Aggressive Port Cleanup for Nginx                    ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}\n"

PORTS=(80 3000 5000 9090)

echo "Checking which ports are in use..."
echo "===================================="
for PORT in "${PORTS[@]}"; do
    echo -e "\n${YELLOW}Port $PORT:${NC}"
    if sudo lsof -i :$PORT > /dev/null 2>&1; then
        echo -e "${RED}✗ IN USE${NC}"
        sudo lsof -i :$PORT
    else
        echo -e "${GREEN}✓ Free${NC}"
    fi
done

echo ""
echo "===================================="
read -p "Kill all processes using these ports? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "Killing processes..."
echo "===================================="

# Method 1: lsof + kill
for PORT in "${PORTS[@]}"; do
    echo -n "Port $PORT: "
    if sudo lsof -ti :$PORT > /dev/null 2>&1; then
        sudo lsof -ti :$PORT | xargs -r sudo kill -9 2>/dev/null
        echo -e "${GREEN}Killed${NC}"
    else
        echo -e "${GREEN}Already free${NC}"
    fi
done

sleep 2

# Method 2: fuser (more aggressive)
echo ""
echo "Running fuser cleanup..."
for PORT in "${PORTS[@]}"; do
    sudo fuser -k $PORT/tcp 2>/dev/null || true
done

sleep 2

# Method 3: Kill all Nginx processes
echo ""
echo "Killing all Nginx processes..."
sudo pkill -9 nginx 2>/dev/null || true
sudo systemctl stop nginx 2>/dev/null || true

# Method 4: Clean up PID files
echo "Cleaning up PID files..."
sudo rm -f /run/nginx.pid /var/run/nginx.pid 2>/dev/null || true

sleep 2

echo ""
echo "===================================="
echo "Verification:"
echo "===================================="
STILL_BLOCKED=false
for PORT in "${PORTS[@]}"; do
    echo -n "Port $PORT: "
    if sudo lsof -i :$PORT > /dev/null 2>&1; then
        echo -e "${RED}✗ STILL IN USE${NC}"
        sudo lsof -i :$PORT | tail -1
        STILL_BLOCKED=true
    else
        echo -e "${GREEN}✓ Free${NC}"
    fi
done

echo ""
if [ "$STILL_BLOCKED" = true ]; then
    echo -e "${RED}⚠ Some ports are still blocked!${NC}"
    echo ""
    echo "Try these manual steps:"
    echo ""
    echo "1. Check what's using the ports:"
    echo "   sudo ss -tlnp | grep -E ':(80|3000|5000|9090)'"
    echo ""
    echo "2. Find the process IDs:"
    echo "   sudo lsof -i :3000"
    echo ""
    echo "3. Kill specific process:"
    echo "   sudo kill -9 <PID>"
    echo ""
    echo "4. Check for Docker containers:"
    echo "   docker ps"
    echo "   docker stop <container>"
    echo ""
    echo "5. Check for previous Minikube services:"
    echo "   kubectl get svc -A"
    echo "   minikube service list"
    echo ""
    exit 1
else
    echo -e "${GREEN}✓ All ports successfully freed!${NC}"
    echo ""
    echo "You can now run:"
    echo "  bash fix-nginx-startup.sh"
    echo "  or"
    echo "  bash deploy-complete-almalinux.sh"
    echo ""
fi
