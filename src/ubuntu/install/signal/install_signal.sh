#!/usr/bin/env bash
###############################################################################
# install_signal.sh
#
# Purpose: Installs signal.
#
# Note: Common Pre-Requisite apt packages are called via install_tools.sh
###############################################################################
# This script installs Signal. It is meant to be called from a Dockerfile
# and installed on Ubuntu and/or a debian variant.
# This script installs Signal. It is meant to be called from a Dockerfile
# and installed on Ubuntu and/or a debian variant.
set -euo pipefail
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

echo "======= Installing Signal ======="

echo "Step 1: Checking for supported Architecture and OS..."
ARCH="$(dpkg --print-architecture)"
if [ "${ARCH}" != "amd64" ]; then
  echo "Signal Desktop APT repo is intended for amd64; skipping on ${ARCH}"
  exit 0
fi

. /etc/os-release
case "${ID}" in
  ubuntu|debian|kali) ;;
  *)
    echo "Unsupported distro for Signal installer: ${ID}" >&2
    exit 1
    ;;
esac

echo "Step 2: Installing dependencies..."
apt_update_if_needed
apt_install ca-certificates curl gpg

echo "Step 3: Installing signing key..."
install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://updates.signal.org/desktop/apt/keys.asc \
  | gpg --dearmor \
  > /etc/apt/keyrings/signal-desktop.gpg
chmod 0644 /etc/apt/keyrings/signal-desktop.gpg

echo "Step 4: Adding repo..."
curl -fsSL -o /etc/apt/sources.list.d/signal-desktop.sources \
  https://updates.signal.org/static/desktop/apt/signal-desktop.sources

# If you ever had the old method, kill it so apt doesn't keep failing.
rm -f /etc/apt/sources.list.d/signal-xenial.list || true

# Ensure Signed-By points to our keyring (works whether or not it already exists)
if grep -qi '^Signed-By:' /etc/apt/sources.list.d/signal-desktop.sources; then
  sed -i 's|^Signed-By:.*|Signed-By: /etc/apt/keyrings/signal-desktop.gpg|I' \
    /etc/apt/sources.list.d/signal-desktop.sources
else
  printf '\nSigned-By: /etc/apt/keyrings/signal-desktop.gpg\n' \
    >> /etc/apt/sources.list.d/signal-desktop.sources
fi

echo "Step 5: Install the app..."
apt_refresh_after_repo_change
apt_install signal-desktop

bash "${INST_DIR}/ubuntu/install/signal/configure_ui.sh"

echo "Signal is now installed!"
