#!/usr/bin/env bash
###############################################################################
# install_dind.sh
# Purpose: Installs Docker, k3d, and kubectl for SquirrelWorks 1.1
###############################################################################
set -euo pipefail
: "${INST_DIR:=/dockerstartup/install}"
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[DIND-INSTALL] $*"; }

main() {
    log "======= Installing Docker-In-Docker (DinD) ======="

    ARCH="$(dpkg --print-architecture)"
    . /etc/os-release
    apt_update_if_needed

    log "Step 1: Adding Docker Official Repository..."
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" > /etc/apt/sources.list.d/docker.list

    apt_refresh_after_repo_change

    log "Step 2: Installing Docker Engine and Core Dependencies..."
    apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin \
                fuse-overlayfs iptables kmod uidmap sudo supervisor

    log "Step 3: Fetching Moby DinD Hack and Entrypoints..."
    curl -fsSL -o /usr/local/bin/dind https://raw.githubusercontent.com/moby/moby/master/hack/dind
    curl -fsSL -o /usr/local/bin/dockerd-entrypoint.sh https://kasm-ci.s3.amazonaws.com/dockerd-entrypoint.sh
    chmod +x /usr/local/bin/dind /usr/local/bin/dockerd-entrypoint.sh

    log "Step 4: Installing Kubernetes Tooling (k3d/kubectl)..."
    wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | TAG=v5.6.0 bash
    curl -fsSL -o /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl"
    chmod +x /usr/local/bin/kubectl

    log "Step 5: Configuring SubUID/SubGID for Rootless/DinD..."
    useradd -U dockremap || true
    echo "dockremap:165536:65536" >> /etc/subuid
    echo "dockremap:165536:65536" >> /etc/subgid
    
    # Ensure the Kasm user is in the docker group
    usermod -aG docker kasm-user || true

    log "Triggering UI/Config configuration..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "${SCRIPT_DIR}/configure_ui.sh" ]; then
        bash "${SCRIPT_DIR}/configure_ui.sh"
    fi
}

main "$@"
