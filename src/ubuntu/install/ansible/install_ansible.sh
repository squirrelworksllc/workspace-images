# Copied from official KasmTech repo at "https://github.com/kasmtech/workspaces-images/blob/develop/src/ubuntu/install/"
# Modified to remove non-ubuntu references and apply updated logic
#!/usr/bin/env bash
set -ex

echo "======= Installing Ansible ======="

if grep -q "ID=debian" /etc/os-release || grep -q "VERSION_CODENAME=noble" /etc/os-release; then
  apt-get update
  apt-get install -y ansible
else
  apt-get update
  apt-get install -y software-properties-common
  apt-add-repository --yes --update ppa:ansible/ansible
  apt-get install -y ansible
fi

echo "Ansible is now Installed!"