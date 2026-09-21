#!/usr/bin/env bash
###############################################################################
# install.sh (Desktop Module)
# Purpose: Orchestrates system-wide branding, UI pinning, and documentation.
###############################################################################
set -euo pipefail
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/03_scaffold.sh"

# In our new loop, the Dockerfile passes 'noble' or 'remnux' as $1
THEME="${1:-noble}"

LOG_TAG="DESKTOP-INSTALL"

log "======= Applying $THEME Desktop Environment Branding ======="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 0. Icon theme. XFCE's xsettings here is configured for the Greybird GTK
# theme, whose matching icon set is elementary-xfce - but on a minimal image
# (e.g. DinD: Core + Chromium + Docker tooling, no Firefox/GIMP/LibreOffice/
# etc.) nothing happens to pull that package in as a dependency, so icons
# silently fall back to the near-empty stock hicolor theme (Trash, Home,
# Downloads, the Whisker button, etc. all render as generic/broken glyphs).
# Install it explicitly so every image that runs this script gets it
# regardless of which apps it happens to include.
apt_update_if_needed
apt_install elementary-xfce-icon-theme adwaita-icon-theme

# 1. Run the wallpaper replacement (The file-swap logic)
if [ -f "${SCRIPT_DIR}/set_wallpaper.sh" ]; then
    bash "${SCRIPT_DIR}/set_wallpaper.sh" "$THEME"
fi

# 2. Run the UI configuration (The XFCE pinning logic)
if [ -f "${SCRIPT_DIR}/configure_ui.sh" ]; then
    bash "${SCRIPT_DIR}/configure_ui.sh"
fi

# 3. Generate Local HTML Documentation & Package Manifests
# Skipped when GENERATE_DESKTOP_DOCS=false (e.g. the DinD image wants the
# branding/panel fixes but no app catalog).
if [ "${GENERATE_DESKTOP_DOCS:-true}" = "true" ] && [ -f "${SCRIPT_DIR}/generate_desktop_docs.sh" ]; then
    bash "${SCRIPT_DIR}/generate_desktop_docs.sh"
else
    log "Skipping documentation generation (GENERATE_DESKTOP_DOCS=${GENERATE_DESKTOP_DOCS:-true})."
fi

log "Desktop environment branding complete."
