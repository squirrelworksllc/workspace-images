#!/usr/bin/env bash
###############################################################################
# install_signal.sh
#
# Purpose: Installs Signal Desktop for SquirrelWorks 1.1 Registry.
###############################################################################
set -euo pipefail
: "${INST_DIR:=/dockerstartup/install}"
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[SIGNAL-INSTALL] $*"; }

log "======= Installing Signal Desktop ======="

ARCH="$(dpkg --print-architecture)"
if [ "${ARCH}" != "amd64" ]; then
  log "Signal Desktop is amd64-only; skipping on ${ARCH}."
  exit 0
fi

log "Step 1: Installing dependencies..."
apt_update_if_needed

log "Step 2: Installing Signal signing key..."
install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://updates.signal.org/desktop/apt/keys.asc \
  | gpg --dearmor -o /etc/apt/keyrings/signal-desktop.gpg
chmod 0644 /etc/apt/keyrings/signal-desktop.gpg

log "Step 3: Adding Signal APT repo (DEB822 format)..."
curl -fsSL -o /etc/apt/sources.list.d/signal-desktop.sources \
  https://updates.signal.org/static/desktop/apt/signal-desktop.sources

# Ensure the official sources file uses our specific keyring path
sed -i 's|^Signed-By:.*|Signed-By: /etc/apt/keyrings/signal-desktop.gpg|I' \
  /etc/apt/sources.list.d/signal-desktop.sources

log "Step 4: Installing signal-desktop..."
apt_refresh_after_repo_change
apt_install signal-desktop

log "Step 5: Triggering UI configuration..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/configure_ui.sh" ]; then
    bash "${SCRIPT_DIR}/configure_ui.sh"
fi

log "Signal installation complete!"
