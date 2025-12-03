# Copied from official KasmTech repo at "https://github.com/kasmtech/workspaces-images/blob/develop/src/ubuntu/install/"
# Modified to remove non-ubuntu references and apply updated logic
#!/usr/bin/env bash
set -ex

echo "======= Installing Chrome ======="

echo "Step 1: Check CPU Architecture and set arguments..."
# set arguments
CHROME_ARGS="--password-store=basic --no-sandbox --ignore-gpu-blocklist --user-data-dir --no-first-run --disable-search-engine-choice-screen --simulate-outdated-no-au='Tue, 31 Dec 2099 23:59:59 GMT'"
CHROME_VERSION=$1
# check the cpu architecture
ARCH=$(arch | sed 's/aarch64/arm64/g' | sed 's/x86_64/amd64/g')
if [ "$ARCH" == "arm64" ] ; then
  echo "Chrome not supported on arm64, skipping Chrome installation"
  exit 0
fi	

echo "Step 2: Download and Install..."
# if there is no chrome installed, then download it
if [ ! -z "${CHROME_VERSION}" ]; then
  wget -q https://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_${CHROME_VERSION}_amd64.deb -O chrome.deb --no-check-certificate
else
  wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O chrome.deb --no-check-certificate
fi
# finally install the app
apt-get install -y ./chrome.deb
rm chrome.deb
# do a little cleanup after install
if [ -z ${SKIP_CLEAN+x} ]; then
  apt-get autoclean
  rm -rf \
    /var/lib/apt/lists/* \
    /var/tmp/*
fi

echo "Step 3: Set App Files and Preferences"

sed -i 's/-stable//g' /usr/share/applications/google-chrome.desktop
# copy the icon and set ownership
cp /usr/share/applications/google-chrome.desktop $HOME/Desktop/
chown 1000:1000 $HOME/Desktop/google-chrome.desktop
chmod +x $HOME/Desktop/google-chrome.desktop
# move the chrome bin over
mv /usr/bin/google-chrome /usr/bin/google-chrome-orig
# create preferences file
cat >/usr/bin/google-chrome <<EOL
#!/usr/bin/env bash

supports_vulkan() {
  # Needs the CLI tool
  command -v vulkaninfo >/dev/null 2>&1 || return 1

  # Look for any non-CPU device
  DISPLAY= vulkaninfo --summary 2>/dev/null |
    grep -qE 'PHYSICAL_DEVICE_TYPE_(INTEGRATED_GPU|DISCRETE_GPU|VIRTUAL_GPU)'
}

if ! pgrep chrome > /dev/null;then
  rm -f \$HOME/.config/google-chrome/Singleton*
fi
sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' ~/.config/google-chrome/Default/Preferences
sed -i 's/"exit_type":"Crashed"/"exit_type":"None"/' ~/.config/google-chrome/Default/Preferences

VULKAN_FLAGS=
if supports_vulkan; then
  VULKAN_FLAGS="--use-angle=vulkan"
  echo 'vulkan supported'
fi

if [ -f /opt/VirtualGL/bin/vglrun ] && [ ! -z "\${KASM_EGL_CARD}" ] && [ ! -z "\${KASM_RENDERD}" ] && [ -O "\${KASM_RENDERD}" ] && [ -O "\${KASM_EGL_CARD}" ] ; then
    echo "Starting Chrome with GPU Acceleration on EGL device \${KASM_EGL_CARD}"
    vglrun -d "\${KASM_EGL_CARD}" /opt/google/chrome/google-chrome ${CHROME_ARGS} "\${VULKAN_FLAGS}" "\$@" 
else
    echo "Starting Chrome"
    /opt/google/chrome/google-chrome ${CHROME_ARGS} "\${VULKAN_FLAGS}" "\$@"
fi
EOL
# add permissions to that preferences file and copy to correct folder
chmod +x /usr/bin/google-chrome
cp /usr/bin/google-chrome /usr/bin/chrome
# set the default browser
sed -i 's@exec -a "$0" "$HERE/google-chrome" "$\@"@@g' /usr/bin/x-www-browser
cat >>/usr/bin/x-www-browser <<EOL
exec -a "\$0" "\$HERE/chrome" "${CHROME_ARGS}"  "\$@"
EOL

echo "Step 4: Add managed policies..."
mkdir -p /etc/opt/chrome/policies/managed/
cat >>/etc/opt/chrome/policies/managed/default_managed_policy.json <<EOL
{"CommandLineFlagSecurityWarningsEnabled": false, "DefaultBrowserSettingEnabled": false, "PrivacySandboxPromptEnabled": false}
EOL

echo "Step 5: Cleaning up..."
# Cleanup for app layer
chown -R 1000:0 $HOME
find /usr/share/ -name "icon-theme.cache" -exec rm -f {} \;

echo "Chrome now installed!"