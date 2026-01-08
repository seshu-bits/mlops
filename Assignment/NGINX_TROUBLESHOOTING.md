# Nginx Startup Troubleshooting Guide

## Quick Fix

If Nginx fails to start during deployment, run:

```bash
bash fix-nginx-startup.sh
```

This automated script will:
1. Diagnose the issue
2. Apply all necessary fixes
3. Start Nginx successfully

## Common Issues and Solutions

### Issue 1: Port Conflicts

**Symptom:** Nginx fails with "Address already in use" error

**Quick Check:**
```bash
# Check what's using port 80
sudo lsof -i :80

# Check all relevant ports
sudo lsof -i :80,3000,5000,9090
```

**Solutions:**

A. Stop conflicting Apache service:
```bash
sudo systemctl stop httpd
sudo systemctl disable httpd
```

B. Kill stray Nginx processes:
```bash
sudo pkill nginx
sudo rm -f /run/nginx.pid /var/run/nginx.pid
```

C. Find and stop other services:
```bash
# Identify the process
sudo lsof -i :80

# Stop it (replace PID with actual process ID)
sudo kill -9 <PID>
```

### Issue 2: SELinux Blocking Nginx

**Symptom:** Nginx fails to bind to ports 3000, 5000, or 9090

**Quick Check:**
```bash
# Check SELinux status
getenforce

# Check recent denials
sudo ausearch -m avc -ts recent | grep nginx
```

**Solutions:**

A. Enable network connections:
```bash
sudo setsebool -P httpd_can_network_connect 1
```

B. Add port permissions:
```bash
# Install SELinux tools if needed
sudo dnf install -y policycoreutils-python-utils

# Add port labels
sudo semanage port -a -t http_port_t -p tcp 3000
sudo semanage port -a -t http_port_t -p tcp 5000
sudo semanage port -a -t http_port_t -p tcp 9090
```

C. Restore file contexts:
```bash
sudo restorecon -Rv /etc/nginx
sudo restorecon -Rv /var/log/nginx
```

D. Temporary workaround (NOT RECOMMENDED for production):
```bash
# Temporarily set SELinux to permissive
sudo setenforce 0
# Test if Nginx starts
sudo systemctl start nginx
# If it works, the issue is SELinux-related
```

### Issue 3: Configuration Syntax Errors

**Symptom:** `nginx -t` fails with syntax errors

**Quick Check:**
```bash
# Test configuration
sudo nginx -t

# Check configuration files
cat /etc/nginx/nginx.conf
cat /etc/nginx/conf.d/mlops-proxy.conf
```

**Solutions:**

A. Backup and recreate nginx.conf:
```bash
# Backup existing config
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup

# Create minimal working config
sudo tee /etc/nginx/nginx.conf > /dev/null << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

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

    include /etc/nginx/conf.d/*.conf;
}
EOF

# Test again
sudo nginx -t
```

B. Check for duplicate server blocks:
```bash
# List all config files
ls -la /etc/nginx/conf.d/

# Remove default server configs that might conflict
sudo rm -f /etc/nginx/conf.d/default.conf
```

### Issue 4: Missing Directories or Permissions

**Symptom:** Nginx fails with "No such file or directory" errors

**Quick Check:**
```bash
# Check directory existence
ls -la /var/log/nginx
ls -la /var/cache/nginx
ls -la /var/lib/nginx
```

**Solution:**
```bash
# Create all required directories
sudo mkdir -p /var/log/nginx
sudo mkdir -p /etc/nginx/conf.d
sudo mkdir -p /var/cache/nginx
sudo mkdir -p /var/lib/nginx/tmp

# Set correct ownership
sudo chown -R nginx:nginx /var/log/nginx
sudo chown -R nginx:nginx /var/cache/nginx
sudo chown -R nginx:nginx /var/lib/nginx

# Set correct permissions
sudo chmod 755 /var/log/nginx
sudo chmod 755 /var/cache/nginx
```

### Issue 5: Firewall Blocking Connections

**Symptom:** Nginx starts but services are not accessible remotely

**Quick Check:**
```bash
# Check firewall status
sudo firewall-cmd --state

# List open ports
sudo firewall-cmd --list-ports
sudo firewall-cmd --list-services
```

**Solution:**
```bash
# Open required ports
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --permanent --add-port=5000/tcp
sudo firewall-cmd --permanent --add-port=9090/tcp

# Reload firewall
sudo firewall-cmd --reload

# Verify
sudo firewall-cmd --list-all
```

## Diagnostic Commands

### View Nginx Status
```bash
# Service status
sudo systemctl status nginx

# Detailed status with recent logs
sudo systemctl status nginx -l --no-pager

# Check if Nginx is running
sudo systemctl is-active nginx
```

### View Nginx Logs
```bash
# Error log (last 50 lines)
sudo tail -n 50 /var/log/nginx/error.log

# Follow error log in real-time
sudo tail -f /var/log/nginx/error.log

# System journal logs
sudo journalctl -u nginx -n 50

# Follow journal logs
sudo journalctl -u nginx -f
```

### Test Configuration
```bash
# Test configuration syntax
sudo nginx -t

# Test with verbose output
sudo nginx -T
```

