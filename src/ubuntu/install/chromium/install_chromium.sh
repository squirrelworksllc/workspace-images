# Copied from official KasmTech repo at "https://github.com/kasmtech/workspaces-images/blob/develop/src/ubuntu/install/"
#!/usr/bin/env bash
set -ex

echo "======= Installing Chromium ======="

echo "Step 1: Check CPU Architecture and set arguments..."
# set arguments
CHROME_ARGS="--password-store=basic --no-sandbox  --ignore-gpu-blocklist --user-data-dir --no-first-run --simulate-outdated-no-au='Tue, 31 Dec 2099 23:59:59 GMT'"
ARCH=$(arch | sed 's/aarch64/arm64/g' | sed 's/x86_64/amd64/g')
# check architecture
if [[ "${DISTRO}" == @(debian|opensuse|ubuntu) ]] && [ ${ARCH} = 'amd64' ] && [ ! -z ${SKIP_CLEAN+x} ]; then
  echo "not installing chromium on x86_64 desktop build"
  exit 0
fi

echo "Step 2: Download and Install..."
# if this is Kali, ParrotOS or regular Debian...
if grep -q "ID=debian" /etc/os-release || grep -q "ID=kali" /etc/os-release || grep -q "ID=parrot" /etc/os-release; then
  apt-get update
  apt-get install -y chromium
  if [ -z ${SKIP_CLEAN+x} ]; then
  apt-get autoclean
  rm -rf \
    /var/lib/apt/lists/* \
    /var/tmp/*
  fi
else # else assume Ubuntu...
  apt-get update
  apt-get install -y software-properties-common ttf-mscorefonts-installer
  apt-get remove -y chromium-browser-l10n chromium-codecs-ffmpeg chromium-browser

  # Install from debian bookworm repos
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://ftp-master.debian.org/keys/archive-key-12.asc | sudo tee /etc/apt/keyrings/debian-archive-key-12.asc
  echo "deb [signed-by=/etc/apt/keyrings/debian-archive-key-12.asc] http://deb.debian.org/debian bookworm main" | sudo tee /etc/apt/sources.list.d/debian-bookworm.list
  echo -e "Package: *\nPin: release a=bookworm\nPin-Priority: 100" | sudo tee /etc/apt/preferences.d/debian-bookworm
  apt-get update
  apt install -y chromium --no-install-recommends

  # Cleanup debian bookworm repos
  rm /etc/apt/sources.list.d/debian-bookworm.list
  rm /etc/apt/preferences.d/debian-bookworm
  rm /etc/apt/keyrings/debian-archive-key-12.asc
  apt-get update

  if [ -z ${SKIP_CLEAN+x} ]; then
  apt-get autoclean
  rm -rf \
    /var/lib/apt/lists/* \
    /var/tmp/*
  fi

fi
# set the bin path
if grep -q "ID=debian" /etc/os-release || grep -q "ID=kali" /etc/os-release || grep -q "ID=parrot" /etc/os-release || grep -q "ID=ubuntu" /etc/os-release; then
  REAL_BIN=chromium
else
  REAL_BIN=chromium-browser
fi

# Modify desktop icon
echo "Step 3: Modify the Desktop icon..."
sed -i 's/-stable//g' /usr/share/applications/${REAL_BIN}.desktop

if ! grep -q "ID=kali" /etc/os-release; then
  cp /usr/share/applications/${REAL_BIN}.desktop $HOME/Desktop/
  chmod +x $HOME/Desktop/${REAL_BIN}.desktop
  chown 1000:1000 $HOME/Desktop/${REAL_BIN}.desktop
fi

# Set and configure Bin
echo "Step 4: Set up the Bin..."
mv /usr/bin/${REAL_BIN} /usr/bin/${REAL_BIN}-orig
cat >/usr/bin/${REAL_BIN} <<EOL
#!/usr/bin/env bash

supports_vulkan() {
  # Needs the CLI tool
  command -v vulkaninfo >/dev/null 2>&1 || return 1

  # Look for any non-CPU device
  DISPLAY= vulkaninfo --summary 2>/dev/null |
    grep -qE 'PHYSICAL_DEVICE_TYPE_(INTEGRATED_GPU|DISCRETE_GPU|VIRTUAL_GPU)'
}

if ! pgrep chromium > /dev/null;then
  rm -f \$HOME/.config/chromium/Singleton*
fi
sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' ~/.config/chromium/Default/Preferences
sed -i 's/"exit_type":"Crashed"/"exit_type":"None"/' ~/.config/chromium/Default/Preferences

VULKAN_FLAGS=
if supports_vulkan; then
  VULKAN_FLAGS="--use-angle=vulkan"
  echo 'vulkan supported'
fi

if [ -f /opt/VirtualGL/bin/vglrun ] && [ ! -z "\${KASM_EGL_CARD}" ] && [ ! -z "\${KASM_RENDERD}" ] && [ -O "\${KASM_RENDERD}" ] && [ -O "\${KASM_EGL_CARD}" ] ; then
    echo "Starting Chrome with GPU Acceleration on EGL device \${KASM_EGL_CARD}"
    vglrun -d "\${KASM_EGL_CARD}" /usr/bin/${REAL_BIN}-orig ${CHROME_ARGS} "\${VULKAN_FLAGS}" "\$@" 
else
    echo "Starting Chrome"
    /usr/bin/${REAL_BIN}-orig ${CHROME_ARGS} "\${VULKAN_FLAGS}" "\$@"
fi
EOL
chmod +x /usr/bin/${REAL_BIN}

# final configurations
echo "Step 5: Final Configurations..."
sed -i 's@exec -a "$0" "$HERE/chromium-browser" "$\@"@@g' /usr/bin/x-www-browser
cat >>/usr/bin/x-www-browser <<EOL
exec -a "\$0" "\$HERE/chromium" "${CHROME_ARGS}"  "\$@"

mkdir -p /etc/chromium/policies/managed/
cat >>/etc/chromium/policies/managed/default_managed_policy.json <<EOL
{"CommandLineFlagSecurityWarningsEnabled": false, "DefaultBrowserSettingEnabled": false}
EOL

# Cleanup for app layer
echo "Step 6: Cleaning Up..."
chown -R 1000:0 $HOME
find /usr/share/ -name "icon-theme.cache" -exec rm -f {} \;

echo "Chromium is now Installed!"