# Copied from official KasmTech repo at "https://github.com/kasmtech/workspaces-images/blob/develop/src/ubuntu/install/"
#!/usr/bin/env bash
set -ex

echo "======= Installing Thunderbird ======="

# If OS is Non-Ubuntu Debian Variant
echo "Step 1: Download and Install..."
add-apt-repository ppa:mozillateam/ppa
apt install thunderbird -y
echo ' Package: * Pin: release o=LP-PPA-mozillateam Pin-Priority: 1001\nPackage: thunderbird Pin: version 2:1snap* Pin-Priority: -1 ' | sudo tee /etc/apt/preferences.d/thunderbird.conf

# Desktop icon
echo "Step 2: Modify the desktop icon..."
cp /usr/share/applications/thunderbird.desktop $HOME/Desktop/
chmod +x $HOME/Desktop/thunderbird.desktop

# Cleanup for app layer
echo "Step 3: Cleaning Up..."
chown -R 1000:0 $HOME
find /usr/share/ -name "icon-theme.cache" -exec rm -f {} \;

echo "Thunderbird is now Installed!"