#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
#
# Purpose: Configures UI elements and shortcuts for teams.
#
# Note: Common Pre-Requisite apt packages are called via install_tools.sh
###############################################################################
set -euo pipefail

echo "Step 4: Desktop shortcut..."
mkdir -p "$HOME/Desktop" "$HOME/.config/teams-for-linux"
