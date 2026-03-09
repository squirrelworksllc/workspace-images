#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
# Purpose: Managed Policies + Advanced Binary Wrapper for Chrome
###############################################################################
set -euo pipefail

log() { echo "[CHROME-UI] $*"; }

# 1. Managed Policies (Merged your flags with my hardening)
log "Step 1: Injecting Managed Policies..."
mkdir -p /etc/opt/chrome/policies/managed/
cat <<EOF > /etc/opt/chrome/policies/managed/squirrelworks_policy.json
{
  "BackgroundModeEnabled": false,
  "MetricsReportingEnabled": false,
  "SyncDisabled": true,
  "PasswordManagerEnabled": false,
  "CommandLineFlagSecurityWarningsEnabled": false,
  "DefaultBrowserSettingEnabled": false,
  "PrivacySandboxPromptEnabled": false,
  "FirstRunTabs": [""],
  "ComponentUpdatesEnabled": false
}
EOF

# 2. Advanced Binary Wrapper (Merged Vulkan/VirtualGL logic)
log "Step 2: Creating Advanced Binary Wrapper..."
# Your arguments merged:
CHROME_ARGS="--password-store=basic --no-sandbox --ignore-gpu-blocklist --user-data-dir --no-first-run --disable-search-engine-choice-screen --simulate-outdated-no-au='Tue, 31 Dec 2099 23:59:59 GMT' --disable-gpu"

mv /usr/bin/google-chrome-stable /usr/bin/google-chrome-orig

cat <<EOF > /usr/bin/google-chrome-stable
#!/usr/bin/env bash
supports_vulkan() {
    command -v vulkaninfo >/dev/null 2>&1 || return 1
    vulkaninfo --summary 2>/dev/null | grep -qE 'PHYSICAL_DEVICE_TYPE_(INTEGRATED_GPU|DISCRETE_GPU|VIRTUAL_GPU)'
}

VULKAN_FLAGS=""
supports_vulkan && VULKAN_FLAGS="--use-angle=vulkan"

if [ -f /opt/VirtualGL/bin/vglrun ] && [ -n "\${KASM_EGL_CARD:-}" ] && [ -n "\${KASM_RENDERD:-}" ]; then
    exec /opt/VirtualGL/bin/vglrun -d "\${KASM_EGL_CARD}" /usr/bin/google-chrome-orig $CHROME_ARGS \$VULKAN_FLAGS "\$@"
else
    exec /usr/bin/google-chrome-orig $CHROME_ARGS \$VULKAN_FLAGS "\$@"
fi
EOF

chmod +x /usr/bin/google-chrome-stable
ln -sf /usr/bin/google-chrome-stable /usr/bin/chrome

# 3. Desktop Shortcut
log "Step 3: Deploying Desktop Shortcut..."
KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")
mkdir -p "\$KASM_HOME/Desktop"
cp /usr/share/applications/google-chrome.desktop "\$KASM_HOME/Desktop/"
chmod +x "\$KASM_HOME/Desktop/google-chrome.desktop"
chown -R 1000:1000 "\$KASM_HOME/Desktop"

log "Chrome UI configuration applied."
