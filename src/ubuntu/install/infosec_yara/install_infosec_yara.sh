# This script is designed to install the complete environment needed to test and/or develop YARA rules inside
# of a docker container. This includes a pre-defined Yara release, a Yara Language Server (YLS-Yara)
# and extensions for Visual Studio as well as commandline utilities.
# Although this script may work alone it was not designed to do so and was designed to be invoked via Dockerfile.
#!/usr/bin/env bash
set -ex

echo "======= Installing InfoSec Yara Environment ======="
# Install Dependencies
echo "Step 1: Installing Dependencies..."
apt install automake libtool make gcc pkg-config libssl-dev -y

# Download Yara 4.5.5 release and install
echo "Step 2: Download and Install Yara..."
cd /opt
curl -sSLo yara.tar.gz https://github.com/VirusTotal/yara/archive/refs/tags/v4.5.5.tar.gz
tar -zxf yara.tar.gz
cd /opt/yara
./bootstrap.sh
./configure
echo "Now Installing Yara 4.5.5..."
make install

# Download Yara's Python libraries
echo "Step 3: Download and install Python libraries..."
# Install yara-python
pip3 install yara-python
# Prep and install yls-yara
mkdir -p ~/yls
cd ~/yls
python -m venv env
. env/bin/activate
pip3 install -U yls-yara
# To get the absolute path of the yls executable
realpath env/bin/yls

# Install VS Code extension
echo "Step 4: Prep and Install VS Code extension..."
cd /usr/share/applications && sed -i 's%--new-window% c --no-sandbox --disable-workspace-trust --new-window%' code.desktop
cd /usr/share/applications && sed -i 's%--unity-launch% c --no-sandbox --disable-workspace-trust --new-window%' code.desktop
mkdir -p /home/kasm-user/.local/share/applications && cp /usr/share/applications/code.desktop /home/kasm-user/.local/share/applications/code.desktop
code --no-sandbox --user-data-dir ~/.config/Code --install-extension infosec-intern.yara
code --no-sandbox --user-data-dir ~/.config/Code --install-extension avast-threatlabs-yara.vscode-yls
echo "VS Code should now be ready."

# Cleanup for app layer
echo "Step 5: Cleaning up..."
chown -R 1000:0 $HOME
find /usr/share/ -name "icon-theme.cache" -exec rm -f {} \;
if [ -z ${SKIP_CLEAN+x} ]; then
  apt-get autoclean
  rm -rf \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /tmp/*
fi

echo "InfoSec Yara Environment is now installed!"