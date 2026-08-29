#!/usr/bin/env bash
###############################################################################
# install_tools.sh
#
# Purpose: Installs tools.
#
# Note: Common Pre-Requisite apt packages are called via install_tools.sh
###############################################################################
# Installs common tools used by all squirrelworksllc base docker images.
set -euo pipefail
LOG_TAG="TOOLS-INSTALL"
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/03_scaffold.sh"

log "======= Installing Common Tools ======="

. /etc/os-release
case "${ID}" in
  ubuntu|debian|kali) ;;
  *)
    echo "Unsupported distro for install_tools.sh: ${ID}" >&2
    exit 1
    ;;
esac

apt_update_if_needed

# Common CLI tools used across installers
apt_install \
  curl \
  git \
  nano \
  zip \
  xdotool \
  wget \
  ca-certificates \
  gnupg \
  apt-transport-https \
  tmux \
  python3 \
  python3-pip \
  tar \
  unzip \
  xz-utils \
  gpgv \
  software-properties-common \
  jq \
  tree
