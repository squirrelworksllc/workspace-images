#!/usr/bin/env bash
###############################################################################
# install_slack.sh
#
# Purpose: Installs slack.
#
# Note: Common Pre-Requisite apt packages are called via install_tools.sh
###############################################################################
# This script installs Slack. It is meant to be called from a Dockerfile
# and installed on Ubuntu and/or a debian variant.
set -euo pipefail
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

echo "======= Installing Slack ======="

ARCH="$(dpkg --print-architecture)"
if [ "${ARCH}" != "amd64" ]; then
  echo "Slack Desktop APT repo is amd64-only; skipping on ${ARCH}"
  exit 0
fi

. /etc/os-release
case "${ID}" in
  ubuntu|debian|kali) ;;
  *)
    echo "Unsupported distro for Slack installer: ${ID}" >&2
    exit 1
    ;;
esac

echo "Step 1: Installing dependencies..."
apt_update_if_needed
apt_install ca-certificates curl gpg

echo "Step 2: Installing Slack signing key..."
install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://packagecloud.io/slacktechnologies/slack/gpgkey \
  | gpg --dearmor \
  > /etc/apt/keyrings/slack.gpg
chmod 0644 /etc/apt/keyrings/slack.gpg

echo "Step 3: Adding Slack APT repo..."
cat >/etc/apt/sources.list.d/slack.sources <<'EOF'
Types: deb
URIs: https://packagecloud.io/slacktechnologies/slack/debian/
Suites: jessie
Components: main
Signed-By: /etc/apt/keyrings/slack.gpg
Architectures: amd64
EOF

echo "Step 4: Installing Slack..."
apt_refresh_after_repo_change
apt_install slack-desktop

bash "${INST_DIR}/ubuntu/install/slack/configure_ui.sh"

  cp /usr/share/applications/slack.desktop "$HOME/Desktop/slack.desktop"
  chmod +x "$HOME/Desktop/slack.desktop"
  chown 1000:1000 "$HOME/Desktop/slack.desktop" 2>/dev/null || true
fi

echo "Slack is now installed!"
