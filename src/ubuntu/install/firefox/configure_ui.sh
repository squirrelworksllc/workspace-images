#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
# Purpose: Hardens Firefox and sets Desktop integration.
###############################################################################
set -euo pipefail

log() { echo "[FIREFOX-UI] $*"; }

KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")

log "Step 1: Applying Global Hardening Policies..."
POL_DIR="/usr/lib/firefox/distribution"
mkdir -p "$POL_DIR"

# This kills telemetry, pocket, and first-run tabs globally
cat <<EOF > "$POL_DIR/policies.json"
{
  "policies": {
    "DisableAppUpdate": true,
    "DisableFirefoxScreenshots": true,
    "DisableFirefoxStudies": true,
    "DisablePocket": true,
    "DisableTelemetry": true,
    "OverrideFirstRunPage": "",
    "OverridePostUpdatePage": "",
    "DontCheckDefaultBrowser": true,
    "DisplayBookmarksToolbar": "never",
    "SearchBar": "unified"
  }
}
EOF

log "Step 2: Deploying Desktop Shortcut..."
# We use the system-generated desktop file but fix the icon path
SRC_DESKTOP="/usr/share/applications/firefox.desktop"
if [ -f "$SRC_DESKTOP" ]; then
    mkdir -p "$KASM_HOME/Desktop"
    cp "$SRC_DESKTOP" "$KASM_HOME/Desktop/firefox.desktop"
    # Ensure the icon path is standard
    sed -i 's/^Icon=.*/Icon=firefox/g' "$KASM_HOME/Desktop/firefox.desktop"
    chmod +x "$KASM_HOME/Desktop/firefox.desktop"
fi

chown -R 1000:1000 "$KASM_HOME/Desktop"

log "Firefox configuration successfully applied."
