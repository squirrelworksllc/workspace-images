#!/usr/bin/env bash
set -euo pipefail
IFS=$'
	'

###############################################################################
# install_gnome_keyring_stub.sh
#
# Debian-based only (Debian / Ubuntu).
# Intended to be called non-interactively from a Dockerfile to install
# a gnome-keyring stub before the REMnux installer runs.
#
# Responsibilities:
#   - Ensure /etc/xdg/autostart/gnome-keyring-ssh.desktop exists.
#   - This is necessary because the official REMnux salt states expect to modify
#     this specific file during the "remnux-gnome-config-keyring-ssh-disable-autostart"
#     step. If it is missing, the salt state fails, cascading into further failures.
#
# Env expectations:
#   INST_DIR   (default: /dockerstartup/install) - location of apt helper
###############################################################################

: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[gnome_keyring_stub] $*"; }

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "[gnome_keyring_stub] ERROR: must be run as root" >&2
    exit 1
  fi
}

main() {
  require_root

  echo "======= Installing GNOME Keyring Stub ======="

  log "Step 1: Install gnome-keyring..."
  apt_update_if_needed
  apt_install gnome-keyring

  log "Step 2: Ensure /etc/xdg/autostart/gnome-keyring-ssh.desktop exists..."
  install -d -m 0755 /etc/xdg/autostart
  if [ ! -f /etc/xdg/autostart/gnome-keyring-ssh.desktop ]; then
    if [ -f /usr/share/xdg/autostart/gnome-keyring-ssh.desktop ]; then
      cp -a /usr/share/xdg/autostart/gnome-keyring-ssh.desktop /etc/xdg/autostart/
    else
      # Create a minimal desktop entry stub so Salt can manage/disable it.
      cat > /etc/xdg/autostart/gnome-keyring-ssh.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=GNOME Keyring: SSH Agent
Exec=/usr/bin/gnome-keyring-daemon --start --components=ssh
X-GNOME-Autostart-enabled=true
EOF
      chmod 0644 /etc/xdg/autostart/gnome-keyring-ssh.desktop
    fi
  fi

  log "GNOME Keyring Stub install complete."
}

main "$@"