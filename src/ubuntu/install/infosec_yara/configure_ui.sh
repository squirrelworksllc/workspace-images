#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
# Purpose: Pre-configures VS Code extensions and UI for YARA development.
###############################################################################
set -euo pipefail

log() { echo "[YARA-UI] $*"; }

KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")

log "Step 1: Pre-staging VS Code Environment for YARA..."
CODE_USER_DIR="${KASM_HOME}/.config/Code/User"
CODE_EXT_DIR="${KASM_HOME}/.vscode/extensions"
mkdir -p "${CODE_USER_DIR}" "${CODE_EXT_DIR}"

# Merge the YLS keys into the existing settings.json rather than clobbering the
# global "Silent Analyst" config that vs_code/configure_ui.sh wrote earlier.
SETTINGS_FILE="${CODE_USER_DIR}/settings.json"
if command -v python3 >/dev/null 2>&1; then
    python3 - "$SETTINGS_FILE" <<'PY' || log "WARNING: settings.json merge failed; leaving existing config untouched."
import json, os, sys
path = sys.argv[1]
data = {}
if os.path.isfile(path):
    try:
        with open(path) as fh:
            data = json.load(fh)
    except (ValueError, OSError):
        data = {}
data.update({
    "yara.languageServerPath": "/usr/local/bin/yls",
    "yara.yls.enabled": True,
    "editor.formatOnSave": True,
})
with open(path, "w") as fh:
    json.dump(data, fh, indent=4)
PY
elif [ ! -f "$SETTINGS_FILE" ]; then
    # No python and no prior config: write a minimal standalone file
    cat <<EOF > "$SETTINGS_FILE"
{
    "yara.languageServerPath": "/usr/local/bin/yls",
    "yara.yls.enabled": true,
    "editor.formatOnSave": true
}
EOF
else
    log "WARNING: python3 unavailable; cannot merge YLS keys into existing settings.json."
fi

log "Step 2: Installing extensions via CLI (Best Effort)..."
# Runs as root at build time: pin HOME + data/extension dirs at the Kasm profile
# so the extensions don't land in /root/.vscode and vanish. Errors ignored - the
# analyst can still install from the marketplace.
if command -v code >/dev/null 2>&1; then
    for EXT in infosec-intern.yara avast-threatlabs-yara.vscode-yls; do
        HOME="${KASM_HOME}" code --no-sandbox \
            --user-data-dir "${KASM_HOME}/.config/Code" \
            --extensions-dir "${CODE_EXT_DIR}" \
            --install-extension "$EXT" || true
    done
fi

chown -R 1000:0 "${KASM_HOME}/.config/Code" "${KASM_HOME}/.vscode" 2>/dev/null || true

log "YARA UI configuration applied."
