#!/usr/bin/env bash
# Script to install "Docker In A Docker" (DIND).
# Meant to be called from a Dockerfile, may not run on its own.
set -euo pipefail
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

ARCH="$(dpkg --print-architecture)"
. /etc/os-release

echo "======= Installing Docker-In-A-Docker ======="

echo "Step 1: Enabling Docker repo..."
apt_update_if_needed
apt_install ca-certificates curl

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

cat >/etc/apt/sources.list.d/docker.list <<EOF
deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable
EOF

apt_refresh_after_repo_change

echo "Step 2: Installing dependencies..."
apt_install \
  dbus-user-session \
  docker-buildx-plugin \
  docker-ce \
  docker-ce-cli \
  docker-compose-plugin \
  fuse-overlayfs \
  iptables \
  kmod \
  openssh-client \
  sudo \
  supervisor \
  uidmap \
  wget \
  gnupg

echo "Step 3: Installing DIND..."
useradd -U dockremap || true
grep -q '^dockremap:165536:65536$' /etc/subuid || echo 'dockremap:165536:65536' >> /etc/subuid
grep -q '^dockremap:165536:65536$' /etc/subgid || echo 'dockremap:165536:65536' >> /etc/subgid

curl -fsSL -o /usr/local/bin/dind https://raw.githubusercontent.com/moby/moby/master/hack/dind
chmod +x /usr/local/bin/dind

curl -fsSL -o /usr/local/bin/dockerd-entrypoint.sh https://kasm-ci.s3.amazonaws.com/dockerd-entrypoint.sh
chmod +x /usr/local/bin/dockerd-entrypoint.sh

echo 'hosts: files dns' > /etc/nsswitch.conf
usermod -aG docker kasm-user || true

echo "Step 4: Install k3d tools..."
wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
curl -fsSL -o /usr/local/bin/kubectl \
  "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl"
chmod +x /usr/local/bin/kubectl

echo "Step 5: Passwordless sudo..."
echo 'kasm-user:kasm-user' | chpasswd
echo 'kasm-user ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

echo "Step 6: Cleaning up..."
apt_cleanup

echo "Docker-In-A-Docker is installed! Please practice Inception Responsibly."