# syntax=docker/dockerfile:1.7

################################################################################
# SquirrelWorks 1.1 - Ubuntu Noble Core
# 
# ARCHITECTURE: Base Layer / Modular Parent
# BUILD CONTEXT: Repo Root
# PURPOSE: 
#   The lean foundation for all SquirrelWorks Noble images. 
#   Provides the shared 'apt_helper', 'cleanup', and 'tools' modules.
################################################################################

# ----------------------------- BASE IMAGE -----------------------------
ARG BASE_TAG="1.18.0-rolling-weekly"
ARG BASE_IMAGE="core-ubuntu-noble"

# ############################################################################
# ------------------------------ BASE STAGE -------------------------------- #
# ############################################################################
FROM --platform=$BUILDPLATFORM kasmweb/${BASE_IMAGE}:${BASE_TAG} AS base

USER root

# Shared Global Environment Variables
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

# Validates the foundation before anything else builds
RUN bash /src/tools/ci/lint_installers.sh
RUN bash /src/tools/ci/lint-dockerfile.sh /src/images/ubuntu-noble-core/Dockerfile
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

# --- Stage Installer Framework ---
# We copy the entire ubuntu/ tree so children have access to helpers,
# but we only execute the absolute minimum baseline here.
COPY ./src/ubuntu/ ${INST_DIR}/ubuntu/

# Make baseline scripts executable
RUN set -eux; \
    find "${INST_DIR}/ubuntu/install" -maxdepth 5 -type f -name '*.sh' -exec chmod +x {} \;

# --- Baseline Execution ---
RUN set -eux; \
    apt-get update; \
    \
    # Intentionally tiny list for the Core image
    SCRIPTS=( \
      "/ubuntu/install/tools/install_tools.sh" \
      "/ubuntu/install/common/00_apt_helper.sh" \
      "/ubuntu/install/common/01_cleanup.sh" \
    ); \
    \
    for SCRIPT in "${SCRIPTS[@]}"; do \
      echo ">>> Executing Base Module: ${SCRIPT}"; \
      bash "${INST_DIR}${SCRIPT}" || { exit 1; }; \
    done; \
    \
    # --- Final Foundation Prep ---
    "${STARTUPDIR}/set_user_permission.sh" "${HOME}"; \
    chown 1000:0 "${HOME}"; \
    mkdir -p /home/kasm-user; \
    chown -R 1000:0 /home/kasm-user; \
    \
    # We leave the common/ directory intact in the Core image 
    # so child images (Desktop, REMNux, etc.) can source apt_helper.sh
    rm -rf "${INST_DIR}/ubuntu/install"

# ----------------------------- FINALIZATION -----------------------------
ENV HOME=/home/kasm-user
WORKDIR ${HOME}
USER 1000

# Standard Kasm Entrypoint
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
