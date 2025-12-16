#!/usr/bin/env bash
# Customized script to install Chromium. Depends on an environmental of "Install_Chrome" being either true/false
# in the dockerfile this script is invoked from.
set -euo pipefail
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

echo "======= Installing Chromium ======="

. /etc/os-release
ARCH="$(dpkg --print-architecture)"

echo "Step 1: Set arguments..."
CHROME_ARGS="--password-store=basic --no-sandbox --ignore-gpu-blocklist --user-data-dir --no-first-run --simulate-outdated-no-au='Tue, 31 Dec 2099 23:59:59 GMT'"

# If Chrome is installed in this image, Chromium is redundant.
# Set INSTALL_CHROME=true (or SKIP_CHROMIUM=true) from the Dockerfile to skip.
: "${INSTALL_CHROME:=false}"
: "${SKIP_CHROMIUM:=false}"

if [ "${INSTALL_CHROME}" = "true" ] || [ "${SKIP_CHROMIUM}" = "true" ]; then
  echo "Chrome is installed (or SKIP_CHROMIUM=true); skipping Chromium."
  exit 0
fi


echo "Step 2: Install..."
apt_update_if_needed

if [ "${ID}" = "debian" ] || [ "${ID}" = "kali" ] || [ "${ID}" = "parrot" ]; then
  apt_install chromium
else
  # Ubuntu path: avoid snap chromium by using Debian repo workaround (if that's your intent)
  apt_install curl ca-certificates software-properties-common ttf-mscorefonts-installer

  # Remove any conflicting ubuntu chromium packages (ok if absent)
  apt-get remove -y chromium-browser-l10n chromium-codecs-ffmpeg chromium-browser || true

  # Add Debian bookworm repo JUST for chromium (tight pinning recommended)
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://ftp-master.debian.org/keys/archive-key-12.asc \
    -o /etc/apt/keyrings/debian-archive-key-12.asc

  cat >/etc/apt/sources.list.d/debian-bookworm.list <<'EOF'
deb [signed-by=/etc/apt/keyrings/debian-archive-key-12.asc] http://deb.debian.org/debian bookworm main
EOF

  # TODO: tighten pinning to only chromium packages
  cat >/etc/apt/preferences.d/debian-bookworm <<'EOF'
Package: chromium chromium-common chromium-sandbox chromium-l10n
Pin: release n=bookworm
Pin-Priority: 990
EOF

  apt_refresh_after_repo_change
  apt_install chromium

  # remove bookworm repo + pins
  rm -f /etc/apt/sources.list.d/debian-bookworm.list \
        /etc/apt/preferences.d/debian-bookworm \
        /etc/apt/keyrings/debian-archive-key-12.asc

  apt_refresh_after_repo_change
fi

REAL_BIN="chromium"
# some distros use chromium-browser; adjust only if you truly support them
if [ "${ID}" != "ubuntu" ] && [ "${ID}" != "debian" ] && [ "${ID}" != "kali" ] && [ "${ID}" != "parrot" ]; then
  REAL_BIN="chromium-browser"
fi

echo "Step 3: Modify desktop icon..."
mkdir -p "$HOME/Desktop"
sed -i 's/-stable//g' "/usr/share/applications/${REAL_BIN}.desktop" || true

if [ "${ID}" != "kali" ]; then
  cp "/usr/share/applications/${REAL_BIN}.desktop" "$HOME/Desktop/"
  chmod +x "$HOME/Desktop/${REAL_BIN}.desktop"
  chown 1000:1000 "$HOME/Desktop/${REAL_BIN}.desktop" || true
fi

echo "Step 4: Setting wrapper..."
mv "/usr/bin/${REAL_BIN}" "/usr/bin/${REAL_BIN}-orig"
cat >"/usr/bin/${REAL_BIN}" <<EOL
#!/usr/bin/env bash
if ! pgrep chromium >/dev/null 2>&1; then
  rm -f "\$HOME/.config/chromium/Singleton"* 2>/dev/null || true
fi

VULKAN_FLAGS=
if command -v vulkaninfo >/dev/null 2>&1; then
  if DISPLAY= vulkaninfo --summary 2>/dev/null | grep -qE 'PHYSICAL_DEVICE_TYPE_(INTEGRATED_GPU|DISCRETE_GPU|VIRTUAL_GPU)'; then
    VULKAN_FLAGS="--use-angle=vulkan"
  fi
fi

if [ -f /opt/VirtualGL/bin/vglrun ] && [ -n "\${KASM_EGL_CARD:-}" ] && [ -n "\${KASM_RENDERD:-}" ] && [ -O "\${KASM_RENDERD}" ] && [ -O "\${KASM_EGL_CARD}" ]; then
  exec vglrun -d "\${KASM_EGL_CARD}" /usr/bin/${REAL_BIN}-orig ${CHROME_ARGS} \${VULKAN_FLAGS} "\$@"
else
  exec /usr/bin/${REAL_BIN}-orig ${CHROME_ARGS} \${VULKAN_FLAGS} "\$@"
fi
EOL
chmod +x "/usr/bin/${REAL_BIN}"

echo "Step 5: Configuring any added policies..."
mkdir -p /etc/chromium/policies/managed/
cat >/etc/chromium/policies/managed/default_managed_policy.json <<'JSON'
{"CommandLineFlagSecurityWarningsEnabled": false, "DefaultBrowserSettingEnabled": false}
JSON

echo "Chromium is now Installed!"
