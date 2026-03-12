#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
# Purpose: Advanced Binary Wrapper + Desktop Integration for Chromium
###############################################################################
set -euo pipefail

log() { echo "[CHROMIUM-UI] $*"; }

# 1. Managed Policies (Hardening)
log "Step 1: Injecting Managed Policies..."
mkdir -p /etc/chromium/policies/managed/
cat <<EOF > /etc/chromium/policies/managed/squirrelworks_policy.json
{
  "CommandLineFlagSecurityWarningsEnabled": false,
  "DefaultBrowserSettingEnabled": false,
  "BackgroundModeEnabled": false,
  "MetricsReportingEnabled": false,
  "SyncDisabled": true,
  "ComponentUpdatesEnabled": false
}
EOF

# 2. Binary Wrapper (Merging your Vulkan/VirtualGL logic)
log "Step 2: Creating Binary Wrapper..."
CHROME_ARGS="--password-store=basic --no-sandbox --ignore-gpu-blocklist --user-data-dir --no-first-run --simulate-outdated-no-au='Tue, 31 Dec 2099 23:59:59 GMT' --disable-gpu"

# Determine the binary name (Ubuntu/Debian usually just use 'chromium')
REAL_BIN="chromium"
[ -f /usr/bin/chromium-browser ] && REAL_BIN="chromium-browser"

mv "/usr/bin/${REAL_BIN}" "/usr/bin/${REAL_BIN}-orig"

cat <<EOF > "/usr/bin/${REAL_BIN}"
#!/usr/bin/env bash
supports_vulkan() {
    command -v vulkaninfo >/dev/null 2>&1 || return 1
    vulkaninfo --summary 2>/dev/null | grep -qE 'PHYSICAL_DEVICE_TYPE_(INTEGRATED_GPU|DISCRETE_GPU|VIRTUAL_GPU)'
}

VULKAN_FLAGS=""
supports_vulkan && VULKAN_FLAGS="--use-angle=vulkan"

if [ -f /opt/VirtualGL/bin/vglrun ] && [ -n "\${KASM_EGL_CARD:-}" ] && [ -n "\${KASM_RENDERD:-}" ]; then
    exec /opt/VirtualGL/bin/vglrun -d "\${KASM_EGL_CARD}" "/usr/bin/${REAL_BIN}-orig" $CHROME_ARGS \$VULKAN_FLAGS "\$@"
else
    exec "/usr/bin/${REAL_BIN}-orig" $CHROME_ARGS \$VULKAN_FLAGS "\$@"
fi
EOF

chmod +x "/usr/bin/${REAL_BIN}"

# 3. Desktop Shortcut
log "Step 3: Deploying Desktop Shortcut..."
KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")
SRC_DESKTOP="/usr/share/applications/${REAL_BIN}.desktop"

if [ -f "$SRC_DESKTOP" ]; then
    mkdir -p "$KASM_HOME/Desktop"
    cp "$SRC_DESKTOP" "$KASM_HOME/Desktop/Chromium.desktop"
    chmod +x "$KASM_HOME/Desktop/Chromium.desktop"
    chown -R 1000:1000 "$KASM_HOME/Desktop"
fi
