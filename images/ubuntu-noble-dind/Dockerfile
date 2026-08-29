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
    DEBUG=false

# Desktop-icon toggles (per app). "true" places an icon on the Desktop; the app
# stays in the Applications menu either way.
ENV CHROMIUM_DESKTOP_ICON=false \
    VS_CODE_DESKTOP_ICON=false

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
COPY ./images/ubuntu-noble-dind/README.md /src/README.md
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
    # SQUIRRELWORKS MODULE REGISTRY
    # =========================================================================
    SCRIPTS=( \
      "/ubuntu/install/tools/install_tools.sh" \
      "/ubuntu/install/common/00_apt_helper.sh" \
      "/ubuntu/install/dind/install_dind.sh" \
      "/ubuntu/install/chromium/install_chromium.sh" \
      "/ubuntu/install/vs_code/install_vs_code.sh" \
      "/ubuntu/install/desktop/install.sh" \
      "/ubuntu/install/common/01_cleanup.sh" \
    ); \
    \
    # Execution Loop
    for SCRIPT in "${SCRIPTS[@]}"; do \
      echo ">>> Executing Module: ${SCRIPT}"; \
      \
      # Handle conditional Chromium install
      if [[ "${SCRIPT}" == *"chromium/install_chromium.sh" && "${SKIP_CHROMIUM}" == "true" ]]; then \
        echo "Skipping Chromium per ENV constraint..."; \
        continue; \
      fi; \
      \
      # Handle branded desktop install
      if [[ "${SCRIPT}" == *"desktop/install.sh" ]]; then \
        bash "${INST_DIR}${SCRIPT}" noble; \
      elif [[ "${SCRIPT}" == *"common/01_cleanup.sh" ]]; then \
        SKIP_CLEAN=false bash "${INST_DIR}${SCRIPT}"; \
      else \
        bash "${INST_DIR}${SCRIPT}"; \
      fi || { \
        rc=$?; \
        echo "FAILED: ${SCRIPT} (rc=$rc)"; \
        [ "${APT_DEBUG}" = "true" ] && tail -n 100 /var/log/apt/term.log || true; \
        exit "$rc"; \
      }; \
    done; \
    \
    # --- Final Session Preparation ---
    "${STARTUPDIR}/set_user_permission.sh" "${HOME}"; \
    rm -f /etc/X11/xinit/Xclients; \
    chown 1000:0 "${HOME}"; \
    mkdir -p /home/kasm-user; \
    chown -R 1000:0 /home/kasm-user; \
    \
    # Prune the ephemeral build-only installers, but KEEP the runtime layer:
    #   common/**     -> master_startup.sh + shared helpers (run/sourced at boot)
    #   */startup.sh  -> per-app runtime permission / daemon modules
    find "${INST_DIR}/ubuntu/install" -type f \
         ! -name 'startup.sh' ! -path '*/common/*' -delete; \
    find "${INST_DIR}/ubuntu/install" -type d -empty -delete

# ############################################################################
# ------------------------- RUNTIME STARTUP HOOK -------------------------- #
# ############################################################################
# Kasm executes ${STARTUPDIR}/custom_startup.sh at session start. This is the
# only entrypoint into the per-app runtime module chain (master_startup.sh ->
# */startup.sh), e.g. the VS Code profile-permission sync.
COPY ./src/ubuntu/startup/custom_startup.sh /dockerstartup/custom_startup.sh
RUN chmod 0755 /dockerstartup/custom_startup.sh

# ############################################################################
# -------------------------- SECURITY METADATA LAYER ----------------------- #
# ############################################################################
# Create the standard OpenVEX directory and embed the unified exception profile
RUN mkdir -p /opt/vex
COPY images/vex_ubuntu_common.json /opt/vex/vex.json

# Copy the centralized Trivy ignore file into standard system scanner paths
COPY images/trivy_ubuntu_common.ignore /.trivyignore
COPY images/trivy_ubuntu_common.ignore /app/.trivyignore
ENV TRIVY_IGNOREFILE=/.trivyignore

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
