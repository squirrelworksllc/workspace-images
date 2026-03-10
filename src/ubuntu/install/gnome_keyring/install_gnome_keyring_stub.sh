#!/usr/bin/env bash
###############################################################################
# install_gnome_keyring_stub.sh
# Purpose: Satisfies REMnux SaltStack dependencies to prevent build failures.
###############################################################################
set -euo pipefail
: "${INST_DIR:=/dockerstartup/install}"
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[KEYRING-STUB] $*"; }

main() {
    log "======= Pre-conditioning GNOME Keyring for REMnux ======="

    apt_update_if_needed
    apt_install gnome-keyring \
        dbus-x11 \
        libpam-gnome-keyring \
        pinentry-gnome3

    log "Step 1: Creating target autostart directory..."
    mkdir -p /etc/xdg/autostart

    log "Step 2: Checking for gnome-keyring-ssh.desktop..."
    if [ ! -f /etc/xdg/autostart/gnome-keyring-ssh.desktop ]; then
        if [ -f /usr/share/applications/gnome-keyring-ssh.desktop ]; then
            log "Found system template, copying to autostart..."
            cp /usr/share/applications/gnome-keyring-ssh.desktop /etc/xdg/autostart/
        else
            log "No template found. Creating dummy stub for SaltStack..."
            cat <<EOF > /etc/xdg/autostart/gnome-keyring-ssh.desktop
[Desktop Entry]
Type=Application
Name=GNOME Keyring: SSH Agent
Exec=/usr/bin/gnome-keyring-daemon --start --components=ssh
X-GNOME-Autostart-enabled=true
EOF
            chmod 0644 /etc/xdg/autostart/gnome-keyring-ssh.desktop
        fi
    fi

    log "Keyring stub is in place. REMnux Salt states can now proceed."
}

main "$@"
