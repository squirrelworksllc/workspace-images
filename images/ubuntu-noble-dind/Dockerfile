# syntax=docker/dockerfile:1.7

################################################################################
# SquirrelWorks 1.1 - Ubuntu Noble DinD (Docker-in-Docker)
# 
# ARCHITECTURE: Modular Registry
# BUILD CONTEXT: Repo Root
# SPECIALTY: High-privilege container for dev/ops and orchestration
################################################################################

# ----------------------------- BASE IMAGE -----------------------------
# Defaults to public Docker Hub & develop for local VSCode testing.
# Overridden dynamically by CI/CD pipeline injections.
ARG BASE_IMAGE="squirrelworksllc/ubuntu-noble-core"
ARG BASE_TAG="develop"

# ############################################################################
# ------------------------------ BASE STAGE -------------------------------- #
# ############################################################################
FROM ${BASE_IMAGE}:${BASE_TAG} AS base

# hadolint ignore=DL3002
USER root

# Shared Environment Variables
ENV HOME=/home/kasm-default-profile \
    STARTUPDIR=/dockerstartup \
    DEBIAN_FRONTEND=noninteractive \
    SKIP_CLEAN=true \
    KASM_RX_HOME=/dockerstartup/kasmrx \
    DONT_PROMPT_WSL_INSTALL="No_Prompt_please" \
    INST_DIR=/dockerstartup/install \
    INSTALL_CHROME=false \
    SKIP_CHROMIUM=false \
    GENERATE_DESKTOP_DOCS=false \
    DEBUG=false

# Desktop-icon toggles. The nested Docker daemon is NOT auto-started; the user
# launches it from the "Docker in Docker" icon (Desktop + Applications menu).
#   DIND_DESKTOP_ICON=false     -> keep it in the menu only, no Desktop icon
#   CHROMIUM_DESKTOP_ICON=true  -> also drop a Chromium icon on the Desktop
ENV DIND_DESKTOP_ICON=true \
    CHROMIUM_DESKTOP_ICON=false

WORKDIR ${HOME}

# ############################################################################
# ------------------------------ LINT TARGET ------------------------------- #
# ############################################################################
FROM base AS lint

WORKDIR /src
COPY . /src

RUN bash /src/tools/ci/lint_installers.sh && \
    bash /src/tools/ci/lint-dockerfile.sh /src/images/ubuntu-noble-dind/Dockerfile && \
    bash /src/tools/ci/lint-shell.sh

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
RUN find "${INST_DIR}/ubuntu/install" -maxdepth 4 -type f -name '*.sh' -exec chmod +x {} \;

# --- Global Build Orchestration ---
# DinD is Core + Chromium + Docker/k8s tooling + the on-demand "Docker in
# Docker" launcher (dind/install_dind.sh). desktop/install.sh runs for the
# wallpaper + XFCE panel/menu fixes only - GENERATE_DESKTOP_DOCS=false skips the
# app catalog. SCRIPTS run in order; Chromium is skipped when SKIP_CHROMIUM=true.
ARG APT_DEBUG=false

RUN set -eux; \
    GREEN=$(printf '\033[0;32m'); RED=$(printf '\033[0;31m'); YELLOW=$(printf '\033[0;33m'); NC=$(printf '\033[0m'); \
    apt-get update; \
    SCRIPTS=( \
      "/ubuntu/install/tools/install_tools.sh" \
      "/ubuntu/install/common/00_apt_helper.sh" \
      "/ubuntu/install/dind/install_dind.sh" \
      "/ubuntu/install/chromium/install_chromium.sh" \
      "/ubuntu/install/desktop/install.sh" \
      "/ubuntu/install/common/01_cleanup.sh" \
    ); \
    for SCRIPT in "${SCRIPTS[@]}"; do \
      echo ">>> Executing Module: ${SCRIPT}"; \
      if [[ "${SCRIPT}" == *"chromium/install_chromium.sh" && "${SKIP_CHROMIUM}" == "true" ]]; then \
        echo "${YELLOW}>>> SKIPPED: ${SCRIPT} (SKIP_CHROMIUM=true)${NC}"; \
        continue; \
      fi; \
      ARGS=(); \
      [[ "${SCRIPT}" == *"desktop/install.sh" ]] && ARGS=("noble"); \
      if bash "${INST_DIR}${SCRIPT}" "${ARGS[@]}"; then \
        echo "${GREEN}>>> SUCCESS: ${SCRIPT} applied successfully${NC}"; \
      else \
        rc=$?; \
        echo "${RED}>>> FAILED: ${SCRIPT} (exit ${rc}) - see the module's own log output directly above for the failing step${NC}"; \
        [ "${APT_DEBUG}" = "true" ] && tail -n 100 /var/log/apt/term.log || true; \
        exit "$rc"; \
      fi; \
    done; \
    echo "${GREEN}>>> All DinD modules applied successfully${NC}"; \
    "${STARTUPDIR}/set_user_permission.sh" "${HOME}"; \
    chown 1000:0 "${HOME}"; \
    mkdir -p /home/kasm-user; \
    chown -R 1000:0 /home/kasm-user; \
    rm -rf "${INST_DIR}/ubuntu/install"

# NOTE: like ubuntu-noble-core, this stage does NOT overwrite
# /dockerstartup/custom_startup.sh or remove /etc/X11/xinit/Xclients - those
# were the DinD-only changes that broke Kasm session provisioning. The nested
# Docker daemon is never auto-started; the user launches it from the "Docker in
# Docker" icon.

# ############################################################################
# -------------------------- SECURITY METADATA LAYER ----------------------- #
# ############################################################################
# Create the standard OpenVEX directory and embed the unified exception profile
RUN mkdir -p /opt/vex
COPY images/vex_ubuntu_common.json /opt/vex/vex.json

# NOTE: no embedded .trivyignore here - this image is never Trivy-scanned in
# CI (only ubuntu-noble-core is; DinD builds FROM that already-scanned base).

# ############################################################################
# ------------------------------ FINALIZATION ------------------------------ #
# ############################################################################
ENV HOME=/home/kasm-user
WORKDIR ${HOME}
USER 1000

# Entrypoint for Kasm Workspaces
CMD ["--tail-log"]

# ############################################################################
# ------------------------------- DEVELOP IMAGE ---------------------------- #
# ############################################################################
FROM build AS develop
ENV DEBUG=true

# ############################################################################
# ----------------------------- PRODUCTION IMAGE --------------------------- #
# ############################################################################
FROM build AS production
ENV DEBUG=false
