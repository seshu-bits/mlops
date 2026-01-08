#!/bin/bash

# Nginx Startup Troubleshooting and Fix Script
# This script diagnoses and fixes common Nginx startup issues on AlmaLinux

set +e  # Don't exit on errors - we want to gather all diagnostics

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         Nginx Startup Troubleshooting & Fix Script            ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}\n"

# Step 1: Check current Nginx status
echo -e "${YELLOW}Step 1: Checking Nginx Status${NC}"
echo "================================"
sudo systemctl status nginx --no-pager -l
echo ""

# Step 2: Check for port conflicts
echo -e "${YELLOW}Step 2: Checking for Port Conflicts${NC}"
echo "====================================="
echo "Checking port 80:"
sudo lsof -i :80 2>/dev/null || echo "Port 80 is free"
echo ""

echo "Checking port 3000:"
sudo lsof -i :3000 2>/dev/null || echo "Port 3000 is free"
echo ""

echo "Checking port 5000:"
sudo lsof -i :5000 2>/dev/null || echo "Port 5000 is free"
echo ""

echo "Checking port 9090:"
sudo lsof -i :9090 2>/dev/null || echo "Port 9090 is free"
echo ""

# Step 3: Check Nginx logs
echo -e "${YELLOW}Step 3: Nginx Error Logs (Last 30 lines)${NC}"
echo "=========================================="
sudo tail -n 30 /var/log/nginx/error.log 2>/dev/null || echo "No error log found"
echo ""

# Step 4: Check journal logs
echo -e "${YELLOW}Step 4: System Journal Logs for Nginx${NC}"
echo "======================================="
sudo journalctl -u nginx -n 30 --no-pager
echo ""

# Step 5: Test Nginx configuration
echo -e "${YELLOW}Step 5: Testing Nginx Configuration${NC}"
echo "====================================="
sudo nginx -t
echo ""

# Step 6: Check SELinux status
echo -e "${YELLOW}Step 6: Checking SELinux Status${NC}"
echo "================================="
if command -v getenforce &> /dev/null; then
    SELINUX_STATUS=$(getenforce)
    echo "SELinux status: $SELINUX_STATUS"

    if [ "$SELINUX_STATUS" != "Disabled" ]; then
        echo ""
        echo "Checking SELinux denials for Nginx:"
        sudo ausearch -m avc -ts recent 2>/dev/null | grep nginx | tail -n 10 || echo "No recent denials found"

        echo ""
        echo "Checking port labels:"
        sudo semanage port -l | grep http_port_t | grep -E "(80|3000|5000|9090)"
    fi
else
    echo "getenforce not found - SELinux may not be installed"
fi
echo ""

# Step 7: Check required directories
echo -e "${YELLOW}Step 7: Checking Required Directories${NC}"
echo "======================================="
[ -d "/var/log/nginx" ] && echo "✓ /var/log/nginx exists" || echo "✗ /var/log/nginx missing"
[ -d "/etc/nginx/conf.d" ] && echo "✓ /etc/nginx/conf.d exists" || echo "✗ /etc/nginx/conf.d missing"
[ -d "/var/cache/nginx" ] && echo "✓ /var/cache/nginx exists" || echo "✗ /var/cache/nginx missing"
[ -d "/run" ] && echo "✓ /run exists" || echo "✗ /run missing"
echo ""

# Step 8: Check configuration files
echo -e "${YELLOW}Step 8: Checking Configuration Files${NC}"
echo "======================================"
[ -f "/etc/nginx/nginx.conf" ] && echo "✓ nginx.conf exists" || echo "✗ nginx.conf missing"
[ -f "/etc/nginx/conf.d/mlops-proxy.conf" ] && echo "✓ mlops-proxy.conf exists" || echo "✗ mlops-proxy.conf missing"
echo ""

# Now offer fixes
echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                     Applying Fixes                             ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}\n"

# Fix 1: Stop conflicting services and free up ports
echo -e "${GREEN}Fix 1: Stopping Conflicting Services and Freeing Ports${NC}"
echo "======================================================="
if sudo systemctl is-active --quiet httpd; then
    echo "Stopping Apache (httpd)..."
    sudo systemctl stop httpd
    sudo systemctl disable httpd
    echo "✓ Apache stopped"
else
    echo "✓ No Apache service running"
fi

# Kill any stray nginx processes
if pgrep nginx > /dev/null; then
    echo "Killing stray Nginx processes..."
    sudo pkill -9 nginx 2>/dev/null || true
    sleep 3
    echo "✓ Stray processes killed"
else
    echo "✓ No stray Nginx processes"
fi

# Aggressively kill processes on required ports
echo "Checking and freeing required ports (80, 3000, 5000, 9090)..."
for PORT in 80 3000 5000 9090; do
    if sudo lsof -i :$PORT > /dev/null 2>&1; then
        echo "  Port $PORT is in use, killing processes..."
        sudo lsof -ti :$PORT | xargs -r sudo kill -9 2>/dev/null || true
        sleep 1
        if sudo lsof -i :$PORT > /dev/null 2>&1; then
            echo "  ⚠ Port $PORT still in use after kill attempt"
            sudo lsof -i :$PORT
        else
            echo "  ✓ Port $PORT freed"
        fi
    else
        echo "  ✓ Port $PORT is free"
    fi
