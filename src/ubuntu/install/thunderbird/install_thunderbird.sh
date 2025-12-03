# Copied from official KasmTech repo at "https://github.com/kasmtech/workspaces-images/blob/develop/src/ubuntu/install/"
#!/usr/bin/env bash
set -ex

echo "======= Installing Thunderbird ======="

# If OS is Non-Ubuntu Debian Variant
echo "Step 1: Download and Install..."
if grep -q "ID=debian" /etc/os-release; then
  apt-get update
  apt-get install -y thunderbird
  if [ -z ${SKIP_CLEAN+x} ]; then
  apt-get autoclean
  rm -rf \
    /var/lib/apt/lists/* \
    /var/tmp/*
  fi
else # else, assume Ubuntu
  apt-get update
  if [ ! -f '/etc/apt/preferences.d/mozilla-firefox' ]; then
    add-apt-repository -y ppa:mozillateam/ppa
    echo '
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001
' > /etc/apt/preferences.d/mozilla-firefox
  fi
  apt-get install -y thunderbird
  if [ -z ${SKIP_CLEAN+x} ]; then
  apt-get autoclean
  rm -rf \
    /var/lib/apt/lists/* \
    /var/tmp/*
  fi
fi

# Desktop icon
echo "Step 2: Modify the desktop icon..."
cp /usr/share/applications/thunderbird.desktop $HOME/Desktop/
chmod +x $HOME/Desktop/thunderbird.desktop

# Cleanup for app layer
echo "Step 3: Cleaning Up..."
chown -R 1000:0 $HOME
find /usr/share/ -name "icon-theme.cache" -exec rm -f {} \;

echo "Thunderbird is now Installed!"