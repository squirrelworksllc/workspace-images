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
# We use the RedHat Ansible extension for YAML validation and Linting
if command -v code >/dev/null 2>&1; then
    # Note: Using --no-sandbox because we are running inside the container build phase
    code --no-sandbox --user-data-dir "${KASM_HOME}/.config/Code" --install-extension redhat.ansible || true
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

# Final permission sync
chown -R 1000:1000 "$KASM_HOME/.ansible" "$KASM_HOME/.ansible.cfg" 2>/dev/null || true

log "Ansible UI and CLI environment configured."
