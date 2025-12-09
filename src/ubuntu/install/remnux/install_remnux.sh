# This script installs the Remnux tools using the "Add to an existing system". 
# It is meant to be run/installed into a pre-configured Kasm workspace's
# Dockerfile and was not developed to work as standalone. 
# For official documentation see "https://docs.remnux.org/install-distro/"
#!/usr/bin/env bash
set -ex

echo "======= Installing REMnux Malware Analysis Environment ======="

export DEBIAN_FRONTEND=noninteractive
export HOME=/root   # ensure HOME is correct for REMnux

# Step 1: Installing dependencies
echo "Step 1: Installing dependencies..."
apt-get update
apt-get upgrade -y
apt-get autoremove -y

# Step 2: Downloading and running REMnux tools
echo "Step 2: Downloading and running REMnux tools..."
cd /tmp
curl -sSLo remnux https://remnux.org/remnux-cli
chmod +x remnux

# Must run with the sudo command, with HOME=/root and /root must exist
sudo ./remnux install --mode=addon --user=kasm-user

# Step 3: Cleaning up
echo "Step 3: Cleaning up..."

# DO NOT remove /root before REMnux install
rm -f /usr/share/xfce4/panel/plugins/power-manager-plugin.desktop
rm -rf /tmp/*

# Reset HOME **after** REMnux installation
export HOME=/home/kasm-default-profile

if [ -z "${SKIP_CLEAN+x}" ]; then
  apt-get autoclean
  rm -rf \
    /var/lib/apt/lists/* \
    /var/tmp/*
fi

echo "The REMnux Malware Analysis Environment is configured. Use responsibly!"