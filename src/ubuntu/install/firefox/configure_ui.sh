#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
# Purpose: Hardens Firefox and sets Desktop integration.
###############################################################################
set -euo pipefail

log() { echo "[FIREFOX-UI] $*"; }

KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")
# shellcheck source=/dev/null
source "${INST_DIR:-/dockerstartup/install}/ubuntu/install/common/10_desktop_icon.sh"

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

log "Step 2: Desktop integration..."
SRC_DESKTOP="/usr/share/applications/firefox.desktop"
# Normalise the icon on the source so the menu + desktop entries match.
[ -f "$SRC_DESKTOP" ] && sed -i 's/^Icon=.*/Icon=firefox/g' "$SRC_DESKTOP"

# Desktop icon (opt-in via FIREFOX_DESKTOP_ICON; default ON for the browser)
desktop_icon firefox "$SRC_DESKTOP" true

log "Firefox configuration successfully applied."
