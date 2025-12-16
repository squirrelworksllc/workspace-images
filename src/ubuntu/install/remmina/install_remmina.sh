#!/usr/bin/env bash
# This script installs Remmina. It is meant to be called from a Dockerfile
# and installed on Ubuntu and/or a debian variant.
set -euo pipefail
source ${INST_DIR}/ubuntu/install/common/00_apt_helper.sh

echo "======= Installing Remmina ======="

. /etc/os-release
mkdir -p "$HOME/Desktop"

echo "Step 1: Install packages..."
apt_update_if_needed

case "${ID}" in
  ubuntu)
    # On Noble, Remmina is in repo; on older Ubuntus you may prefer the PPA.
    if [ "${VERSION_CODENAME:-}" = "noble" ]; then
      apt_install remmina remmina-plugin-rdp remmina-plugin-secret xdotool
    else
      apt_install software-properties-common
      apt-add-repository -y ppa:remmina-ppa-team/remmina-next
      apt_refresh_after_repo_change
      apt_install remmina remmina-plugin-rdp remmina-plugin-secret remmina-plugin-spice xdotool
    fi
    ;;
  debian|kali)
    # Debian/Kali: use distro packages; no PPAs.
    # Some repos may not have all plugins (spice/secret) depending on suite.
    apt_install remmina remmina-plugin-rdp remmina-plugin-secret xdotool
    ;;
  *)
    echo "Unsupported distro for Remmina installer: ${ID}" >&2
    exit 1
    ;;
esac

echo "Step 2: Desktop shortcut..."
if [ -f /usr/share/applications/org.remmina.Remmina.desktop ]; then
  cp /usr/share/applications/org.remmina.Remmina.desktop "$HOME/Desktop/"
  chmod +x "$HOME/Desktop/org.remmina.Remmina.desktop"
  chown 1000:1000 "$HOME/Desktop/org.remmina.Remmina.desktop" 2>/dev/null || true
fi

echo "Step 3: Default profiles..."
DEFAULT_PROFILE_DIR="$HOME/.local/share/remmina/defaults"
mkdir -p "$DEFAULT_PROFILE_DIR"

cat >"$DEFAULT_PROFILE_DIR/default.vnc.remmina" <<'EOF'
[remmina]
name=vnc-connection
protocol=VNC
server=
username=
password=
ignore-tls-errors=1
viewmode=4
window_width=640
window_height=480
colordepth=32
quality=9
EOF

cat >"$DEFAULT_PROFILE_DIR/default.rdp.remmina" <<'EOF'
[remmina]
name=rdp-connection
protocol=RDP
server=
username=
password=
ignore-tls-errors=1
viewmode=4
resolution_mode=2
sound=off
freerdp_log_level=INFO
colordepth=99
EOF

# Ownership only for what we created (final cleanup handles broader ownership if you want)
chown -R 1000:1000 "$DEFAULT_PROFILE_DIR" 2>/dev/null || true

echo "Remmina installed!"