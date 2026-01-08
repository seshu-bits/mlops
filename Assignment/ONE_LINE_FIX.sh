#!/bin/bash
# ONE-LINE FIX for Nginx startup failure on AlmaLinux 8
#
# ═══════════════════════════════════════════════════════════════════
# USAGE (On AlmaLinux server 72.163.219.91):
# ═══════════════════════════════════════════════════════════════════
#
# Just copy-paste and run this command:

bash fix-nginx-startup.sh

# That's it! The script will:
# - Diagnose the problem
# - Fix SELinux configuration
# - Stop conflicting services
# - Create missing directories
# - Configure firewall
# - Start Nginx successfully
#
# ═══════════════════════════════════════════════════════════════════
# If you don't have the script yet:
# ═══════════════════════════════════════════════════════════════════
#
# git pull
# bash fix-nginx-startup.sh
#
# ═══════════════════════════════════════════════════════════════════
