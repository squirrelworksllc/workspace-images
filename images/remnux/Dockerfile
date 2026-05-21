# syntax=docker/dockerfile:1.7

################################################################################
# SquirrelWorks 1.1 - Ubuntu Noble REMNux for Kasm Workspaces
# 
# ARCHITECTURE: Modular Registry + SaltStack Overlay
# BUILD CONTEXT: Repo Root
# DESIGN PHILOSOPHY: Pre-condition -> Install REMNux -> Polish -> Cleanup
################################################################################

# ----------------------------- BASE IMAGE -----------------------------
ARG BASE_IMAGE="squirrelworksllc/ubuntu-noble-core"
ARG BASE_TAG="1.18.0"

# ############################################################################
# ------------------------------ BASE STAGE -------------------------------- #
# ############################################################################
FROM --platform=$BUILDPLATFORM ${BASE_IMAGE}:${BASE_TAG} AS base

USER root

# Shared Environment Variables
ENV HOME=/home/kasm-default-profile \
    STARTUPDIR=/dockerstartup \
    DEBIAN_FRONTEND=noninteractive \
    SKIP_CLEAN=true \
    KASM_RX_HOME=/dockerstartup/kasmrx \
    DONT_PROMPT_WSL_INSTALL="No_Prompt_please" \
    INST_DIR=/dockerstartup/install

WORKDIR ${HOME}

# ############################################################################
# ------------------------------ LINT TARGET ------------------------------- #
# ############################################################################
FROM --platform=$BUILDPLATFORM base AS lint
WORKDIR /src
COPY . /src
RUN bash /src/tools/ci/lint_installers.sh
RUN bash /src/tools/ci/lint-dockerfile.sh /src/images/remnux/Dockerfile
RUN bash /src/tools/ci/lint-shell.sh
USER 1000

# ############################################################################
# -------------------------- COMMON BUILD TARGET --------------------------- #
# ############################################################################
FROM --platform=$BUILDPLATFORM base AS build
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# --- Context Guard ---
COPY ./src/ubuntu/install/ ./__context_check__/ubuntu_install/
RUN rm -rf ./__context_check__

# --- Stage Resources ---
COPY ./src/ubuntu/ ${INST_DIR}/ubuntu/
RUN find "${INST_DIR}/ubuntu/install" -maxdepth 4 -type f -name '*.sh' -exec chmod +x {} \;

# --- Runtime Validation Tools ---
RUN mkdir -p /dockerstartup/tools
COPY ./src/tools/runtime/runtime_validation.sh /dockerstartup/tools/runtime_validation.sh
RUN chmod 0755 /dockerstartup/tools/runtime_validation.sh

# --- Global Build Orchestration ---
ARG APT_DEBUG=false

RUN set -eux; \
    apt-get update; \
    \
    # =========================================================================
    # SQUIRRELWORKS MODULE REGISTRY (REMNux Prerequisites)
    # =========================================================================
    SCRIPTS=( \
      # GROUP 1: Core System & REMNux "Salt-Fail" Prevention
      "/ubuntu/install/tools/install_tools.sh" \
      "/ubuntu/install/common/00_apt_helper.sh" \
      "/ubuntu/install/gnome_keyring/install_gnome_keyring_stub.sh" \
      \
      # GROUP 2: Forensic UI Tools (REMNux expects these pre-installed)
      "/ubuntu/install/firefox/install_firefox.sh" \
      "/ubuntu/install/vs_code/install_vs_code.sh" \
      "/ubuntu/install/wireshark/install_wireshark.sh" \
      \
      # GROUP 3: Binary Compatibility & Analysis
      "/ubuntu/install/wine/install_wine.sh" \
      \
      # GROUP 4: Branding (Noble-native or REMNux themed)
      "/ubuntu/install/desktop/install.sh" \
    ); \
    \
    # Execution Loop for Prereqs
    for SCRIPT in "${SCRIPTS[@]}"; do \
      echo ">>> Executing Module: ${SCRIPT}"; \
      if [[ "${SCRIPT}" == *"desktop/install.sh" ]]; then \
        # Passing 'remnux' for the forensic theme, or 'noble' for standard numbat
        bash "${INST_DIR}${SCRIPT}" remnux; \
      else \
        bash "${INST_DIR}${SCRIPT}"; \
      fi || { exit 1; }; \
    done; \
    \
    # =========================================================================
    # STEP 5: THE REMNUX CORE INSTALLER
    # =========================================================================
    log() { echo "[REMNUX-INSTALLER] $*"; }; \
    ARCH="$(dpkg --print-architecture)"; \
    if [ "${ARCH}" != "amd64" ]; then log "ERROR: amd64 only"; exit 1; fi; \
    \
    log "Downloading REMNux SaltStack Installer..."; \
    curl -fsSL -o /tmp/remnux-installer https://remnux.org/remnux; \
    chmod +x /tmp/remnux-installer; \
    \
    log "Running REMNux (Cloud Mode)... this will take time."; \
    /tmp/remnux-installer install --mode=cloud --user=kasm-user || true; \
    \
    # =========================================================================
    # STEP 6: POST-REMNUX REPAIR & CLEANUP
    # =========================================================================
    log "Restoring Kasm-critical dependencies (PulseAudio)..."; \
    apt-get update && apt-get install -y --no-install-recommends pulseaudio; \
    \
    log "Running Global SquirrelWorks Cleanup..."; \
    SKIP_CLEAN=false bash "${INST_DIR}/ubuntu/install/common/01_cleanup.sh"; \
    \
    # --- Final Session Preparation ---
    # Merge REMNux-created bashrc into the default profile
    if [ -f /home/kasm-user/.bashrc ]; then \
      cat /home/kasm-user/.bashrc >> "${HOME}/.bashrc"; \
      rm /home/kasm-user/.bashrc; \
    fi; \
    cp -a /home/kasm-user/. "${HOME}/" || true; \
    rm -rf /home/kasm-user; \
    \
    "${STARTUPDIR}/set_user_permission.sh" "${HOME}"; \
    chown 1000:0 "${HOME}"; \
    mkdir -p /home/kasm-user; \
    chown -R 1000:0 /home/kasm-user; \
    \
    # Deep cleanup of temporary build assets
    rm -rf "${INST_DIR}/ubuntu/install" /tmp/* /var/cache/salt

# ----------------------------- FINALIZATION -----------------------------
ENV HOME=/home/kasm-user
WORKDIR ${HOME}
USER 1000
CMD ["--tail-log"]

# ############################################################################
# ------------------------------- DEVELOP --------------------------------- #
# ############################################################################
FROM --platform=$BUILDPLATFORM build AS develop
ENV DEBUG=true

# ############################################################################
# ----------------------------- PRODUCTION -------------------------------- #
# ############################################################################
FROM --platform=$BUILDPLATFORM build AS production
ENV DEBUG=false