done

# Clean up PID files
sudo rm -f /run/nginx.pid /var/run/nginx.pid 2>/dev/null || true
echo "✓ PID files cleaned"
echo ""

# Fix 2: Create missing directories
echo -e "${GREEN}Fix 2: Creating Missing Directories${NC}"
echo "====================================="
sudo mkdir -p /var/log/nginx
sudo mkdir -p /etc/nginx/conf.d
sudo mkdir -p /var/cache/nginx
sudo mkdir -p /var/lib/nginx/tmp
sudo chown -R nginx:nginx /var/log/nginx /var/cache/nginx /var/lib/nginx
echo "✓ Directories created and permissions set"
echo ""

# Fix 3: SELinux configuration
echo -e "${GREEN}Fix 3: Configuring SELinux${NC}"
echo "============================"
if command -v getenforce &> /dev/null && [ "$(getenforce)" != "Disabled" ]; then
    # Install SELinux tools if needed
    if ! command -v semanage &> /dev/null; then
        echo "Installing SELinux management tools..."
        sudo dnf install -y policycoreutils-python-utils
    fi

    # Set boolean for network connections
    echo "Enabling httpd_can_network_connect..."
    sudo setsebool -P httpd_can_network_connect 1

    # Configure ports
    echo "Configuring SELinux port labels..."
    for PORT in 3000 5000 9090; do
        sudo semanage port -a -t http_port_t -p tcp $PORT 2>/dev/null || \
        sudo semanage port -m -t http_port_t -p tcp $PORT 2>/dev/null || \
        echo "Port $PORT already configured or error"
    done

    # Restore file contexts
    echo "Restoring SELinux file contexts..."
    sudo restorecon -Rv /etc/nginx /var/log/nginx /var/cache/nginx 2>/dev/null || true

    echo "✓ SELinux configured"
else
    echo "ℹ️  SELinux is disabled, skipping"
fi
echo ""

# Fix 4: Clean up conflicting Nginx configurations
echo -e "${GREEN}Fix 4: Cleaning Up Conflicting Nginx Configurations${NC}"
echo "====================================================="

