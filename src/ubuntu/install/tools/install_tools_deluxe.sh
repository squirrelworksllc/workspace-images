# Copied from official KasmTech repo at "https://github.com/kasmtech/workspaces-images/blob/develop/src/ubuntu/install/"
#!/usr/bin/env bash
set -ex

apt-get update
apt-get upgrade -y
apt-get autoremove -y
apt-get install -y vlc git tmux