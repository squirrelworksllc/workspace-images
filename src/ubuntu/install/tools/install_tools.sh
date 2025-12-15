# Installs common tools used by all squirrelworksllc base docker images.
#!/usr/bin/env bash
set -euo pipefail
source /dockerstartup/install/ubuntu/install/common/00_apt_helper.sh

echo "======= Installing Common Tools ======="

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
  python3-pip