#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
# Purpose: Configures Wine environment and cleans up Start Menu clutter.
###############################################################################
set -euo pipefail

log() { echo "[WINE-UI] $*"; }

KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")

log "Configuring Wine environment for Kasm user..."

# 1. Environment Variables for Wine (PEP 668 & Multi-user safe)
# We set these globally so they persist in the Kasm session
cat >> /etc/environment <<EOF
WINEPREFIX=${KASM_HOME}/.wine
WINEDEBUG=-all
EOF

# 2. Cleanup "Wine Pollution" in the Start Menu
# WineHQ adds many shortcuts; we only want 'Wine Configuration' to show up
log "Cleaning up Start Menu shortcuts..."
WINE_APPS_DIR="/usr/share/applications"
for app in wine-browsedrive.desktop wine-uninstaller.desktop wine-viewman.desktop; do
  if [ -f "${WINE_APPS_DIR}/${app}" ]; then
    echo "NoDisplay=true" >> "${WINE_APPS_DIR}/${app}"
  fi
done

# 3. Desktop Shortcut for Wine Config (handy for analysts)
if [ -f "${WINE_APPS_DIR}/winecfg.desktop" ]; then
  mkdir -p "${KASM_HOME}/Desktop"
  cp "${WINE_APPS_DIR}/winecfg.desktop" "${KASM_HOME}/Desktop/Wine Config.desktop"
  chmod +x "${KASM_HOME}/Desktop/Wine Config.desktop"
  chown 1000:1000 "${KASM_HOME}/Desktop/Wine Config.desktop"
fi

# 4. Pre-configuring Wine Registry for better Kasm compatibility
log "Pre-configuring Wine registry settings..."
USER_WINE_REG="${KASM_HOME}/.wine/user.reg"
mkdir -p "${KASM_HOME}/.wine"

# We create a basic user.reg that enables "Emulate Desktop"
# This prevents Windows apps from trying to resize the Kasm browser window.
cat <<EOF > "${KASM_HOME}/.wine/user.reg"
WINE REGISTRY Version 2
;; All manual changes here will be overwritten by wine!

[Software\\Wine\\Explorer]
"Desktop"="Default"

[Software\\Wine\\Explorer\\Desktops]
"Default"="1024x768"
EOF

chown -R 1000:1000 "${KASM_HOME}/.wine"

if command -v update-desktop-database > /dev/null; then
    update-desktop-database /usr/share/applications/
fi

log "Wine UI and environment configuration complete."
