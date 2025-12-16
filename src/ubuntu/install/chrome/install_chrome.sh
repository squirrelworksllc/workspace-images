#!/usr/bin/env bash
# Custom script to install Google Chrome
set -euo pipefail
source ${INST_DIR}/ubuntu/install/common/00_apt_helper.sh

echo "======= Installing Chrome ======="

echo "Step 1: Check CPU Architecture and set arguments..."
CHROME_ARGS="--password-store=basic --no-sandbox --ignore-gpu-blocklist --user-data-dir --no-first-run --disable-search-engine-choice-screen --simulate-outdated-no-au='Tue, 31 Dec 2099 23:59:59 GMT'"
CHROME_VERSION="${1:-}"

ARCH="$(dpkg --print-architecture)"
if [ "${ARCH}" = "arm64" ]; then
  echo "Chrome not supported on arm64, skipping Chrome installation"
  exit 0
fi

echo "Step 2: Download and Install..."
apt_update_if_needed

if [ -n "${CHROME_VERSION}" ]; then
  wget -q "https://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_${CHROME_VERSION}_amd64.deb" -O /tmp/chrome.deb
else
  wget -q "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" -O /tmp/chrome.deb
fi

apt-get install -y /tmp/chrome.deb
rm -f /tmp/chrome.deb

echo "Step 3: Set App Files and Preferences..."
mkdir -p "$HOME/Desktop"
sed -i 's/-stable//g' /usr/share/applications/google-chrome.desktop || true
cp /usr/share/applications/google-chrome.desktop "$HOME/Desktop/"
chown 1000:1000 "$HOME/Desktop/google-chrome.desktop" || true
chmod +x "$HOME/Desktop/google-chrome.desktop"

mv /usr/bin/google-chrome /usr/bin/google-chrome-orig

cat >/usr/bin/google-chrome <<EOL
#!/usr/bin/env bash

supports_vulkan() {
  command -v vulkaninfo >/dev/null 2>&1 || return 1
  DISPLAY= vulkaninfo --summary 2>/dev/null |
    grep -qE 'PHYSICAL_DEVICE_TYPE_(INTEGRATED_GPU|DISCRETE_GPU|VIRTUAL_GPU)'
}

if ! pgrep chrome > /dev/null 2>&1; then
  rm -f "\$HOME/.config/google-chrome/Singleton"* 2>/dev/null || true
fi

if [ -f "\$HOME/.config/google-chrome/Default/Preferences" ]; then
  sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' "\$HOME/.config/google-chrome/Default/Preferences" || true
  sed -i 's/"exit_type":"Crashed"/"exit_type":"None"/' "\$HOME/.config/google-chrome/Default/Preferences" || true
fi

VULKAN_FLAGS=
if supports_vulkan; then
  VULKAN_FLAGS="--use-angle=vulkan"
fi

if [ -f /opt/VirtualGL/bin/vglrun ] && [ -n "\${KASM_EGL_CARD:-}" ] && [ -n "\${KASM_RENDERD:-}" ] && [ -O "\${KASM_RENDERD}" ] && [ -O "\${KASM_EGL_CARD}" ]; then
  exec vglrun -d "\${KASM_EGL_CARD}" /opt/google/chrome/google-chrome ${CHROME_ARGS} \${VULKAN_FLAGS} "\$@"
else
  exec /opt/google/chrome/google-chrome ${CHROME_ARGS} \${VULKAN_FLAGS} "\$@"
fi
EOL

chmod +x /usr/bin/google-chrome
cp /usr/bin/google-chrome /usr/bin/chrome

echo "Step 4: Set default browser + managed policies..."
# make x-www-browser deterministic: remove prior chrome exec lines then add one
sed -i '/\$HERE\/chrome/d' /usr/bin/x-www-browser || true
echo "exec -a \"\$0\" \"\$HERE/chrome\" ${CHROME_ARGS} \"\$@\"" >> /usr/bin/x-www-browser

mkdir -p /etc/opt/chrome/policies/managed/
cat >/etc/opt/chrome/policies/managed/default_managed_policy.json <<'JSON'
{"CommandLineFlagSecurityWarningsEnabled": false, "DefaultBrowserSettingEnabled": false, "PrivacySandboxPromptEnabled": false}
JSON

echo "Chrome now installed!"