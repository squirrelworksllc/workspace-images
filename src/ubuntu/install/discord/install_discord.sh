#!/usr/bin/env bash
###############################################################################
# install_discord.sh
#
# Purpose: Installs discord.
#
# Note: Common Pre-Requisite apt packages are called via install_tools.sh
###############################################################################
# This is a script to install Discord. It is meant to be called from a Dockerfile
set -euo pipefail
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

echo "======= Installing Discord ======="

echo "Step 1: Install the app..."
apt_update_if_needed
apt_install curl ca-certificates

curl -fsSL -o /tmp/discord.deb "https://discord.com/api/download?platform=linux&format=deb"
apt-get install -y /tmp/discord.deb
rm -f /tmp/discord.deb

echo "Step 2: Set config values..."
mkdir -p "$HOME/.config/discord"
cat >"$HOME/.config/discord/settings.json" <<'JSON'
{"SKIP_HOST_UPDATE": true}
JSON

bash "${INST_DIR}/ubuntu/install/discord/configure_ui.sh"

echo "Step 4: Cleaning up..."
apt_cleanup

echo "Discord is now installed!"
