# Copied from official KasmTech repo at "https://github.com/kasmtech/workspaces-images/blob/develop/src/ubuntu/install/"
# Modified to remove non-ubuntu references and apply updated logic
#!/usr/bin/env bash
set -euo pipefail
source /dockerstartup/install/ubuntu/install/common/00_apt_helper.sh

echo "======= Installing Ansible ======="

# Require Ubuntu
. /etc/os-release
if [ "${ID}" != "ubuntu" ]; then
  echo "This installer supports Ubuntu only (found: ${ID})." >&2
  exit 1
fi

apt_update_if_needed

if [ "${VERSION_CODENAME}" = "noble" ]; then
  apt_install ansible
else
  apt_install software-properties-common
  apt-add-repository --yes ppa:ansible/ansible
  apt_refresh_after_repo_change
  apt_install ansible
fi

echo "Ansible is now Installed!"