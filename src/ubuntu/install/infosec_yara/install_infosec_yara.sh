# This script is designed to install the complete environment needed to test and/or develop YARA rules inside
# of a docker container. This includes a pre-defined Yara release, a Yara Language Server (YLS-Yara)
# and extensions for Visual Studio as well as commandline utilities.
# Although this script may work alone it was not designed to do so and was designed to be invoked via Dockerfile.
#!/usr/bin/env bash
set -ex

echo "======= Installing InfoSec Yara Environment ======="

# Install Dependencies
echo "Step 1: Installing Dependencies..."
apt-get update
apt-get install -y \
  automake libtool make gcc pkg-config libssl-dev \
  curl python3-pip python3-venv

# Download Yara 4.5.5 release and install
echo "Step 2: Download and Install Yara..."
cd /opt
curl -sSLo yara.tar.gz https://github.com/VirusTotal/yara/archive/refs/tags/v4.5.5.tar.gz
tar -zxf yara.tar.gz
cd /opt/yara-4.5.5
./bootstrap.sh
./configure
echo "Now Installing Yara 4.5.5..."
make install
ldconfig

# Download Yara's Python libraries
echo "Step 3: Set up Python environment and Yara tools..."
mkdir -p /opt/yara-env
cd /opt/yara-env
python3 -m venv env
. env/bin/activate
pip install --upgrade pip
pip install yara-python yls-yara
realpath env/bin/yls
deactivate

# Install VS Code extension
echo "Step 4: Prep and Install VS Code extension..."
# Make sure config dir exists for this user
mkdir -p "$HOME/.config/Code"
# Optional: tweak the desktop file if you really need to
cd /usr/share/applications
sed -i 's%--new-window% --no-sandbox --disable-workspace-trust --new-window%' code.desktop || true
sed -i 's%--unity-launch% --no-sandbox --disable-workspace-trust --new-window%' code.desktop || true
# Copy desktop file into user space (optional, but you had it)
mkdir -p "$HOME/.local/share/applications"
cp /usr/share/applications/code.desktop "$HOME/.local/share/applications/code.desktop" || true
# Install the extensions for the current user ($HOME depends on Dockerfile USER)
code --no-sandbox --user-data-dir "$HOME/.config/Code" \
  --install-extension infosec-intern.yara
code --no-sandbox --user-data-dir "$HOME/.config/Code" \
  --install-extension avast-threatlabs-yara.vscode-yls
echo "VS Code should now be ready."

# Cleanup for app layer
echo "Step 5: Cleaning up..."
chown -R 1000:0 "$HOME"
find /usr/share/ -name "icon-theme.cache" -exec rm -f {} \;
if [ -z "${SKIP_CLEAN+x}" ]; then
  apt-get autoclean
  rm -rf \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /tmp/*
fi

echo "InfoSec Yara Environment is now installed!"