#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
#
# Purpose: Configures UI elements and shortcuts for slack.
#
# Note: Common Pre-Requisite apt packages are called via install_tools.sh
###############################################################################
set -euo pipefail

echo "Step 5: Desktop shortcut (best effort)..."
mkdir -p "$HOME/Desktop"
if [ -f /usr/share/applications/slack.desktop ]; then
  # Add --no-sandbox safely
  sed -i 's@^Exec=/usr/bin/slack@Exec=/usr/bin/slack --no-sandbox@' \
    /usr/share/applications/slack.desktop || true
