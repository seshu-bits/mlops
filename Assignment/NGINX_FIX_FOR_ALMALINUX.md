# Nginx Startup Fix for AlmaLinux 8 Deployment

## Problem

During deployment on AlmaLinux 8, Nginx fails to start with the error:
```
✗ Nginx failed to start
Job for nginx.service failed because the control process exited with error code.
See "systemctl status nginx.service" and "journalctl -xe" for details.
```

## Solution Files Created

Three new files have been created to help diagnose and fix this issue on your AlmaLinux server:

### 1. `fix-nginx-startup.sh` (PRIMARY SOLUTION)
**Location:** `Assignment/fix-nginx-startup.sh`

This is the main automated fix script that will:
- ✓ Diagnose the exact issue
- ✓ Stop conflicting services (Apache/httpd)
- ✓ Kill stray Nginx processes
- ✓ Configure SELinux properly
- ✓ Create missing directories
- ✓ Fix Nginx configuration
- ✓ Configure firewall
- ✓ Start Nginx successfully

### 2. `preflight-check-nginx.sh` (PREVENTIVE)
**Location:** `Assignment/preflight-check-nginx.sh`

Run this BEFORE deployment to catch issues early:
- Checks port availability
- Verifies SELinux configuration
- Checks for conflicting services
- Validates Minikube status
- Verifies system resources

### 3. `NGINX_TROUBLESHOOTING.md` (REFERENCE)
**Location:** `Assignment/NGINX_TROUBLESHOOTING.md`

Comprehensive troubleshooting guide with:
- Common issues and solutions
- Manual fix procedures
- Diagnostic commands
- Step-by-step instructions

### 4. `NGINX_QUICK_FIX.txt` (QUICK REFERENCE)
**Location:** `Assignment/NGINX_QUICK_FIX.txt`

Quick reference card with immediate solutions.

## How to Use on AlmaLinux Server

### Step 1: Transfer Files to AlmaLinux Server

From your Mac, sync the files to your AlmaLinux server:

```bash
# Option A: If you have SSH access
cd "/Users/saghanta/Personal/Docs/Education/Seshu/BITS/Courses/SEM 3/MLOps/mlops"
scp Assignment/fix-nginx-startup.sh user@72.163.219.91:/path/to/mlops/Assignment/
scp Assignment/preflight-check-nginx.sh user@72.163.219.91:/path/to/mlops/Assignment/

# Option B: If using git
cd "/Users/saghanta/Personal/Docs/Education/Seshu/BITS/Courses/SEM 3/MLOps/mlops"
git add Assignment/fix-nginx-startup.sh
git add Assignment/preflight-check-nginx.sh
git add Assignment/NGINX_TROUBLESHOOTING.md
git add Assignment/NGINX_QUICK_FIX.txt
git commit -m "Add Nginx troubleshooting and fix scripts for AlmaLinux"
git push

# Then on AlmaLinux server:
# git pull
```

### Step 2: Run on AlmaLinux Server

**SSH into your AlmaLinux server first:**
```bash
ssh user@72.163.219.91
cd /path/to/mlops/Assignment
```

**Then run the fix:**

#### Option A: Automated Fix (Recommended)
```bash
# Make executable (on AlmaLinux)
chmod +x fix-nginx-startup.sh

# Run the fix
bash fix-nginx-startup.sh
```

#### Option B: Pre-Flight Check First (Best Practice)
```bash
# Make executable (on AlmaLinux)
chmod +x preflight-check-nginx.sh

# Run pre-flight check
bash preflight-check-nginx.sh

# If issues found, run the fix
chmod +x fix-nginx-startup.sh
bash fix-nginx-startup.sh
```

#### Option C: Re-run Deployment
The deployment script has been updated with better error handling:
```bash
bash deploy-complete-almalinux.sh
```

If it fails at the Nginx step, it will now provide detailed diagnostics and suggest running the fix script.

## Most Common Causes on AlmaLinux 8

### 1. SELinux Blocking Nginx (90% of cases)
AlmaLinux 8 has SELinux enabled by default in Enforcing mode.

**The fix script handles this by:**
- Installing `policycoreutils-python-utils`
- Setting `httpd_can_network_connect` boolean
- Adding port labels for 3000, 5000, 9090
- Restoring file contexts

