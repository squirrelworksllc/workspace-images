#!/usr/bin/env bash
# Install REMnux tools using "Add to an existing system" (addon mode).
# Intended for Dockerfile use in a pre-configured Kasm workspace image.
# Docs: https://docs.remnux.org/install-distro/
set -euo pipefail

source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

echo "======= Installing REMnux Malware Analysis Environment (addon mode) ======="

# REMnux is amd64-only; Dockerfile should already enforce this,
# but skipping is better than blowing up multi-arch builds.
ARCH="$(dpkg --print-architecture)"
if [ "${ARCH}" != "amd64" ]; then
  echo "REMnux addon is amd64-only; skipping on ${ARCH}."
  exit 0
fi

echo "Step 1: Install minimal dependencies..."
apt_update_if_needed
apt_install gnupg

echo "Step 2: Download REMnux CLI..."
INSTALL_DIR="/tmp/remnux-installer"
rm -rf "${INSTALL_DIR}"
mkdir -p "${INSTALL_DIR}"
cd "${INSTALL_DIR}"

curl -fsSLo remnux https://remnux.org/remnux-cli
chmod 0755 remnux

echo "Step 3: Run REMNux addon installer..."
export HOME=/root
export NPM_CONFIG_UNSAFE_PERM=true
export npm_config_user=root

# Optional debug while you’re still troubleshooting:
echo "DEBUG: whoami=$(whoami), uid=$(id -u), HOME=$HOME"

if command -v sudo >/dev/null 2>&1; then
  sudo -E ./remnux install --mode=addon --user=kasm-user
else
  # If REMnux *requires* sudo explicitly, install it.
  # If not required, running as root is fine.
  echo "sudo not found; attempting to run installer directly as root..."
  if ./remnux install --mode=addon --user=kasm-user; then
    true
  else
    echo "Installer failed without sudo; installing sudo and retrying..."
    apt_update_if_needed
    apt_install sudo
    sudo -E ./remnux install --mode=addon --user=kasm-user
  fi
fi

echo "REMnux Malware Analysis Environment installed (addon mode)."
