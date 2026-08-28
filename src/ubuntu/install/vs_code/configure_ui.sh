#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
#
# Purpose: Configures UI elements, shortcuts, and "Silent Analyst" settings.
###############################################################################
set -euo pipefail

# Standard SquirrelWorks logging fallback
if ! command -v log >/dev/null 2>&1; then
  log() { echo "[VSCODE-UI] $*"; }
fi

# Kasm 1.18+ Dynamic Home Detection
KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")

log "Step 2: Desktop & Start Menu shortcut..."

DESKTOP_FILE="/usr/share/applications/code.desktop"

if [ -f "$DESKTOP_FILE" ]; then
  # 1. Start Menu Integration
  log "Categorizing VS Code for the Applications Menu..."
  sed -i 's/Categories=.*/Categories=Development;IDE;TextEditor;Utility;/g' "$DESKTOP_FILE"

  # 1b. Sandbox fix — the containerized Chromium/Electron sandbox (SUID /
  # user namespaces) is unavailable in Kasm, so a GUI launch of VS Code from
  # the menu or desktop icon fails *silently*. Chrome works around the same
  # limitation (see chrome/configure_ui.sh). Append the flags to every Exec
  # line (primary launcher + "New Window" desktop action) if not already set.
  log "Injecting --no-sandbox into launcher Exec lines..."
  sed -i -E '/^Exec=/ { /--no-sandbox/! s/(\/code)([[:space:]]|$)/\1 --no-sandbox --password-store=basic\2/ }' "$DESKTOP_FILE"

  if command -v update-desktop-database > /dev/null; then
    update-desktop-database /usr/share/applications/
  fi

  # 2. Desktop Icon Logic
  log "Deploying Desktop icon to $KASM_HOME"
  mkdir -p "$KASM_HOME/Desktop"
  cp "$DESKTOP_FILE" "$KASM_HOME/Desktop/code.desktop"
  chmod +x "$KASM_HOME/Desktop/code.desktop"
  chown 1000:0 "$KASM_HOME/Desktop/code.desktop" 2>/dev/null || true
fi

log "Step 3: Applying 'Silent Analyst' global settings..."
# Create the settings directory for the Kasm user
SETTINGS_DIR="$KASM_HOME/.config/Code/User"
mkdir -p "$SETTINGS_DIR"

# Inject the settings JSON to kill the noise
cat <<EOF > "$SETTINGS_DIR/settings.json"
{
    "telemetry.telemetryLevel": "off",
    "workbench.welcomePage.fillReferralMetadata": false,
    "workbench.startupEditor": "none",
    "security.workspace.trust.enabled": false,
    "security.workspace.trust.startupPrompt.enabled": "never",
    "security.workspace.trust.banner": "never",
    "update.mode": "none",
    "extensions.autoCheckUpdates": false,
    "extensions.autoUpdate": false
}
EOF

# Ensure the user owns their config directory (Kasm runtime uses group 0)
chown -R 1000:0 "$KASM_HOME/.config"

log "VS Code UI and Environment configuration complete!"
