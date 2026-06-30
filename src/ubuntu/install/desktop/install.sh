#!/usr/bin/env bash
###############################################################################
# install.sh (Desktop Module)
# Purpose: Orchestrates system-wide branding, UI pinning, and documentation.
###############################################################################
set -euo pipefail

# In our new loop, the Dockerfile passes 'noble' or 'remnux' as $1
THEME="${1:-noble}"

log() { echo "[DESKTOP-INSTALL] $*"; }

log "======= Applying $THEME Desktop Environment Branding ======="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Run the wallpaper replacement (The file-swap logic)
if [ -f "${SCRIPT_DIR}/set_wallpaper.sh" ]; then
    bash "${SCRIPT_DIR}/set_wallpaper.sh" "$THEME"
fi

# 2. Run the UI configuration (The XFCE pinning logic)
if [ -f "${SCRIPT_DIR}/configure_ui.sh" ]; then
    bash "${SCRIPT_DIR}/configure_ui.sh"
fi

# 3. Generate Local HTML Documentation & Package Manifests
# Make sure generate_desktop_docs.sh is saved in this same directory!
if [ -f "${SCRIPT_DIR}/generate_desktop_docs.sh" ]; then
    bash "${SCRIPT_DIR}/generate_desktop_docs.sh"
fi

log "Desktop environment branding complete."
