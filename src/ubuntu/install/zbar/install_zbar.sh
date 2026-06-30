#!/usr/bin/env bash
###############################################################################
# install_zbar.sh
# Purpose: Installs ZBar packages and triggers relative UI configuration.
###############################################################################
set -euo pipefail

log() { echo "[zbar-install] $*"; }

log "Starting ZBar backend installation..."

# Prevent interactive prompts
export DEBIAN_FRONTEND=noninteractive

# Update and install ZBar and video dependencies
apt-get update
apt-get install -y --no-install-recommends \
    zbar-tools \
    libzbar-dev \
    libv4l-0

# Clean apt cache to reduce Docker layer size
apt-get clean
rm -rf /var/lib/apt/lists/*

log "ZBar backend installation complete. Triggering UI configuration..."

# -----------------------------------------------------------------------------
# THE FIX: Dynamic Path Resolution
# Resolve the exact directory this script is currently executing from.
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Verify the UI script exists adjacent to the install script before calling it
if [ -f "${SCRIPT_DIR}/configure_ui.sh" ]; then
    log "Found configure_ui.sh in ${SCRIPT_DIR}. Executing..."
    chmod +x "${SCRIPT_DIR}/configure_ui.sh"
    bash "${SCRIPT_DIR}/configure_ui.sh"
else
    log "ERROR: configure_ui.sh not found in ${SCRIPT_DIR}!" >&2
    exit 1
fi

log "ZBar deployment pipeline finished successfully."
