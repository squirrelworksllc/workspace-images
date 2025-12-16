#!/usr/bin/env bash
# This script installs the Remnux tools using the "Add to an existing system". 
# It is meant to be run/installed into a pre-configured Kasm workspace's
# Dockerfile and was not developed to work as standalone. 
# For official documentation see "https://docs.remnux.org/install-distro/"
set -euo pipefail
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

echo "======= Installing REMnux Malware Analysis Environment (addon mode) ======="

# REMnux is amd64-only; Dockerfile should already enforce this,
# but skipping silently is better than exploding a desktop build.
ARCH="$(dpkg --print-architecture)"
if [ "${ARCH}" != "amd64" ]; then
  echo "REMnux addon is amd64-only; skipping on ${ARCH}."
  exit 0
fi

echo "Step 1: Install minimal dependencies..."
apt_update_if_needed
apt_install curl ca-certificates gnupg sudo

echo "Step 2: Download REMnux CLI..."
INSTALL_DIR="/tmp/remnux-installer"
mkdir -p "${INSTALL_DIR}"
cd "${INSTALL_DIR}"

curl -fsSLo remnux https://remnux.org/remnux-cli
chmod +x remnux

echo "Step 3: Run REMnux addon installer..."
# REMnux requires HOME=/root, but we scope it to the command only
HOME=/root ./remnux install --mode=addon --user=kasm-user

echo "REMnux Malware Analysis Environment installed (addon mode)."