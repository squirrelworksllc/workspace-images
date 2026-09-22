#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
# Purpose: CLI bash-completion and environment setup for DinD
###############################################################################
set -euo pipefail

log() { echo "[DIND-UI] $*"; }

# shellcheck source=/dev/null
source "${INST_DIR:-/dockerstartup/install}/ubuntu/install/common/10_desktop_icon.sh"

KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")

log "Configuring Bash completions for Docker and Kubernetes..."
mkdir -p "$KASM_HOME/.bash_completion.d"

docker completion bash > "$KASM_HOME/.bash_completion.d/docker" || true
kubectl completion bash > "$KASM_HOME/.bash_completion.d/kubectl" || true

# Ensure the .bashrc loads these
if ! grep -q "bash_completion.d" "$KASM_HOME/.bashrc"; then
    echo 'for f in ~/.bash_completion.d/*; do [ -f "$f" ] && . "$f"; done' >> "$KASM_HOME/.bashrc"
fi

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database /usr/share/applications/ || true
fi

# "Docker in Docker" launcher on the Desktop by default (DIND_DESKTOP_ICON=false
# to suppress it; it stays in the Applications menu either way).
desktop_icon dind /usr/share/applications/dind-docker.desktop true "Docker in Docker.desktop"

chown -R 1000:0 "$KASM_HOME" 2>/dev/null || true

log "DinD environment configuration complete."
