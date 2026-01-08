#!/bin/bash

# Pre-Deployment Nginx Check Script
# Run this before deploying to catch potential Nginx issues early

set +e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          Pre-Deployment Nginx Environment Check               ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}\n"

ISSUES=0
WARNINGS=0

# Function to check status
check_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}"
    else
        echo -e "${RED}✗ FAIL${NC}"
        ((ISSUES++))
    fi
}

warn_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ OK${NC}"
    else
        echo -e "${YELLOW}⚠ WARNING${NC}"
        ((WARNINGS++))
    fi
}

echo "1. Checking port availability..."
echo "--------------------------------"

for PORT in 80 3000 5000 9090; do
    echo -n "  Port $PORT: "
    if sudo lsof -i :$PORT > /dev/null 2>&1; then
        echo -e "${RED}✗ IN USE${NC}"
        echo "    Used by: $(sudo lsof -i :$PORT | tail -1 | awk '{print $1}')"
        ((ISSUES++))
    else
        echo -e "${GREEN}✓ Free${NC}"
    fi
done
echo ""

echo "2. Checking for conflicting services..."
echo "---------------------------------------"

echo -n "  Apache (httpd): "
if sudo systemctl is-active --quiet httpd; then
    echo -e "${RED}✗ RUNNING (will conflict)${NC}"
    ((ISSUES++))
else
    echo -e "${GREEN}✓ Not running${NC}"
fi

echo -n "  Existing Nginx: "
if pgrep nginx > /dev/null; then
    echo -e "${YELLOW}⚠ Running (will be restarted)${NC}"
    ((WARNINGS++))
else
    echo -e "${GREEN}✓ Not running${NC}"
fi
echo ""

echo "3. Checking required directories..."
echo "-----------------------------------"

for DIR in "/var/log/nginx" "/etc/nginx/conf.d" "/var/cache/nginx" "/var/lib/nginx"; do
    echo -n "  $DIR: "
    if [ -d "$DIR" ]; then
        echo -e "${GREEN}✓ Exists${NC}"
    else
        echo -e "${YELLOW}⚠ Missing (will be created)${NC}"
        ((WARNINGS++))
    fi
done
echo ""

echo "4. Checking SELinux status..."
echo "-----------------------------"

if command -v getenforce > /dev/null 2>&1; then
    SELINUX_STATUS=$(getenforce)
    echo "  Status: $SELINUX_STATUS"

    if [ "$SELINUX_STATUS" != "Disabled" ]; then
        echo -n "  httpd_can_network_connect: "
        if sudo getsebool httpd_can_network_connect | grep -q "on"; then
            echo -e "${GREEN}✓ Enabled${NC}"
        else
            echo -e "${YELLOW}⚠ Disabled (will be enabled)${NC}"
            ((WARNINGS++))
        fi

        echo "  Port labels:"
        for PORT in 3000 5000 9090; do
            echo -n "    Port $PORT: "
            if sudo semanage port -l 2>/dev/null | grep -q "http_port_t.*$PORT"; then
                echo -e "${GREEN}✓ Configured${NC}"
            else
                echo -e "${YELLOW}⚠ Not configured (will be added)${NC}"
                ((WARNINGS++))
            fi
        done
    fi
else
    echo -e "${YELLOW}  ⚠ getenforce not found (SELinux may not be installed)${NC}"
    ((WARNINGS++))
fi
echo ""

echo "5. Checking Nginx installation..."
echo "---------------------------------"

echo -n "  Nginx installed: "
if command -v nginx > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Yes${NC}"
    NGINX_VERSION=$(nginx -v 2>&1 | cut -d/ -f2)
    echo "  Version: $NGINX_VERSION"
else
    echo -e "${YELLOW}⚠ Not installed (will be installed)${NC}"
    ((WARNINGS++))
fi

if [ -f /etc/nginx/nginx.conf ]; then
    echo -n "  nginx.conf exists: "
    echo -e "${GREEN}✓ Yes${NC}"

    echo -n "  nginx.conf valid: "
    if sudo nginx -t > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Yes${NC}"
    else
        echo -e "${YELLOW}⚠ Has errors (will be recreated)${NC}"
        ((WARNINGS++))
    fi
else
    echo "  nginx.conf: Not present (will be created)"
fi
echo ""

echo "6. Checking firewall status..."
echo "------------------------------"

if command -v firewall-cmd > /dev/null 2>&1; then
    echo -n "  Firewall running: "
    if sudo firewall-cmd --state > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Yes${NC}"

        echo "  Required ports:"
        for PORT in 80 3000 5000 9090; do
            echo -n "    Port $PORT: "
            if sudo firewall-cmd --list-ports 2>/dev/null | grep -q "$PORT/tcp"; then
                echo -e "${GREEN}✓ Open${NC}"
            else
                echo -e "${YELLOW}⚠ Not open (will be opened)${NC}"
                ((WARNINGS++))
            fi
        done
    else
        echo -e "${YELLOW}⚠ Not running${NC}"
        ((WARNINGS++))
    fi
