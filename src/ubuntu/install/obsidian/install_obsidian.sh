#!/usr/bin/env bash
# This script installs Obsidian Text Editor. It is meant to be called from a Dockerfile
# and installed on Ubuntu and/or a debian variant.
set -euo pipefail
source ${INST_DIR}/ubuntu/install/common/00_apt_helper.sh

echo "======= Installing Obsidian ======="

ARCH="$(dpkg --print-architecture)"
case "${ARCH}" in
  amd64|arm64) ;;
  *)
    echo "Unsupported architecture for Obsidian AppImage: ${ARCH}" >&2
    exit 1
    ;;
esac

echo "Step 1: Dependencies..."
apt_update_if_needed
apt_install curl jq libfuse2 ca-certificates

echo "Step 2: Discover latest AppImage URL..."
RELEASE_JSON="$(curl -fsSL https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest)"

if [ "${ARCH}" = "amd64" ]; then
  DOWNLOAD_URL="$(printf '%s\n' "$RELEASE_JSON" | jq -r '.assets[] | select(.name | test("AppImage$") and (contains("arm64") | not)) | .browser_download_url' | head -n1)"
else
  DOWNLOAD_URL="$(printf '%s\n' "$RELEASE_JSON" | jq -r '.assets[] | select(.name | test("arm64") and test("AppImage$")) | .browser_download_url' | head -n1)"
fi

if [ -z "${DOWNLOAD_URL}" ] || [ "${DOWNLOAD_URL}" = "null" ]; then
  echo "ERROR: Failed to determine Obsidian AppImage download URL for ARCH=${ARCH}" >&2
  exit 1
fi

echo "Step 3: Download + extract..."
mkdir -p /opt/Obsidian
cd /opt/Obsidian
curl -fsSL "$DOWNLOAD_URL" -o Obsidian.AppImage
chmod +x Obsidian.AppImage
./Obsidian.AppImage --appimage-extract
rm -f Obsidian.AppImage

echo "Step 4: Launcher + desktop integration..."
cat >/opt/Obsidian/squashfs-root/launcher <<'EOL'
#!/usr/bin/env bash
export APPDIR=/opt/Obsidian/squashfs-root
exec /opt/Obsidian/squashfs-root/AppRun --no-sandbox "$@"
EOL
chmod +x /opt/Obsidian/squashfs-root/launcher

DESKTOP_SRC="/opt/Obsidian/squashfs-root/obsidian.desktop"
if [ ! -f "$DESKTOP_SRC" ]; then
  echo "ERROR: obsidian.desktop not found after extraction" >&2
  exit 1
fi

sed -i 's@^Exec=.*@Exec=/opt/Obsidian/squashfs-root/launcher@g' "$DESKTOP_SRC"
sed -i 's@^Icon=.*@Icon=/opt/Obsidian/squashfs-root/obsidian.png@g' "$DESKTOP_SRC"

mkdir -p "$HOME/Desktop"
cp "$DESKTOP_SRC" "$HOME/Desktop/obsidian.desktop"
cp "$DESKTOP_SRC" /usr/share/applications/obsidian.desktop
chmod +x "$HOME/Desktop/obsidian.desktop" /usr/share/applications/obsidian.desktop
chown 1000:1000 "$HOME/Desktop/obsidian.desktop" 2>/dev/null || true

# Optional: only needed if you want the runtime user to be able to modify /opt/Obsidian
chown -R 1000:1000 /opt/Obsidian 2>/dev/null || true

echo "Obsidian installed!"