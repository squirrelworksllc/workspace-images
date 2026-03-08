#!/usr/bin/env bash
###############################################################################
# install_thunderbird.sh
#
# Purpose: Installs thunderbird.
#
# Note: Common Pre-Requisite apt packages are called via install_tools.sh
###############################################################################
set -euo pipefail
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log "======= Installing Thunderbird (DEB, no snap) ======="

. /etc/os-release

apt_update_if_needed

bash "${INST_DIR}/ubuntu/install/thunderbird/configure_ui.sh"

case "${ID}" in
  ubuntu)
    log "Ubuntu detected: using mozillateam PPA to avoid snap wrapper."

    # If snap exists, remove thunderbird snap (ignore errors)
    if command -v snap >/dev/null 2>&1; then
      snap remove --purge thunderbird 2>/dev/null || true
    fi

    # Remove transitional deb wrapper if present
    apt-get remove -y thunderbird || true

    # Add Mozilla Team PPA
    add-apt-repository -y ppa:mozillateam/ppa
    apt_refresh_after_repo_change

    # Prefer PPA and block snap-wrapper versions
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
    log "Unsupported distro for Thunderbird installer: ${ID}" >&2
    exit 1
    ;;
esac

# Desktop shortcut (best-effort)
if [ -f /usr/share/applications/thunderbird.desktop ]; then
  cp /usr/share/applications/thunderbird.desktop "$HOME/Desktop/" || true
  chmod +x "$HOME/Desktop/thunderbird.desktop" 2>/dev/null || true
  chown 1000:1000 "$HOME/Desktop/thunderbird.desktop" 2>/dev/null || true
fi

log "Thunderbird installed (DEB, no snap on Ubuntu)!"
