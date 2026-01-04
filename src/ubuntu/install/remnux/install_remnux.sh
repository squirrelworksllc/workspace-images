#!/usr/bin/env bash
# Install REMnux tools using the REMnux CLI on an existing Kasm image.
# Intended for Dockerfile use in a pre-configured Kasm workspace image.
#
# New REMnux CLI method:
#   wget https://REMnux.org/remnux-cli
#   mv remnux-cli remnux
#   chmod +x remnux
#   mv remnux /usr/local/bin
#   remnux install --user=kasm-user
#
# Docs: https://docs.remnux.org/install-distro/
set -euo pipefail
IFS=$'\n\t'

source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[remnux] $*"; }

log "======= Installing REMnux Malware Analysis Environment (CLI) ======="

# REMnux tooling is effectively amd64-focused; skip gracefully on other arches.
ARCH="$(dpkg --print-architecture)"
if [ "${ARCH}" != "amd64" ]; then
  log "REMnux install is amd64-only in this image; skipping on ${ARCH}."
  exit 0
fi

# Ensure the target user exists (Kasm images usually have kasm-user, but be defensive)
TARGET_USER="kasm-user"
if ! id "${TARGET_USER}" >/dev/null 2>&1; then
  log "User ${TARGET_USER} not found; creating minimal user..."
  # Create without prompting; group 0 is common in Kasm images, but keep it simple here.
  useradd -m -s /bin/bash "${TARGET_USER}"
fi

log "Step 1: Install minimal dependencies..."
apt_update_if_needed
apt_install ca-certificates curl wget gnupg

log "Step 1b: Install GNOME keyring autostart bits (REMnux expects them)..."
apt_update_if_needed
apt_install gnome-keyring

log "Step 1c: Ensure /etc/xdg/autostart/gnome-keyring-ssh.desktop exists (override stub)..."
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

log "Step 2: Install REMnux CLI to /usr/local/bin/remnux ..."
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

cd "${tmpdir}"

# Use the exact URL you used successfully (case-insensitive on host, but keep canonical)
wget -qO remnux https://REMnux.org/remnux-cli
chmod +x remnux
mv remnux /usr/local/bin/remnux

log "Step 3: Run REMnux installer for user ${TARGET_USER} ..."
# The CLI may read HOME; keep it sane for a Docker build (root context)
export HOME=/root

# Helpful debug while stabilizing:
log "DEBUG: remnux=$(command -v remnux), whoami=$(whoami), uid=$(id -u), HOME=${HOME}"

# Run the install (no --mode=addon per your working test)
sudo remnux install --user="${TARGET_USER}" --mode=addon

log "REMnux Malware Analysis Environment install complete."
