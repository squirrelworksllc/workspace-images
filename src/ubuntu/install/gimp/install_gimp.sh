#!/usr/bin/env bash
# This script file installs Gimp. It is meant to be called from a Dockerfile
set -euo pipefail
source ${INST_DIR}/ubuntu/install/common/00_apt_helper.sh

echo "======= Installing GIMP (AppImage) ======="

apt_update_if_needed
apt_install curl wget ca-certificates

ARCH="$(dpkg --print-architecture)"
mkdir -p /opt/gimp-3
cd /opt/gimp-3

echo "Step 1: Get latest stable GIMP version..."
GIMP_VERSION="$(curl -fsSL https://www.gimp.org/downloads/ \
  | grep -Po '(?is)current stable release of gimp is.*?\K[0-9]+\.[0-9]+\.[0-9]+' \
  | head -n1 || true)"

if [ -z "${GIMP_VERSION}" ]; then
  echo "Could not determine GIMP version from website. Consider pinning a version." >&2
  exit 1
fi

echo "Detected GIMP version: ${GIMP_VERSION}"

echo "Step 2: Download AppImage..."
if [ "${ARCH}" = "amd64" ]; then
  wget -q "https://download.gimp.org/gimp/v3.0/linux/GIMP-${GIMP_VERSION}-x86_64.AppImage" -O gimp.AppImage
else
  wget -q "https://download.gimp.org/gimp/v3.0/linux/GIMP-${GIMP_VERSION}-aarch64.AppImage" -O gimp.AppImage
fi

echo "Step 3: Extract and create launcher..."
chmod +x gimp.AppImage
./gimp.AppImage --appimage-extract
rm -f gimp.AppImage

cat >/opt/gimp-3/squashfs-root/launcher <<'EOL'
#!/usr/bin/env bash
export APPDIR=/opt/gimp-3/squashfs-root/
exec /opt/gimp-3/squashfs-root/AppRun
EOL
chmod +x /opt/gimp-3/squashfs-root/launcher

echo "Step 4: Desktop integration..."
mkdir -p "$HOME/Desktop"

DESKTOP_SRC="$(ls -1 /opt/gimp-3/squashfs-root/*.desktop 2>/dev/null | head -n1 || true)"
if [ -z "${DESKTOP_SRC}" ]; then
  echo "No .desktop file found inside AppImage extract." >&2
  exit 1
fi

cp "${DESKTOP_SRC}" /opt/gimp-3/squashfs-root/gimp.desktop
DESKTOP_FILE="/opt/gimp-3/squashfs-root/gimp.desktop"

sed -i 's@^Exec=.*@Exec=/opt/gimp-3/squashfs-root/launcher@g' "${DESKTOP_FILE}"
sed -i 's@^Icon=.*@Icon=/opt/gimp-3/squashfs-root/org.gimp.GIMP.Stable.svg@g' "${DESKTOP_FILE}"

cp "${DESKTOP_FILE}" "$HOME/Desktop/gimp.desktop"
cp "${DESKTOP_FILE}" /usr/share/applications/gimp.desktop
chmod +x "$HOME/Desktop/gimp.desktop" /usr/share/applications/gimp.desktop
chown 1000:1000 "$HOME/Desktop/gimp.desktop" 2>/dev/null || true

# Ownership on /opt is optional; only do it if runtime user needs write access there.
chown -R 1000:1000 /opt/gimp-3 2>/dev/null || true

echo "Your GIMP installed! Remember to use a safe word."