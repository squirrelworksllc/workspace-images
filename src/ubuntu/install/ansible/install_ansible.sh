#!/usr/bin/env bash
# This script install Ansible. It is meant to be called from inside of a Dockerfile.
set -euo pipefail
source ${INST_DIR}/ubuntu/install/common/00_apt_helper.sh

echo "======= Installing Ansible ======="

. /etc/os-release

apt_update_if_needed

case "${ID}" in
  ubuntu)
    # Noble has ansible in the default repos; older Ubuntu can use the PPA if you want newer builds.
    if [ "${VERSION_CODENAME:-}" = "noble" ]; then
      apt_install ansible
    else
      apt_install software-properties-common
      apt-add-repository --yes ppa:ansible/ansible
      apt_refresh_after_repo_change
      apt_install ansible
    fi
    ;;
  debian|kali)
    # Use distro packages (no PPAs here)
    apt_install ansible
    ;;
  *)
    echo "Unsupported distro for Ansible installer: ${ID}" >&2
    exit 1
    ;;
esac

echo "Ansible installed!"