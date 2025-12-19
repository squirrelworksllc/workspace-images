#!/usr/bin/env bash
# Script to install Microsoft Edge. This script is meant to be called from a Dockerfile
# and may not work on it's own.
set -euo pipefail
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

echo "======= Installing Microsoft Edge ======="

CHROME_ARGS="--password-store=basic --no-sandbox --ignore-gpu-blocklist --user-data-dir --no-first-run --simulate-outdated-no-au='Tue, 31 Dec 2099 23:59:59 GMT'"

# deps
apt_update_if_needed
apt_install curl ca-certificates gnupg

. /etc/os-release

# Determine Microsoft repo config package URL (packages-microsoft-prod.deb)
# Microsoft publishes per-distro config packages under:
# https://packages.microsoft.com/config/<distribution>/<version>/packages-microsoft-prod.deb :contentReference[oaicite:2]{index=2}
MSCFG_URL=""

case "${ID}" in
  ubuntu)
    # VERSION_ID is like "24.04"
    if [ -z "${VERSION_ID:-}" ]; then
      echo "VERSION_ID missing; cannot determine Microsoft repo config package for Ubuntu." >&2
      exit 1
    fi
    MSCFG_URL="https://packages.microsoft.com/config/ubuntu/${VERSION_ID}/packages-microsoft-prod.deb"
    ;;
  debian)
    # VERSION_ID is like "12"
    if [ -z "${VERSION_ID:-}" ]; then
      echo "VERSION_ID missing; cannot determine Microsoft repo config package for Debian." >&2
      exit 1
    fi
    DEB_MAJOR="${VERSION_ID%%.*}"
    MSCFG_URL="https://packages.microsoft.com/config/debian/${DEB_MAJOR}/packages-microsoft-prod.deb"
    ;;
  kali)
    # Kali is Debian-based; use Debian major version if available.
    # If Kali doesn't provide VERSION_ID, default to Debian 12 (current common base).
    DEB_MAJOR="${VERSION_ID:-12}"
    DEB_MAJOR="${DEB_MAJOR%%.*}"
    MSCFG_URL="https://packages.microsoft.com/config/debian/${DEB_MAJOR}/packages-microsoft-prod.deb"
    ;;
  *)
    echo "Unsupported distro for Edge installer: ${ID}" >&2
    exit 1
    ;;
esac

echo "Using Microsoft repo config: ${MSCFG_URL}"

# Install Microsoft repo config package
curl -fsSL -o /tmp/packages-microsoft-prod.deb "${MSCFG_URL}"
dpkg -i /tmp/packages-microsoft-prod.deb
rm -f /tmp/packages-microsoft-prod.deb

# Repo changed -> refresh
apt_refresh_after_repo_change

# Install Edge
apt_install microsoft-edge-stable

# Desktop shortcut
mkdir -p "$HOME/Desktop"
if [ -f /usr/share/applications/microsoft-edge.desktop ]; then
  cp /usr/share/applications/microsoft-edge.desktop "$HOME/Desktop/microsoft-edge.desktop"
  chmod +x "$HOME/Desktop/microsoft-edge.desktop"
  chown 1000:1000 "$HOME/Desktop/microsoft-edge.desktop" || true
fi

# Wrapper (idempotent-ish)
if [ -f /usr/bin/microsoft-edge-stable ] && [ ! -f /usr/bin/microsoft-edge-stable-orig ]; then
  mv /usr/bin/microsoft-edge-stable /usr/bin/microsoft-edge-stable-orig
fi

cat >/usr/bin/microsoft-edge-stable <<EOL
#!/usr/bin/env bash

supports_vulkan() {
  command -v vulkaninfo >/dev/null 2>&1 || return 1
  DISPLAY= vulkaninfo --summary 2>/dev/null |
    grep -qE 'PHYSICAL_DEVICE_TYPE_(INTEGRATED_GPU|DISCRETE_GPU|VIRTUAL_GPU)'
}

PREF="\$HOME/.config/microsoft-edge/Default/Preferences"
if [ -f "\$PREF" ]; then
  sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' "\$PREF" || true
  sed -i 's/"exit_type":"Crashed"/"exit_type":"None"/' "\$PREF" || true
fi

VULKAN_FLAGS=
if supports_vulkan; then
  VULKAN_FLAGS="--use-angle=vulkan"
fi

if [ -f /opt/VirtualGL/bin/vglrun ] && [ -n "\${KASM_EGL_CARD:-}" ] && [ -n "\${KASM_RENDERD:-}" ] && [ -O "\${KASM_RENDERD}" ] && [ -O "\${KASM_EGL_CARD}" ]; then
  exec vglrun -d "\${KASM_EGL_CARD}" /opt/microsoft/msedge/microsoft-edge ${CHROME_ARGS} \${VULKAN_FLAGS} "\$@"
else
  exec /opt/microsoft/msedge/microsoft-edge ${CHROME_ARGS} \${VULKAN_FLAGS} "\$@"
fi
EOL
chmod +x /usr/bin/microsoft-edge-stable

# Default browser: remove old edge lines, then add one
sed -i '/\$HERE\/microsoft-edge/d' /usr/bin/x-www-browser || true
echo "exec -a \"\$0\" \"\$HERE/microsoft-edge\" ${CHROME_ARGS} \"\$@\"" >> /usr/bin/x-www-browser

# Edge policies (overwrite, don’t append)
mkdir -p /etc/opt/edge/policies/managed/
cat >/etc/opt/edge/policies/managed/default_managed_policy.json <<'JSON'
{"CommandLineFlagSecurityWarningsEnabled": false, "DefaultBrowserSettingEnabled": false}
JSON

# Symlink Chrome policies into Edge so your web filtering policy path applies
mkdir -p /etc/opt/chrome/policies
mkdir -p /etc/opt/edge
ln -sfn /etc/opt/chrome/policies /etc/opt/edge/policies

echo "Edge installed!"
