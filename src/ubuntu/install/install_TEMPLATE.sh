# This file acts as a template for new app installers. You should create a new folder, then add an install_APPNAME.sh file into it.
# Then adjust the text up here to describe what the file does.
#!/usr/bin/env bash
set -euo pipefail
source /dockerstartup/install/ubuntu/install/common/00_apt_helper.sh

# ----------------------------- CONFIG -----------------------------
APP_NAME="REPLACE_ME"                  # e.g., "VLC"
DESKTOP_NAME="replace-me.desktop"      # e.g., "vlc.desktop" (optional)
SUPPORTED_IDS="ubuntu debian kali"     # adjust if needed
# -----------------------------------------------------------------

echo "======= Installing ${APP_NAME} ======="

# Optional: distro gate (keep if the installer is Debian-family only)
. /etc/os-release
case "${ID}" in
  ubuntu|debian|kali) ;;
  *)
    echo "Unsupported distro for ${APP_NAME}: ${ID}" >&2
    exit 1
    ;;
esac

# Optional: arch gate (use only when upstream is arch-limited)
# ARCH="$(dpkg --print-architecture)"
# if [ "${ARCH}" != "amd64" ]; then
#   echo "${APP_NAME} not supported on ${ARCH}; skipping."
#   exit 0
# fi

echo "Step 1: Install packages..."
apt_update_if_needed
# Use apt_install so you always get --no-install-recommends from your helper
# Example:
# apt_install package1 package2
apt_install REPLACE_ME_PACKAGE_NAMES

echo "Step 2: Desktop shortcut (best effort)..."
mkdir -p "$HOME/Desktop"

# If the system desktop entry exists, copy it to the user desktop
if [ -n "${DESKTOP_NAME}" ] && [ -f "/usr/share/applications/${DESKTOP_NAME}" ]; then
  cp "/usr/share/applications/${DESKTOP_NAME}" "$HOME/Desktop/${DESKTOP_NAME}"
  chmod +x "$HOME/Desktop/${DESKTOP_NAME}"
  chown 1000:1000 "$HOME/Desktop/${DESKTOP_NAME}" 2>/dev/null || true
fi

# Optional: create your own desktop file instead of copying
# cat >"/usr/share/applications/${DESKTOP_NAME}" <<'EOL'
# [Desktop Entry]
# Version=1.0
# Name=REPLACE_ME
# Exec=/usr/bin/REPLACE_ME
# Icon=REPLACE_ME
# Type=Application
# Categories=Utility;
# EOL
# chmod +x "/usr/share/applications/${DESKTOP_NAME}"
# cp "/usr/share/applications/${DESKTOP_NAME}" "$HOME/Desktop/${DESKTOP_NAME}"

echo "${APP_NAME} installed!"
