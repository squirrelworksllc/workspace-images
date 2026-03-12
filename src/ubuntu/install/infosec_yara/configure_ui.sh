#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
# Purpose: Pre-configures VS Code extensions and UI for YARA development.
###############################################################################
set -euo pipefail

log() { echo "[YARA-UI] $*"; }

KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")

log "Step 1: Pre-staging VS Code Environment for YARA..."
mkdir -p "${KASM_HOME}/.config/Code/User"
mkdir -p "${KASM_HOME}/.vscode/extensions"

# We inject the YLS path into VS Code settings so the analyst doesn't have to
cat <<EOF > "${KASM_HOME}/.config/Code/User/settings.json"
{
    "yara.languageServerPath": "/usr/local/bin/yls",
    "yara.yls.enabled": true,
    "editor.formatOnSave": true
}
EOF

log "Step 2: Installing extensions via CLI (Best Effort)..."
# Note: Using --no-sandbox is mandatory here. 
# We ignore errors because if VS Code isn't fully 'happy' in the build env, 
# the user can still install these manually from the marketplace.
if command -v code >/dev/null 2>&1; then
    code --no-sandbox --user-data-dir "${KASM_HOME}/.config/Code" --install-extension infosec-intern.yara || true
    code --no-sandbox --user-data-dir "${KASM_HOME}/.config/Code" --install-extension avast-threatlabs-yara.vscode-yls || true
fi

chown -R 1000:1000 "${KASM_HOME}/.config/Code" "${KASM_HOME}/.vscode"

log "YARA UI configuration applied."