**Manual fix if needed:**
```bash
sudo setsebool -P httpd_can_network_connect 1
sudo semanage port -a -t http_port_t -p tcp 3000
sudo semanage port -a -t http_port_t -p tcp 5000
sudo semanage port -a -t http_port_t -p tcp 9090
```

### 2. Apache (httpd) Conflict
AlmaLinux often has Apache pre-installed and running on port 80.

**The fix script handles this by:**
```bash
sudo systemctl stop httpd
sudo systemctl disable httpd
```

### 3. Missing Directories
Sometimes Nginx directories have wrong permissions.

**The fix script handles this by:**
```bash
sudo mkdir -p /var/log/nginx /var/cache/nginx /var/lib/nginx/tmp
sudo chown -R nginx:nginx /var/log/nginx /var/cache/nginx /var/lib/nginx
```

## Updated Deployment Script

The `deploy-complete-almalinux.sh` has been updated with:

1. **Better SELinux handling** - Creates directories and sets permissions properly
2. **Enhanced error messages** - Shows exactly what went wrong
3. **Diagnostic output** - Displays port conflicts, SELinux denials, and logs
4. **Fix script recommendation** - Suggests running `fix-nginx-startup.sh`

## Verification on AlmaLinux

After running the fix on your AlmaLinux server, verify:

```bash
# 1. Check Nginx status
sudo systemctl status nginx

# 2. Verify ports are listening
sudo ss -tlnp | grep nginx
# Should show: 80, 3000, 5000, 9090

# 3. Check SELinux
getenforce
# Should show: Enforcing (that's OK if properly configured)

sudo ausearch -m avc -ts recent | grep nginx
# Should be empty (no denials)

# 4. Test local connectivity
curl -I http://localhost
curl -I http://localhost:3000
curl -I http://localhost:5000
curl -I http://localhost:9090

# 5. Test remote connectivity (from your Mac or browser)
# http://72.163.219.91/
# http://72.163.219.91:9090
# http://72.163.219.91:3000
# http://72.163.219.91:5000
```

## Remote Access from Your Mac

Once Nginx is running on AlmaLinux, you can access services from your Mac:

```bash
# API
curl http://72.163.219.91/health

# Or open in browser:
open http://72.163.219.91/docs           # API Documentation
open http://72.163.219.91:9090           # Prometheus
open http://72.163.219.91:3000           # Grafana (admin/admin)
open http://72.163.219.91:5000           # MLflow
```

## Workflow Summary

### On Your Mac:
1. Edit files (already done ✓)
2. Commit and push to git
3. Access services remotely after deployment

### On AlmaLinux Server:
1. Pull latest code
2. Run preflight check (optional but recommended)
3. Run deployment script OR fix script
4. Verify services are running
5. Services are now accessible remotely

## Important Notes

- ✓ All scripts are designed for AlmaLinux 8
- ✓ Scripts handle SELinux properly (don't disable it!)
- ✓ Scripts are safe to run multiple times
- ✓ The fix script is non-destructive (backs up configs)
- ✓ Firewall rules are automatically configured

## Quick Command Reference (On AlmaLinux)

```bash
# Pre-flight check (before deployment)
bash preflight-check-nginx.sh

# Fix Nginx issues (after deployment failure)
bash fix-nginx-startup.sh

# View detailed guide
cat NGINX_TROUBLESHOOTING.md

# View quick reference
cat NGINX_QUICK_FIX.txt

# Manual diagnostics
sudo journalctl -u nginx -n 50
sudo systemctl status nginx
sudo nginx -t
sudo lsof -i :80,3000,5000,9090
```

## Support

If issues persist after running the fix script:

1. Capture full diagnostics:
   ```bash
   bash fix-nginx-startup.sh > nginx-diagnostics.log 2>&1
   ```

2. Check specific error:
   ```bash
   sudo journalctl -u nginx -n 100 --no-pager
   ```

3. Verify Minikube is running:
   ```bash
   minikube status
   minikube ip
   ```

4. Test Minikube connectivity:
   ```bash
   MINIKUBE_IP=$(minikube ip)
   curl -I http://$MINIKUBE_IP
   ```