else
    echo -e "${YELLOW}  ⚠ firewalld not found${NC}"
    ((WARNINGS++))
fi
echo ""

echo "7. Checking Minikube status..."
echo "------------------------------"

echo -n "  Minikube installed: "
if command -v minikube > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Yes${NC}"

    echo -n "  Minikube running: "
    if minikube status > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Yes${NC}"
        MINIKUBE_IP=$(minikube ip 2>/dev/null)
        echo "  Minikube IP: $MINIKUBE_IP"

        echo -n "  Minikube reachable: "
        if curl -s -f http://$MINIKUBE_IP > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Yes${NC}"
        else
            echo -e "${YELLOW}⚠ Not responding (services may not be deployed yet)${NC}"
            ((WARNINGS++))
        fi
    else
        echo -e "${RED}✗ Not running${NC}"
        echo "  Run: minikube start"
        ((ISSUES++))
    fi
else
    echo -e "${RED}✗ Not installed${NC}"
    ((ISSUES++))
fi
echo ""

echo "8. Checking system resources..."
echo "-------------------------------"

# Check available memory
AVAILABLE_MEM=$(free -m | awk 'NR==2{printf "%.0f", $7}')
echo "  Available memory: ${AVAILABLE_MEM}MB"
if [ "$AVAILABLE_MEM" -lt 1024 ]; then
    echo -e "    ${YELLOW}⚠ Low memory (recommend 2GB+ free)${NC}"
    ((WARNINGS++))
else
    echo -e "    ${GREEN}✓ Sufficient${NC}"
fi

# Check disk space
DISK_USAGE=$(df -h / | awk 'NR==2{print $5}' | sed 's/%//')
echo "  Root disk usage: ${DISK_USAGE}%"
if [ "$DISK_USAGE" -gt 90 ]; then
    echo -e "    ${YELLOW}⚠ Disk space getting low${NC}"
    ((WARNINGS++))
else
    echo -e "    ${GREEN}✓ OK${NC}"
fi
echo ""

# Summary
echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                         Summary                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}\n"

if [ $ISSUES -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓✓✓ ALL CHECKS PASSED ✓✓✓${NC}"
    echo ""
    echo "Your system is ready for deployment!"
    echo "Run: bash deploy-complete-almalinux.sh"
    exit 0
elif [ $ISSUES -eq 0 ]; then
    echo -e "${YELLOW}⚠ $WARNINGS WARNINGS FOUND${NC}"
    echo ""
    echo "Your system should work, but there are some warnings."
    echo "Review the warnings above, then proceed with deployment."
    echo ""
    echo "Recommended actions:"
    if pgrep nginx > /dev/null; then
        echo "  1. Stop existing Nginx: sudo systemctl stop nginx"
    fi
    if sudo systemctl is-active --quiet httpd; then
        echo "  2. Stop Apache: sudo systemctl stop httpd && sudo systemctl disable httpd"
    fi
    echo ""
    echo "Or run the fix script to prepare everything:"
    echo "  bash fix-nginx-startup.sh"
    exit 0
else
    echo -e "${RED}✗✗✗ $ISSUES CRITICAL ISSUES FOUND ✗✗✗${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}    $WARNINGS warnings also found${NC}"
    fi
    echo ""
    echo "Please fix the following before deployment:"
    echo ""

    # Provide specific guidance based on issues
    if ! command -v minikube > /dev/null 2>&1 || ! minikube status > /dev/null 2>&1; then
        echo "  1. Start Minikube:"
        echo "     minikube start --driver=docker --cpus=4 --memory=8192"
        echo ""
    fi

    if sudo systemctl is-active --quiet httpd; then
        echo "  2. Stop Apache:"
        echo "     sudo systemctl stop httpd"
        echo "     sudo systemctl disable httpd"
        echo ""
    fi

    # Check for port conflicts
    PORT_CONFLICTS=false
    for PORT in 80 3000 5000 9090; do
        if sudo lsof -i :$PORT > /dev/null 2>&1; then
            if [ "$PORT_CONFLICTS" = false ]; then
                echo "  3. Free up ports:"
                PORT_CONFLICTS=true
            fi
            echo "     sudo lsof -i :$PORT  # Check what's using it"
        fi
    done
    if [ "$PORT_CONFLICTS" = true ]; then
        echo "     sudo pkill <process>  # Kill the conflicting process"
        echo ""
    fi

    echo "Or run the automated fix:"
    echo "  bash fix-nginx-startup.sh"
    echo ""
    exit 1
fi
