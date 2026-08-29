#!/usr/bin/env bash
###############################################################################
# install_dind.sh
# Purpose: Installs Docker, k3d, and kubectl for SquirrelWorks 1.1
#          Script is designed to fetch latest "Go" ON PURPOSE.
###############################################################################
set -euo pipefail
LOG_TAG="DIND-INSTALL"
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/03_scaffold.sh"

main() {
    log "======= Installing Docker-In-Docker (DinD) ======="

    ARCH="$(dpkg --print-architecture)"
    # Translate architecture for GitHub release URLs
    if [ "$ARCH" = "amd64" ]; then
        COMPOSE_ARCH="x86_64"
    elif [ "$ARCH" = "arm64" ]; then
        COMPOSE_ARCH="aarch64"
    else
        COMPOSE_ARCH="$ARCH"
    fi

    . /etc/os-release
    apt_update_if_needed

    log "Step 1: Adding Docker Official Repository..."
    install -m 0755 -d /etc/apt/keyrings
    
    # [FIX APPLIED HERE]: Added --batch --yes --no-tty to prevent interactive prompt crashes
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --batch --yes --no-tty --dearmor -o /etc/apt/keyrings/docker.gpg
    
    echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" > /etc/apt/sources.list.d/docker.list

    apt_refresh_after_repo_change

    log "Step 2: Installing Docker Engine Core (Skipping CLI Plugins for Dynamic Fetch)..."
    apt_install docker-ce docker-ce-cli containerd.io \
                fuse-overlayfs iptables kmod uidmap sudo supervisor

    log "Step 2.5: Dynamically Fetching Latest Go-Compiled Docker CLI Plugins (Trivy Vuln Remediation)..."
    mkdir -p /usr/libexec/docker/cli-plugins

    # Dynamically fetch and install the latest Docker Compose plugin
    LATEST_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | awk -F '"' '{print $4}')
    log "Installing Docker Compose version: ${LATEST_COMPOSE_VERSION}"
    curl -fsSL "https://github.com/docker/compose/releases/download/${LATEST_COMPOSE_VERSION}/docker-compose-linux-${COMPOSE_ARCH}" \
         -o /usr/libexec/docker/cli-plugins/docker-compose
    chmod +x /usr/libexec/docker/cli-plugins/docker-compose

    # Dynamically fetch and install the latest Docker Buildx plugin
    LATEST_BUILDX_VERSION=$(curl -s https://api.github.com/repos/docker/buildx/releases/latest | grep '"tag_name":' | awk -F '"' '{print $4}')
    log "Installing Docker Buildx version: ${LATEST_BUILDX_VERSION}"
    curl -fsSL "https://github.com/docker/buildx/releases/download/${LATEST_BUILDX_VERSION}/buildx-${LATEST_BUILDX_VERSION}.linux-${ARCH}" \
         -o /usr/libexec/docker/cli-plugins/docker-buildx
    chmod +x /usr/libexec/docker/cli-plugins/docker-buildx

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

    log "Step 6: Deferred dockerd autostart (fires once the XFCE session is up)..."
    local here
    here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    install -m 0755 "${here}/autostart_dockerd.sh" /usr/local/bin/dind-autostart-dockerd

    # Session user may start the Kasm dockerd entrypoint as root, nothing else.
    cat > /etc/sudoers.d/dind-dockerd <<'EOF'
kasm-user ALL=(root) NOPASSWD: /usr/local/bin/dockerd-entrypoint.sh
EOF
    chmod 0440 /etc/sudoers.d/dind-dockerd

    # XFCE runs this after the desktop loads.
    install -d -m 0755 /etc/xdg/autostart
    cat > /etc/xdg/autostart/dind-dockerd.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=DinD Docker Daemon
Comment=Start the nested Docker daemon after the desktop is ready
Exec=/usr/local/bin/dind-autostart-dockerd
Terminal=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF
    chmod 0644 /etc/xdg/autostart/dind-dockerd.desktop

    # Shared log, writable by the docker group (kasm-user is a member).
    touch /var/log/dockerd.log
    chgrp docker /var/log/dockerd.log 2>/dev/null || true
    chmod 0664 /var/log/dockerd.log

    run_configure_ui
}

main "$@"
