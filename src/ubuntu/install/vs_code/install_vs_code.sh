# Copied from official KasmTech repo at "https://github.com/kasmtech/workspaces-images/blob/develop/src/ubuntu/install/"
# Modified to remove non-ubuntu references and apply updated logic
#!/usr/bin/env bash
set -euo pipefail
source /dockerstartup/install/ubuntu/install/common/00_apt_helper.sh

echo "======= Installing VS Code ======="

ARCH="$(dpkg --print-architecture)"
# VS Code uses "amd64" / "arm64" in its deb URL
case "${ARCH}" in
  amd64|arm64) ;;
  *)
    echo "Unsupported arch for VS Code deb: ${ARCH}" >&2
    exit 1
    ;;
esac

echo "Step 1: Download and install..."
# If your Dockerfile already did apt-get update, this will usually skip
apt_update_if_needed

wget -q "https://update.code.visualstudio.com/latest/linux-deb-${ARCH}/stable" -O /tmp/vs_code.deb
apt-get install -y /tmp/vs_code.deb
rm -f /tmp/vs_code.deb

echo "Step 2: Desktop icon / launcher..."
mkdir -p "$HOME/Desktop"

# Optional: force no-sandbox in desktop entry (Kasm desktop containers often need it)
if [ -f /usr/share/applications/code.desktop ]; then
  sed -i 's#/usr/share/code/code#/usr/share/code/code --no-sandbox#' /usr/share/applications/code.desktop || true
  cp /usr/share/applications/code.desktop "$HOME/Desktop/code.desktop"
  chmod +x "$HOME/Desktop/code.desktop"
  chown 1000:1000 "$HOME/Desktop/code.desktop" 2>/dev/null || true
fi

# Optional: custom icon (PNG saved as PNG)
# (You can delete this whole block if you don't care; VS Code ships icons already.)
mkdir -p /usr/share/icons/hicolor/256x256/apps
wget -qO /usr/share/icons/hicolor/256x256/apps/vscode.png https://code.visualstudio.com/assets/branding/code-stable.png
if [ -f /usr/share/applications/code.desktop ]; then
  sed -i '/^Icon=/c\Icon=/usr/share/icons/hicolor/256x256/apps/vscode.png' /usr/share/applications/code.desktop || true
fi

echo "Step 3: Python conveniences..."
# If you truly want these in the base image
apt_update_if_needed
apt_install python3-setuptools python3-venv python3-virtualenv

echo "VS Code is now Installed!"