### Check Listening Ports
```bash
# Show all Nginx listening ports
sudo ss -tlnp | grep nginx

# Alternative using netstat
sudo netstat -tlnp | grep nginx

# Check specific port
sudo lsof -i :80
```

### Check SELinux
```bash
# SELinux status
getenforce

# List SELinux booleans for httpd
sudo getsebool -a | grep httpd

# Check port labels
sudo semanage port -l | grep http_port_t

# View recent SELinux denials
sudo ausearch -m avc -ts recent

# View Nginx-specific denials
sudo ausearch -m avc -c nginx
```

## Step-by-Step Manual Fix

If the automated script doesn't work, follow these steps manually:

### 1. Stop Everything
```bash
# Stop Nginx
sudo systemctl stop nginx

# Kill any stray processes
sudo pkill nginx

# Clean PID files
sudo rm -f /run/nginx.pid /var/run/nginx.pid

# Stop conflicting services
sudo systemctl stop httpd
```

### 2. Check for Conflicts
```bash
# Check all ports
for PORT in 80 3000 5000 9090; do
    echo "Port $PORT:"
    sudo lsof -i :$PORT 2>/dev/null || echo "  Free"
done
```

### 3. Fix SELinux
```bash
# Install tools
sudo dnf install -y policycoreutils-python-utils

# Enable network connections
sudo setsebool -P httpd_can_network_connect 1

# Configure ports
for PORT in 3000 5000 9090; do
    sudo semanage port -a -t http_port_t -p tcp $PORT 2>/dev/null || \
    sudo semanage port -m -t http_port_t -p tcp $PORT
done

# Restore contexts
sudo restorecon -Rv /etc/nginx
```

### 4. Create Directories
```bash
sudo mkdir -p /var/log/nginx /etc/nginx/conf.d /var/cache/nginx /var/lib/nginx/tmp
sudo chown -R nginx:nginx /var/log/nginx /var/cache/nginx /var/lib/nginx
```

### 5. Test Configuration
```bash
sudo nginx -t
```

### 6. Configure Firewall
```bash
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --permanent --add-port=5000/tcp
sudo firewall-cmd --permanent --add-port=9090/tcp
sudo firewall-cmd --reload
```

### 7. Start Nginx
```bash
# Enable on boot
sudo systemctl enable nginx

# Start service
sudo systemctl start nginx

# Verify
sudo systemctl status nginx
```

## Verification After Fix

Run these commands to verify everything is working:

```bash
# 1. Check Nginx status
sudo systemctl status nginx

# 2. Verify listening ports
sudo ss -tlnp | grep nginx

# 3. Test configuration
sudo nginx -t

# 4. Check logs for errors
sudo tail -n 20 /var/log/nginx/error.log

# 5. Test local connectivity
curl -I http://localhost
curl -I http://localhost:3000
curl -I http://localhost:5000
curl -I http://localhost:9090

# 6. Check SELinux denials (should be empty)
sudo ausearch -m avc -ts today | grep nginx
```

## Prevention Tips

1. **Always run deployment as non-root user with sudo**
2. **Check for port conflicts before starting Nginx**
3. **Ensure SELinux is properly configured before first start**
4. **Keep backups of working configurations**
5. **Use the automated fix script for consistent results**

## Getting Help

If issues persist after trying all solutions:

1. **Gather diagnostic information:**
```bash
# Run comprehensive diagnostics
bash fix-nginx-startup.sh > nginx-diagnostics.txt 2>&1
```

2. **Check specific error messages:**
```bash
# View detailed journal
sudo journalctl -u nginx --no-pager -n 100

# Check system messages
sudo tail -n 100 /var/log/messages | grep nginx
```

3. **Verify Minikube is running:**
```bash
minikube status
minikube ip
```

4. **Test backend connectivity:**
```bash
MINIKUBE_IP=$(minikube ip)
curl -I http://$MINIKUBE_IP
```

## Quick Reference

| Problem | Command | Expected Result |
|---------|---------|-----------------|
| Test config | `sudo nginx -t` | syntax is ok |
| Check status | `sudo systemctl status nginx` | active (running) |
| Check ports | `sudo ss -tlnp \| grep nginx` | Shows 80, 3000, 5000, 9090 |
| Check SELinux | `getenforce` | Enforcing or Permissive |
| View errors | `sudo journalctl -u nginx -n 20` | No recent errors |
| Restart | `sudo systemctl restart nginx` | No error message |

## Emergency Workaround

If you need services running immediately and can't fix Nginx:

```bash
# Access services directly via Minikube IP
MINIKUBE_IP=$(minikube ip)

# Update /etc/hosts on your local machine
echo "$MINIKUBE_IP api.mlops.local" | sudo tee -a /etc/hosts
echo "$MINIKUBE_IP grafana.mlops.local" | sudo tee -a /etc/hosts
echo "$MINIKUBE_IP prometheus.mlops.local" | sudo tee -a /etc/hosts
echo "$MINIKUBE_IP mlflow.mlops.local" | sudo tee -a /etc/hosts

# Access via browser
firefox http://$MINIKUBE_IP
```
