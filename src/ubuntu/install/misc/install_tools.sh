# Installs common tools used by all squirrelworksllc base docker images.
#!/usr/bin/env bash
set -ex

if [ "$DISTRO" = centos ]; then
  yum install -y nano zip wget apt-transport-https wget
  yum install epel-release -y
  yum install xdotool -y
else
  apt-get update
  apt-get install -y nano zip xdotool apt-transport-https wget gpg
  apt-get install -y python3 python3-pip
fi