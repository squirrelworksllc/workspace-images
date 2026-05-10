#!/usr/bin/env bash
###############################################################################
# install_qbittorrent.sh
# Purpose: Installs qBittorrent with "No-Seed" Enforcement for SquirrelWorks
###############################################################################
set -ex

# 1. Dependency Check & PPA Setup
# Ensure software-properties-common is present for add-apt-repository
apt-get update
apt-get install -y software-properties-common
add-apt-repository -y ppa:qbittorrent-team/qbittorrent-stable
apt-get update
apt-get install -y qbittorrent

# 2. Configuration Injection (System-Wide Skeleton)
# We use /etc/skel so that new ephemeral sessions inherit these settings.
# Note: Kasm uses 'kasm_user' (underscore), not 'kasm-user' (hyphen).
SKEL_CONF_DIR="/etc/skel/.config/qBittorrent"
mkdir -p "$SKEL_CONF_DIR"

# 3. Inject "Anti-Seeding" Configuration
cat <<EOF > "$SKEL_CONF_DIR/qBittorrent.conf"
[LegalNotice]
Accepted=true

[Preferences]
Downloads\SavePath=/home/kasm_user/Downloads/torrents/
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
WebUI\Enabled=false
EOF

# 4. Initialize kasm_user home directories for the build layer
USER_CONF_DIR="/home/kasm_user/.config/qBittorrent"
mkdir -p "$USER_CONF_DIR"
cp "$SKEL_CONF_DIR/qBittorrent.conf" "$USER_CONF_DIR/qBittorrent.conf"

# Create download target
mkdir -p /home/kasm_user/Downloads/torrents

# 5. Permission Enforcement (UID 1000)
chown -R 1000:1000 /home/kasm_user/.config
chown -R 1000:1000 /home/kasm_user/Downloads

# 6. SquirrelWorks Cleanup Protocol
apt-get clean
rm -rf /var/lib/apt/lists/*
