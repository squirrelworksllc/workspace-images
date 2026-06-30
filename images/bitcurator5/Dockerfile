# syntax=docker/dockerfile:1.7

##################################################################################
# SquirrelWorks 1.1 - Bitcurator Forensics and Data Analysis Workstation for Kasm
# 
# ARCHITECTURE: Modular Registry + SaltStack Overlay
# BUILD CONTEXT: Repo Root
# DESIGN PHILOSOPHY: Pre-condition -> Install BitCurator 5 -> Polish -> Cleanup
##################################################################################

# ----------------------------- BASE IMAGE -----------------------------
ARG BASE_IMAGE="squirrelworksllc/ubuntu-noble-core"
ARG BASE_TAG="develop"

# ############################################################################
# ------------------------------ BASE STAGE -------------------------------- #
# ############################################################################
FROM ${BASE_IMAGE}:${BASE_TAG} AS base

USER root

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
FROM base AS lint
WORKDIR /src
COPY . /src

RUN bash /src/tools/ci/lint_installers.sh
RUN bash /src/tools/ci/lint-dockerfile.sh /src/images/bitcurator5/Dockerfile
RUN bash /src/tools/ci/lint-shell.sh
USER 1000

# ############################################################################
# -------------------------- COMMON BUILD TARGET --------------------------- #
# ############################################################################
FROM base AS build
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# --- Context Guard ---
COPY ./src/ubuntu/install/ ./__context_check__/ubuntu_install/
RUN rm -rf ./__context_check__

# --- Stage Resources ---
COPY ./src/ubuntu/ ${INST_DIR}/ubuntu/
COPY ./images/bitcurator5/README.md /src/README.md
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
    # SQUIRRELWORKS MODULE REGISTRY
    # =========================================================================
    SCRIPTS=( \
      "/ubuntu/install/tools/install_tools.sh" \
      "/ubuntu/install/common/00_apt_helper.sh" \
      "/ubuntu/install/desktop/install.sh" \
    ); \
    \
    # Execution Loop for Prereqs
    for SCRIPT in "${SCRIPTS[@]}"; do \
      echo ">>> Executing Module: ${SCRIPT}"; \
      if [[ "${SCRIPT}" == *"desktop/install.sh" ]]; then \
        # Passing 'bitcurator5' to trigger specific branding & desktop overrides
        bash "${INST_DIR}${SCRIPT}" bitcurator5; \
      else \
        bash "${INST_DIR}${SCRIPT}"; \
      fi || { exit 1; }; \
    done; \ 
    \
    # =========================================================================
    # THE BITCURATOR V5 CORE INSTALLER
    # =========================================================================
    log() { echo -e "\n\033[1;34m[BITCURATOR-INSTALLER]\033[0m $*"; }; \
    \
    log "Fetching prerequisites and BitCurator CLI..."; \
    apt-get install -y --no-install-recommends curl wget git python3 python3-pip sudo ca-certificates; \
    wget -qO- https://raw.githubusercontent.com/BitCurator/bitcurator-cli/main/install.sh | bash; \
    \
    log "Executing BitCurator SaltStack States (Expected service warnings)..."; \
    bitcurator-cli install bitcurator --user kasm-user || log "Salt applied. Expected Docker service warnings bypassed."; \
    \
    # =========================================================================
    # DESKTOP OVERRIDE REPAIR
    # =========================================================================
    log "Purging overlapping Desktop Environments installed by Salt..."; \
    # Added '|| true' to safeguard against package-not-found or partial install crashes under set -e
    apt-get purge -y ubuntu-desktop gnome-shell gdm3 lightdm ubuntu-session || true; \
    apt-get autoremove -y; \
    \
    log "Restoring Kasm XFCE & Critical Dependencies..."; \
    update-alternatives --set x-session-manager /usr/bin/xfce4-session || true; \
    apt-get update && apt-get install -y --no-install-recommends pulseaudio; \
    \
    # =========================================================================
    # POST-INSTALL POLISH & CLEANUP
    # =========================================================================
    log "Running Global SquirrelWorks Cleanup..."; \
    SKIP_CLEAN=false bash "${INST_DIR}/ubuntu/install/common/01_cleanup.sh"; \
    \
    # --- Final Session Preparation ---
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

# ############################################################################
# -------------------------- SECURITY METADATA LAYER ----------------------- #
# ############################################################################
RUN mkdir -p /opt/vex
COPY images/vex_ubuntu_common.json /opt/vex/vex.json

# ############################################################################
# ------------------------------ FINALIZATION ------------------------------ #
# ############################################################################
ENV HOME=/home/kasm-user
WORKDIR ${HOME}
USER 1000
CMD ["--tail-log"]

# ############################################################################
# ------------------------------- DEVELOP --------------------------------- #
# ############################################################################
FROM build AS develop
ENV DEBUG=true

# ############################################################################
# ----------------------------- PRODUCTION -------------------------------- #
# ############################################################################
FROM build AS production
ENV DEBUG=false
