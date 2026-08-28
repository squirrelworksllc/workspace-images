#!/usr/bin/env bash
###############################################################################
# install_vs_code.sh
#
# Purpose: Installs vs_code.
#
# Note: Common Pre-Requisite apt packages are called via install_tools.sh
###############################################################################
set -euo pipefail
: "${INST_DIR:=/dockerstartup/install}"
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log "======= Installing VS Code ======="
log "Step 1: Download and install..."

# VS Code uses "x64" naming; map dpkg arch -> code arch token
ARCH="$(dpkg --print-architecture)"
case "${ARCH}" in
  amd64) CODE_ARCH="x64" ;;
  arm64) CODE_ARCH="arm64" ;;
  *)
    log "Unsupported arch for VS Code: ${ARCH}" >&2
    exit 1
    ;;
esac

apt_update_if_needed

TMP_DEB="/tmp/vscode.deb"
URL="https://update.code.visualstudio.com/latest/linux-deb-${CODE_ARCH}/stable"

# Use curl with -f so HTTP errors fail the build, and show them.
curl -fL --retry 5 --retry-delay 2 -o "${TMP_DEB}" "${URL}"

# Install the deb; apt will pull dependencies.
apt-get install -y "${TMP_DEB}"
rm -f "${TMP_DEB}"

bash "${INST_DIR}/ubuntu/install/vs_code/configure_ui.sh"

log "VS Code installed!"
