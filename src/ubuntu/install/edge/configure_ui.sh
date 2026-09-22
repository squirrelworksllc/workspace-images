#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
# Purpose: Managed Policies + Advanced Binary Wrapper for Edge
###############################################################################
set -euo pipefail

log() { echo "[EDGE-UI] $*"; }

# 1. Edge-Specific Managed Policies
log "Step 1: Injecting Microsoft Edge Managed Policies..."
mkdir -p /etc/opt/edge/policies/managed/
cat <<EOF > /etc/opt/edge/policies/managed/squirrelworks_edge_policy.json
{
  "BackgroundModeEnabled": false,
  "MetricsReportingEnabled": false,
  "HubsSidebarEnabled": false,
  "EdgeShoppingAssistantEnabled": false,
  "EdgeCollectionsEnabled": false,
  "EdgeWalletEnabled": false,
  "ShowWaybackMachineMessage": false,
  "InPrivateModeAvailability": 0,
  "SyncDisabled": true,
  "PasswordManagerEnabled": false,
  "CommandLineFlagSecurityWarningsEnabled": false
}
EOF

# 2. Binary Wrapper (Merging your logic)
log "Step 2: Creating Advanced Binary Wrapper..."
EDGE_ARGS="--password-store=basic --no-sandbox --ignore-gpu-blocklist --user-data-dir --no-first-run --simulate-outdated-no-au='Tue, 31 Dec 2099 23:59:59 GMT' --disable-gpu"

# Idempotent: only shift the real binary aside once
# (an && chain here would trip `set -e` on the no-op re-run)
if [ -f /usr/bin/microsoft-edge-stable ] && [ ! -f /usr/bin/microsoft-edge-stable-orig ]; then
    mv /usr/bin/microsoft-edge-stable /usr/bin/microsoft-edge-stable-orig
fi

cat <<EOF > /usr/bin/microsoft-edge-stable
#!/usr/bin/env bash
supports_vulkan() {
    command -v vulkaninfo >/dev/null 2>&1 || return 1
    vulkaninfo --summary 2>/dev/null | grep -qE 'PHYSICAL_DEVICE_TYPE_(INTEGRATED_GPU|DISCRETE_GPU|VIRTUAL_GPU)'
}

VULKAN_FLAGS=""
supports_vulkan && VULKAN_FLAGS="--use-angle=vulkan"

if [ -f /opt/VirtualGL/bin/vglrun ] && [ -n "\${KASM_EGL_CARD:-}" ] && [ -n "\${KASM_RENDERD:-}" ]; then
    exec /opt/VirtualGL/bin/vglrun -d "\${KASM_EGL_CARD}" /usr/bin/microsoft-edge-stable-orig $EDGE_ARGS \$VULKAN_FLAGS "\$@"
else
    exec /usr/bin/microsoft-edge-stable-orig $EDGE_ARGS \$VULKAN_FLAGS "\$@"
fi
EOF

chmod +x /usr/bin/microsoft-edge-stable

# 3. Desktop icon (opt-in via EDGE_DESKTOP_ICON=true; default off)
# shellcheck source=/dev/null
source "${INST_DIR:-/dockerstartup/install}/ubuntu/install/common/10_desktop_icon.sh"
desktop_icon edge /usr/share/applications/microsoft-edge.desktop false
