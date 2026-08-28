#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
# Purpose: VS Code integration and Bash completion for Ansible
###############################################################################
set -euo pipefail

log() { echo "[ANSIBLE-UI] $*"; }

KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")

log "Step 1: Enabling Global Shell Autocompletion..."
# Ensures 'ansible-playbook [TAB]' works for the user
if command -v activate-global-python-argcomplete >/dev/null 2>&1; then
    activate-global-python-argcomplete --user >/dev/null 2>&1 || true
else
    # Fallback: install the completion helper if missing
    apt-get update && apt-get install -y python3-argcomplete >/dev/null 2>&1 || true
    activate-global-python-argcomplete --user >/dev/null 2>&1 || true
fi

log "Step 2: Pre-installing VS Code Ansible Extensions..."
# We use the RedHat Ansible extension for YAML validation and Linting.
# Runs as root at build time, so pin HOME + the data/extension dirs at the
# Kasm profile (otherwise the extension lands in /root/.vscode and is lost),
# then hand ownership back to the session user.
if command -v code >/dev/null 2>&1; then
    CODE_USER_DIR="${KASM_HOME}/.config/Code"
    CODE_EXT_DIR="${KASM_HOME}/.vscode/extensions"
    mkdir -p "${CODE_USER_DIR}" "${CODE_EXT_DIR}"
    HOME="${KASM_HOME}" code --no-sandbox \
        --user-data-dir "${CODE_USER_DIR}" \
        --extensions-dir "${CODE_EXT_DIR}" \
        --install-extension redhat.ansible || true
    chown -R 1000:0 "${KASM_HOME}/.vscode" "${CODE_USER_DIR}" 2>/dev/null || true
fi

log "Step 3: Creating User Templates..."
# Optional: creates a default inventory location so the user doesn't get 'missing hosts' errors
mkdir -p "$KASM_HOME/.ansible"
cat <<EOF > "$KASM_HOME/.ansible.cfg"
[defaults]
inventory = ~/inventory
host_key_checking = False
stdout_callback = yaml
EOF

# Final permission sync (Kasm Noble runs the session user with primary group 0)
chown -R 1000:0 "$KASM_HOME/.ansible" "$KASM_HOME/.ansible.cfg" 2>/dev/null || true

log "Ansible UI and CLI environment configured."
