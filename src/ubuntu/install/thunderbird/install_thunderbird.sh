#!/usr/bin/env bash
###############################################################################
# install_thunderbird.sh
#
# Purpose: Installs Thunderbird via DEB and triggers UI hardening.
###############################################################################
set -euo pipefail
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[THUNDERBIRD-INSTALL] $*"; }

log "======= Installing Thunderbird (DEB, no snap) ======="

. /etc/os-release

apt_update_if_needed

case "${ID}" in
  ubuntu)
    log "Ubuntu detected: prepping PPA and blocking Snaps..."

    # 1. Kill the Snap transition early
    if command -v snap >/dev/null 2>&1; then
      snap remove --purge thunderbird 2>/dev/null || true
    fi

    # 2. Remove the 'fake' transitional deb
    apt-get remove -y thunderbird || true

    # 3. Add Mozilla Team PPA
    add-apt-repository -y ppa:mozillateam/ppa
    
    # 4. Apply Pinning (Critical: Do this BEFORE apt_install)
    log "Applying APT pinning to prefer PPA over Snap..."
    cat >/etc/apt/preferences.d/thunderbird <<'EOF'
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001

Package: thunderbird
Pin: version 2:1snap*
Pin-Priority: -1
EOF

    apt_refresh_after_repo_change
    apt_install thunderbird
    ;;

  debian|kali)
    log "${ID} detected: installing Thunderbird from distro repos."
    apt_install thunderbird
    ;;

  *)
    log "Unsupported distro for Thunderbird: ${ID}" >&2
    exit 1
    ;;
esac

# FIX: Trigger UI configuration ONLY AFTER binaries are present
log "Step 2: Triggering UI and Policy configuration..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/configure_ui.sh" ]; then
    bash "${SCRIPT_DIR}/configure_ui.sh"
else
    log "WARNING: configure_ui.sh not found. Using internal fallback for desktop icon."
    # Fallback icon placement if standalone script is missing
    mkdir -p "$HOME/Desktop"
    if [ -f /usr/share/applications/thunderbird.desktop ]; then
      cp /usr/share/applications/thunderbird.desktop "$HOME/Desktop/"
      chmod +x "$HOME/Desktop/thunderbird.desktop"
      chown 1000:1000 "$HOME/Desktop/thunderbird.desktop" 2>/dev/null || true
    fi
fi

log "Thunderbird installation and UI setup complete!"
