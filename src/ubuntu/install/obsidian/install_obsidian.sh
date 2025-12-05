# Copied from official KasmTech repo at "https://github.com/kasmtech/workspaces-images/blob/develop/src/ubuntu/install/"
# Modified to remove non-ubuntu references and apply updated logic
#!/usr/bin/env bash
# Copied from official KasmTech repo and adapted for Obsidian AppImage
set -ex

echo "======= Installing Discord ======="

# Normalize architecture
echo "Step 1: Runing some checks..."
ARCH=$(uname -m)
case "$ARCH" in
  x86_64) ARCH=amd64 ;;
  aarch64|arm64) ARCH=arm64 ;;
esac

# Dependencies
apt-get update
apt-get install -y curl wget jq libfuse2

# Get latest release JSON once
RELEASE_JSON=$(curl -s https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest)

# Pick the right AppImage URL
if [ "$ARCH" = "amd64" ]; then
  DOWNLOAD_URL=$(printf '%s\n' "$RELEASE_JSON" | jq -r '.assets[] | select(.name | test("AppImage$") and (contains("arm64") | not)) | .browser_download_url')
else
  DOWNLOAD_URL=$(printf '%s\n' "$RELEASE_JSON" | jq -r '.assets[] | select(.name | test("arm64") and test("AppImage$")) | .browser_download_url')
fi

# Basic sanity check
if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" = "null" ]; then
  echo "ERROR: Failed to determine Obsidian AppImage download URL for ARCH=$ARCH" >&2
  exit 1
fi

# Download AppImage
echo "Step 2: Downloading and installing the AppImage..."
mkdir -p /opt/Obsidian
cd /opt/Obsidian
wget -q "$DOWNLOAD_URL" -O Obsidian.AppImage
chmod +x Obsidian.AppImage

# Extract and create launcher
./Obsidian.AppImage --appimage-extract
rm Obsidian.AppImage

# Optional: ownership (typical for container images; harmless to ignore errors)
echo "Step 3: Fixing permissions issues..."
chown -R 1000:1000 /opt/Obsidian || true

cat >/opt/Obsidian/squashfs-root/launcher <<'EOL'
#!/usr/bin/env bash
export APPDIR=/opt/Obsidian/squashfs-root
exec /opt/Obsidian/squashfs-root/AppRun --no-sandbox "$@"
EOL
chmod +x /opt/Obsidian/squashfs-root/launcher

# Make sure the desktop file exists before touching it
echo "Step 4: Fixing desktop icon..."
if [ ! -f /opt/Obsidian/squashfs-root/obsidian.desktop ]; then
  echo "ERROR: obsidian.desktop not found after extraction" >&2
  exit 1
fi

sed -i 's@^Exec=.*@Exec=/opt/Obsidian/squashfs-root/launcher@g' /opt/Obsidian/squashfs-root/obsidian.desktop
sed -i 's@^Icon=.*@Icon=/opt/Obsidian/squashfs-root/obsidian.png@g' /opt/Obsidian/squashfs-root/obsidian.desktop

# Desktop shortcut + system menu entry
mkdir -p "$HOME/Desktop"
cp /opt/Obsidian/squashfs-root/obsidian.desktop "$HOME/Desktop/"
cp /opt/Obsidian/squashfs-root/obsidian.desktop /usr/share/applications/
chmod +x "$HOME/Desktop/obsidian.desktop"
chmod +x /usr/share/applications/obsidian.desktop

echo "Obsidian is Installed!"