# Backup existing conf.d directory
if [ -d /etc/nginx/conf.d ]; then
    echo "Backing up existing Nginx configurations..."
    sudo mkdir -p /etc/nginx/conf.d.backup.$(date +%Y%m%d_%H%M%S)
    sudo cp -r /etc/nginx/conf.d/* /etc/nginx/conf.d.backup.$(date +%Y%m%d_%H%M%S)/ 2>/dev/null || true
fi

# Remove potentially conflicting default configurations
echo "Removing default/conflicting configurations..."
sudo rm -f /etc/nginx/conf.d/default.conf 2>/dev/null || true
sudo rm -f /etc/nginx/conf.d/ssl.conf 2>/dev/null || true
sudo rm -f /etc/nginx/conf.d/virtual.conf 2>/dev/null || true
sudo rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true

# List any remaining config files that might conflict
echo "Checking for other configuration files..."
if [ -d /etc/nginx/conf.d ]; then
    CONF_COUNT=$(sudo find /etc/nginx/conf.d -name "*.conf" ! -name "mlops-proxy.conf" | wc -l)
    if [ $CONF_COUNT -gt 0 ]; then
        echo "⚠ Found $CONF_COUNT other .conf files:"
        sudo find /etc/nginx/conf.d -name "*.conf" ! -name "mlops-proxy.conf" -exec basename {} \;
        echo "  These may cause port conflicts. Consider reviewing them."
    else
        echo "✓ No conflicting configuration files found"
    fi
fi
echo ""

# Fix 5: Validate and fix Nginx configuration
echo -e "${GREEN}Fix 5: Validating Nginx Configuration${NC}"
echo "======================================="

# Get Minikube IP (if available)
if command -v minikube &> /dev/null && minikube status &> /dev/null; then
    MINIKUBE_IP=$(minikube ip)
    echo "✓ Minikube IP: $MINIKUBE_IP"
else
    MINIKUBE_IP="192.168.49.2"  # Default fallback
    echo "⚠️  Minikube not running, using default IP: $MINIKUBE_IP"
fi

SERVER_IP=$(hostname -I | awk '{print $1}' || echo "localhost")
echo "✓ Server IP: $SERVER_IP"
echo ""

# Create a minimal working nginx.conf
echo "Creating minimal nginx.conf..."
sudo tee /etc/nginx/nginx.conf > /dev/null << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

# Load dynamic modules
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 4096;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    # Load site configs
    include /etc/nginx/conf.d/*.conf;
}
EOF
echo "✓ Minimal nginx.conf created"
echo ""

# Create the proxy configuration
echo "Creating mlops-proxy.conf..."
sudo tee /etc/nginx/conf.d/mlops-proxy.conf > /dev/null << EOF
# MLOps Proxy Configuration
upstream api_backend {
    server ${MINIKUBE_IP}:80;
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name ${SERVER_IP} _;

    location / {
        proxy_pass http://api_backend;
        proxy_set_header Host api.mlops.local;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
}

server {
    listen 9090;
    listen [::]:9090;
    server_name ${SERVER_IP} _;

    location / {
        proxy_pass http://api_backend;
        proxy_set_header Host prometheus.mlops.local;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}

server {
    listen 3000;
    listen [::]:3000;
    server_name ${SERVER_IP} _;

    location / {
        proxy_pass http://api_backend;
        proxy_set_header Host grafana.mlops.local;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}

server {
    listen 5000;
    listen [::]:5000;
    server_name ${SERVER_IP} _;

    location / {
        proxy_pass http://api_backend;
        proxy_set_header Host mlflow.mlops.local;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF
echo "✓ mlops-proxy.conf created"
echo ""

# Test configuration
echo "Testing Nginx configuration..."
if sudo nginx -t; then
    echo -e "${GREEN}✓ Configuration test passed${NC}"
else
    echo -e "${RED}✗ Configuration test failed${NC}"
    echo "Please review the errors above"
    exit 1
fi
echo ""

# Fix 6: Configure firewall
echo -e "${GREEN}Fix 6: Configuring Firewall${NC}"
echo "============================"
if command -v firewall-cmd &> /dev/null; then
    if sudo firewall-cmd --state &> /dev/null; then
        echo "Opening firewall ports..."
        sudo firewall-cmd --permanent --add-service=http
        sudo firewall-cmd --permanent --add-service=https
        sudo firewall-cmd --permanent --add-port=80/tcp
        sudo firewall-cmd --permanent --add-port=443/tcp
        sudo firewall-cmd --permanent --add-port=3000/tcp
        sudo firewall-cmd --permanent --add-port=5000/tcp
        sudo firewall-cmd --permanent --add-port=9090/tcp
        sudo firewall-cmd --reload
        echo "✓ Firewall configured"
    else
        echo "⚠️  Firewall not running"
    fi
else
    echo "ℹ️  firewalld not found"
fi
echo ""

# Fix 7: Start Nginx
echo -e "${GREEN}Fix 7: Starting Nginx${NC}"
echo "======================"

# One final check for port conflicts before starting
echo "Final port check before starting Nginx..."
PORTS_BLOCKED=false
for PORT in 80 3000 5000 9090; do
    if sudo lsof -i :$PORT > /dev/null 2>&1; then
        echo "⚠ Port $PORT is still in use:"
        sudo lsof -i :$PORT
        PORTS_BLOCKED=true
    fi
done

if [ "$PORTS_BLOCKED" = true ]; then
    echo ""
    echo -e "${YELLOW}WARNING: Some ports are still in use.${NC}"
    echo "Attempting to force kill remaining processes..."
    for PORT in 80 3000 5000 9090; do
        sudo fuser -k $PORT/tcp 2>/dev/null || true
    done
    sleep 2
fi

echo "Enabling Nginx to start on boot..."
sudo systemctl enable nginx

echo "Starting Nginx..."
if sudo systemctl start nginx; then
    echo -e "${GREEN}✓ Nginx started successfully${NC}"
else
    echo -e "${RED}✗ Nginx failed to start${NC}"
    echo ""
    echo "Detailed error information:"
    sudo systemctl status nginx --no-pager -l
    echo ""
    echo "Recent journal entries:"
    sudo journalctl -u nginx -n 20 --no-pager
    echo ""
    echo "Port status:"
    sudo ss -tlnp | grep -E ":(80|3000|5000|9090)"
    exit 1
fi
echo ""

# Verify Nginx is running
sleep 2
if sudo systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✓ Nginx is running successfully${NC}"

    # Show listening ports
    echo ""
    echo "Nginx is listening on:"
    sudo ss -tlnp | grep nginx || echo "Could not determine listening ports"
else
    echo -e "${RED}✗ Nginx is not running${NC}"
    sudo systemctl status nginx
    exit 1
fi
echo ""

# Final status check
echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                      Final Status                              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}\n"

echo "Nginx Status:"
sudo systemctl status nginx --no-pager | head -n 5
echo ""

echo "Active Connections:"
sudo ss -tlnp | grep -E "(80|3000|5000|9090)" || echo "No listening ports found"
echo ""

echo -e "${GREEN}✓ All fixes applied!${NC}"
echo ""
echo -e "${YELLOW}Access Points:${NC}"
echo "  API:        http://${SERVER_IP}/"
echo "  Prometheus: http://${SERVER_IP}:9090"
echo "  Grafana:    http://${SERVER_IP}:3000"
echo "  MLflow:     http://${SERVER_IP}:5000"
echo ""
echo -e "${YELLOW}Useful Commands:${NC}"
echo "  Check status:  sudo systemctl status nginx"
echo "  View logs:     sudo tail -f /var/log/nginx/error.log"
echo "  Test config:   sudo nginx -t"
echo "  Restart:       sudo systemctl restart nginx"
echo ""
