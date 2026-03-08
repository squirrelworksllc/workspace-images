#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
#
# Purpose: Configures UI elements and shortcuts for tesseract_ocr.
#
# Note: Common Pre-Requisite apt packages are called via install_tools.sh
###############################################################################
set -euo pipefail

echo "Step 3: Desktop shortcuts..."
mkdir -p "$HOME/Desktop"
