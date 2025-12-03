# Copied from official KasmTech repo at "https://github.com/kasmtech/workspaces-images/blob/develop/src/ubuntu/install/"
# Modified to remove non-ubuntu references and apply updated logic
#!/usr/bin/env bash
set -ex

echo "======= Installing Slack ======="
echo "Step 1: Checking the CPU Architecture..."
ARCH=$(arch | sed 's/aarch64/arm64/g' | sed 's/x86_64/amd64/g')

if [ "${ARCH}" == "arm64" ] ; then
    echo "Slack for arm64 currently not supported, skipping install"
    exit 0
fi

# This might prove fragile depending on how often slack changes it's website.
echo "Step 2: Download and install the app..."
version=$(curl -q https://slack.com/downloads/linux | grep page-downloads__hero__meta-text__version | sed 's/.*Version //g' | cut -d "<" -f1 | head -1)
echo Detected slack version $version

wget -q https://downloads.slack-edge.com/desktop-releases/linux/x64/${version}/slack-desktop-${version}-amd64.deb
apt-get update
apt-get install -y ./slack-desktop-${version}-${ARCH}.deb
rm slack-desktop-${version}-${ARCH}.deb
if [ -z ${SKIP_CLEAN+x} ]; then
  apt-get autoclean
  rm -rf \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /tmp/*
fi

# Modify the desktop icon
echo "Step 3: Modify the desktop icon..."
sed -i 's,/usr/bin/slack,/usr/bin/slack --no-sandbox,g' /usr/share/applications/slack.desktop
cp /usr/share/applications/slack.desktop $HOME/Desktop/
chmod +x $HOME/Desktop/slack.desktop
chown 1000:1000 $HOME/Desktop/slack.desktop

# Cleanup for app layer
echo "Step 4: Cleaning up..."
chown -R 1000:0 $HOME
find /usr/share/ -name "icon-theme.cache" -exec rm -f {} \;

echo "Slack is now Installed!"