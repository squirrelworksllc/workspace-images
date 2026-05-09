#!/usr/bin/env bash
###############################################################################
# install_qbittorrent.sh
# Purpose: Installs Qbittorrent for SquirrelWorks 1.1
###############################################################################
set -ex

# 1. Install qBittorrent GUI
# We use the PPA to ensure we have the latest stable features for Noble
add-apt-repository -y ppa:qbittorrent-team/qbittorrent-stable
apt-get update
apt-get install -y qbittorrent

# 2. Define the Profile Path (Kasm Persistence logic)
# Standard Ubuntu path for qBittorrent config
PROFILE_CONF_DIR="/home/kasm-user/.config/qBittorrent"
mkdir -p "$PROFILE_CONF_DIR"

# 3. Inject "Corporate/Private" Configuration
# This enforces the "No Seeding" and specific pathing rules
cat <<EOF > "$PROFILE_CONF_DIR/qBittorrent.conf"
[LegalNotice]
Accepted=true

[Preferences]
Downloads\SavePath=/home/kasm-user/Downloads/torrents/
Downloads\ScanDirsV2=@Variant(\0\0\0\x1c\0\0\0\0)
Queueing\QueueingEnabled=true
Queueing\MaxActiveDownloads=5
Queueing\MaxActiveSeeds=0
Queueing\MaxActiveUploads=0
Session\RatioLimit=0
Session\TimeLimit=0
Session\Interface=
Session\InterfaceName=
General\CloseToTray=true
General\StartMinimized=false
EOF

# 4. Ensure Directory Structure & Permissions
mkdir -p /home/kasm-user/Downloads/torrents
chown -R 1000:1000 /home/kasm-user/.config
chown -R 1000:1000 /home/kasm-user/Downloads

# 5. SquirrelWorks Cleanup Protocol
# 01_cleanup.sh will handle the heavy lifting, but we clean the local cache
apt-get clean
rm -rf /var/lib/apt/lists/*
