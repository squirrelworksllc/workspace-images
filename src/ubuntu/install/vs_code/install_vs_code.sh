#!/usr/bin/env bash
# Copied from official KasmTech repo at "https://github.com/kasmtech/workspaces-images/blob/develop/src/ubuntu/install/"
# Modified to remove non-ubuntu references and apply updated logic
set -euo pipefail
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

echo "======= Installing VS Code ======="
echo "Step 1: Download and install..."

# VS Code uses "x64" naming; map dpkg arch -> code arch token
ARCH="$(dpkg --print-architecture)"
case "${ARCH}" in
  amd64) CODE_ARCH="x64" ;;
  arm64) CODE_ARCH="arm64" ;;
  *)
    echo "Unsupported arch for VS Code: ${ARCH}" >&2
    exit 1
    ;;
esac

apt_update_if_needed
apt_install ca-certificates curl

TMP_DEB="/tmp/vscode.deb"
URL="https://update.code.visualstudio.com/latest/linux-deb-${CODE_ARCH}/stable"

# Use curl with -f so HTTP errors fail the build, and show them.
curl -fL --retry 5 --retry-delay 2 -o "${TMP_DEB}" "${URL}"

# Install the deb; apt will pull dependencies.
apt-get install -y "${TMP_DEB}"
rm -f "${TMP_DEB}"

echo "Step 2: Desktop shortcut..."
mkdir -p "$HOME/Desktop"
if [ -f /usr/share/applications/code.desktop ]; then
  cp /usr/share/applications/code.desktop "$HOME/Desktop/code.desktop"
  chmod +x "$HOME/Desktop/code.desktop"
  chown 1000:1000 "$HOME/Desktop/code.desktop" 2>/dev/null || true
fi

echo "VS Code installed!"
