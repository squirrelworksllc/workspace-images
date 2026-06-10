#!/usr/bin/env bash
###############################################################################
# install_zbar.sh
# Purpose: Installs the ZBar barcode reader application into the workspace.
###############################################################################
set -e

echo "Starting ZBar backend installation..."

# Prevent interactive prompts
export DEBIAN_FRONTEND=noninteractive

# Update and install ZBar and video dependencies
apt-get update
apt-get install -y --no-install-recommends \
    zbar-tools \
    libzbar-dev \
    libv4l-0

# Clean apt cache to reduce Docker layer size
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "ZBar backend installation complete. Triggering UI configuration..."

# Execute the UI script directly from the install script
# Assuming both are staged in /tmp/ by the Dockerfile
chmod +x /tmp/configure_ui.sh
/tmp/configure_ui.sh
