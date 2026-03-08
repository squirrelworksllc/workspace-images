#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
#
# Purpose: Configures UI elements and shortcuts for chromium.
#
# Note: Common Pre-Requisite apt packages are called via install_tools.sh
###############################################################################
set -euo pipefail

echo "Step 3: Modify desktop icon..."
mkdir -p "$HOME/Desktop"
sed -i 's/-stable//g' "/usr/share/applications/${REAL_BIN}.desktop" || true
