# Copied from official KasmTech repo at "https://github.com/kasmtech/workspaces-images/blob/develop/src/ubuntu/install/"
# Modified to add some logging
#!/usr/bin/env bash
set -ex

apt update 2>&1 | tee /var/log/update.log
apt upgrade -y 2>&1 | tee /var/log/upgrade.log
apt install -y vlc git tmux 2>&1 | tee /var/log/install_tools.log