#!/usr/bin/env bash
###############################################################################
# 02_remediation.sh
# Purpose: Handles vulnerability cleanup and remediation
#          for SquirrelWorks 1.1 images.
###############################################################################
set -ex

echo "=========================================================="
echo ">>> PHASE: Automated Remediation & Purge"
echo "=========================================================="

# Ensure apt doesn't freeze waiting for user input
export DEBIAN_FRONTEND=noninteractive

# 1. Update lists and apply all available OS security patches
echo ">>> Applying system updates and security patches..."
apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y

# 2. Self-heal any broken dependencies caused by previous installers
echo ">>> Fixing broken dependencies..."
apt-get --fix-broken install -y

# 3. Strip out orphaned dependencies and purge their config files
echo ">>> Purging orphaned dependencies..."
apt-get autoremove -y --purge

# 4. Aggressive cache cleanup to shrink the Docker layer size
echo ">>> Cleaning APT caches and lists..."
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /var/cache/apt/archives/*

# 5. Wipe temporary files and logs generated during the build
echo ">>> Removing temporary files and logs..."
rm -rf /tmp/* \
       /var/tmp/* \
       /var/log/apt/* \
       /var/log/dpkg.log \
       /var/log/alternatives.log

echo ">>> Remediation and Purge Complete."
echo "=========================================================="
