# This script installs the Remnux tools using the "Add to an existing system". 
# For official documentation see "https://docs.remnux.org/install-distro/"

#!/bin/bash
set -x

# Download and install dependancies
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
sudo apt install -y gnupg curl

# Download and run the remnux tools
cd /tmp
wget https://REMnux.org/remnux-cli
mv remnux-cli remnux
chmod +x remnux
sudo remnux install --mode=addon --user=kasm-user

# Cleanup
rm -f /usr/share/xfce4/panel/plugins/power-manager-plugin.desktop
rm -rf \
  /root \
  /tmp/*
mkdir /root
export HOME=/home/kasm-default-profile
if [ -z ${SKIP_CLEAN+x} ]; then
  apt-get autoclean
  rm -rf \
    /var/lib/apt/lists/* \
    /var/tmp/*
fi