#!/bin/bash
# Deploy to AlmaLinux and handle Nginx setup
# Run this on your AlmaLinux server: ssh user@72.163.219.91

echo "════════════════════════════════════════════════════════════════"
echo "  AlmaLinux 8 Deployment - Nginx Fix Integrated"
echo "  Server: 72.163.219.91"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Make all scripts executable
chmod +x deploy-complete-almalinux.sh
chmod +x fix-nginx-startup.sh
chmod +x preflight-check-nginx.sh

echo "Step 1: Running Pre-Flight Checks..."
echo "------------------------------------"
bash preflight-check-nginx.sh
PREFLIGHT_RESULT=$?

if [ $PREFLIGHT_RESULT -ne 0 ]; then
    echo ""
    echo "⚠️  Pre-flight checks found issues."
    echo ""
    read -p "Do you want to run the fix script now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "Running automated fix..."
        bash fix-nginx-startup.sh
        if [ $? -ne 0 ]; then
            echo ""
            echo "❌ Fix script encountered errors. Please review the output above."
            exit 1
        fi
    else
        echo ""
        echo "Please fix the issues manually before proceeding."
        echo "See NGINX_TROUBLESHOOTING.md for detailed instructions."
        exit 1
    fi
fi

echo ""
echo "Step 2: Starting Main Deployment..."
echo "------------------------------------"
bash deploy-complete-almalinux.sh

DEPLOY_RESULT=$?

if [ $DEPLOY_RESULT -ne 0 ]; then
    echo ""
    echo "❌ Deployment failed. Checking if it's an Nginx issue..."
    echo ""

    if ! sudo systemctl is-active --quiet nginx; then
        echo "Nginx is not running. Attempting fix..."
        bash fix-nginx-startup.sh

        if sudo systemctl is-active --quiet nginx; then
            echo ""
            echo "✓ Nginx fixed! Re-running deployment from Nginx step..."
            # Could add logic here to continue from where it failed
        else
            echo ""
            echo "❌ Could not fix Nginx. Please check the logs:"
            echo "  sudo journalctl -u nginx -n 50"
            exit 1
        fi
    fi
else
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "  ✓ Deployment Successful!"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "Access your services at:"
    echo "  API:        http://72.163.219.91/"
    echo "  API Docs:   http://72.163.219.91/docs"
    echo "  Prometheus: http://72.163.219.91:9090"
    echo "  Grafana:    http://72.163.219.91:3000 (admin/admin)"
    echo "  MLflow:     http://72.163.219.91:5000"
    echo ""
fi
