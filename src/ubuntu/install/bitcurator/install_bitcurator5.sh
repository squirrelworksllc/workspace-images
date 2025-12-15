# This script installs Bitcurator onto the system under the kasm-user user. 
# It is meant to be run/installed into a pre-configured Kasm workspace's
# Dockerfile and was not developed to work as standalone. 
# For official documentation see "https://github.com/BitCurator/bitcurator-distro/wiki/BitCurator-Quick-Start-Guide"
#!/usr/bin/env bash
set -euo pipefail
source /dockerstartup/install/ubuntu/install/common/00_apt_helper.sh

echo "======= Installing Bitcurator 5 Environment ======="

# Step 1: Installing depencencies
echo "Step 1: Installing dependencies..."
apt_update_if_needed
apt upgrade -y
apt install nano build-essential gcc make perl curl gnupg -y
apt install --reinstall ca-certificates -y

# Step 2: Downloading and prepping the Bitcurator CLI
echo "Step 2: Downloading and prepping the Bitcurator CLI..."
cd /tmp
wget https://github.com/BitCurator/bitcurator-cli/releases/download/v3.0.0/bitcurator-cli-linux
chmod +x /tmp/bitcurator-cli-linux
groupadd bcadmin && usermod -aG sudo,bcadmin,docker kasm-user

# Step 3: Installing Bitcurator (this will take some time)
echo "Step 3: Installing Bitcurator. This will take a while, go get some coffee..."
sudo /tmp/bitcurator-cli-linux install --mode=addon --user=kasm-user

# Step 4: Cleaning up
echo "Step 4: Cleaning up..."
rm -f /usr/share/xfce4/panel/plugins/power-manager-plugin.desktop
rm -rf /tmp/*

# Reset HOME **after** Bitcurator installation
export HOME=/home/kasm-default-profile

if [ -z "${SKIP_CLEAN+x}" ]; then
  apt-get autoclean
  rm -rf \
    /var/lib/apt/lists/* \
    /var/tmp/*
fi

echo "Bitcurator 5 is successfully installed!"


#Keep getting "timedatectl failed: System has not been booted with systemd as init system (PID 1). Can't operate.
# 1740.3 Failed to connect to bus: Host is down"

#Let's try this...
# Do "Manual Builds of the BitCurator Environment" (https://github.com/BitCurator/bitcurator-salt/blob/main/BUILD.md):
#-set the username to "kasm_user"
#-should  I use dedicated or addon? Try dedicated first and see if all Kasm functionality works properly...
