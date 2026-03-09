#!/usr/bin/env bash
###############################################################################
# install_slack.sh
#
# Purpose: Installs Slack Desktop (DEB) for SquirrelWorks 1.1 Registry.
###############################################################################
set -euo pipefail
: "${INST_DIR:=/dockerstartup/install}"
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[SLACK-INSTALL] $*"; }

log "======= Installing Slack Desktop ======="

ARCH="$(dpkg --print-architecture)"
if [ "${ARCH}" != "amd64" ]; then
  log "Slack Desktop is amd64-only; skipping on ${ARCH}."
  exit 0
fi

log "Step 1: Installing dependencies..."
apt_update_if_needed

log "Step 2: Installing Slack signing key..."
install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://packagecloud.io/slacktechnologies/slack/gpgkey \
  | gpg --dearmor -o /etc/apt/keyrings/slack.gpg
chmod 0644 /etc/apt/keyrings/slack.gpg

log "Step 3: Adding Slack APT repo..."
# Note: Slack uses 'jessie' as their generic debian suite name in PackageCloud
cat >/etc/apt/sources.list.d/slack.sources <<'EOF'
Types: deb
URIs: https://packagecloud.io/slacktechnologies/slack/debian/
Suites: jessie
Components: main
Signed-By: /etc/apt/keyrings/slack.gpg
Architectures: amd64
EOF

log "Step 4: Installing slack-desktop..."
apt_refresh_after_repo_change
apt_install slack-desktop

log "Step 5: Triggering UI configuration..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/configure_ui.sh" ]; then
    bash "${SCRIPT_DIR}/configure_ui.sh"
fi

log "Slack installation complete!"
