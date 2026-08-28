#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
#
# Purpose: Hardens Thunderbird and configures UI shortcuts.
###############################################################################
set -euo pipefail

log() { echo "[THUNDERBIRD-UI] $*"; }

# shellcheck source=/dev/null
source "${INST_DIR:-/dockerstartup/install}/ubuntu/install/common/10_desktop_icon.sh"

log "Step 1: Hardening Thunderbird (Disabling Telemetry & Noise)..."
# Enterprise policies are placed in the distribution folder to apply globally
POLICY_DIR="/usr/lib/thunderbird/distribution"
mkdir -p "${POLICY_DIR}"

cat <<EOF > "${POLICY_DIR}/policies.json"
{
  "policies": {
    "DisableTelemetry": true,
    "DisableFirefoxStudies": true,
    "DisableFirefoxAccounts": true,
    "DisableDefaultBrowserAgent": true,
    "OverrideFirstRunPage": "",
    "OverridePostUpdatePage": "",
    "DontCheckDefaultBrowser": true,
    "DisplayBookmarksToolbar": "never",
    "NoDefaultBookmarks": true,
    "UserMessaging": {
      "WhatsNew": false,
      "ExtensionRecommendations": false,
      "FeatureRecommendations": false,
      "UrlbarInterventions": false,
      "SkipOnboarding": true
    }
  }
}
EOF

log "Step 2: Desktop & Start Menu integration..."

# 1. Start Menu (Applications Menu) Registration
if [ -f /usr/share/applications/thunderbird.desktop ]; then
  # Ensure category is set so it appears in 'Internet' or 'Network'
  sed -i 's/Categories=Email;/Categories=Network;Email;News;GTK;/g' /usr/share/applications/thunderbird.desktop
  
  if command -v update-desktop-database > /dev/null; then
    update-desktop-database /usr/share/applications/
  fi
  log "Start Menu entry configured."
fi

# Desktop icon (opt-in via THUNDERBIRD_DESKTOP_ICON=true; default off)
desktop_icon thunderbird /usr/share/applications/thunderbird.desktop false

log "Thunderbird UI configuration complete."
