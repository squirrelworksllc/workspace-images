# Copied from official KasmTech repo at "https://github.com/kasmtech/workspaces-images/blob/develop/src/ubuntu/install/"
# Modified to remove non-ubuntu references and apply updated logic
#!/usr/bin/env bash
set -ex

echo "======= Installing Signal ======="
# Install Signal
echo "Step 1: Check the CPU Architecture..."
ARCH=$(arch | sed 's/aarch64/arm64/g' | sed 's/x86_64/amd64/g')
if [ "${ARCH}" == "arm64" ] ; then
    echo "Signal for arm64 currently not supported, skipping install"
    exit 0
fi

echo "Step 2: Download the GPG Key..."
# Signal only releases its desktop app under the xenial release, however it is compatible with all versions of Debian and Ubuntu that we support.
wget -qO /tmp/signal-desktop-keyring.gpg https://updates.signal.org/desktop/apt/keys.asc --no-check-certificate
apt-key add /tmp/signal-desktop-keyring.gpg

echo "Step 3: Create the apt list and install..."
echo "deb [arch=${ARCH}] https://updates.signal.org/desktop/apt xenial main" |  tee -a /etc/apt/sources.list.d/signal-xenial.list
apt-get update
apt-get install -y signal-desktop

# Desktop icon
echo "Step 3: Modify the desktop icon..."
# Modify the desktop file to include --no-sandbox
sed -i 's|Exec=/opt/Signal/signal-desktop %U|Exec=/opt/Signal/signal-desktop --no-sandbox %U|' /usr/share/applications/signal-desktop.desktop
cp /usr/share/applications/signal-desktop.desktop $HOME/Desktop/
chmod +x $HOME/Desktop/signal-desktop.desktop

# Cleanup for app layer
echo "Step 4: Cleaning up..."
chown -R 1000:0 $HOME
find /usr/share/ -name "icon-theme.cache" -exec rm -f {} \;
if [ -z ${SKIP_CLEAN+x} ]; then
  apt-get autoclean
  rm -rf \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /tmp/*
fi

echo "Signal is now Installed!"