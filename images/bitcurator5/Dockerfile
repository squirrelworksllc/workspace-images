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
# SquirrelWorks module registry, run in order: tools/apt-helper -> desktop
# branding (bitcurator5 theme) -> the BitCurator 5 SaltStack installer. Then a
# forced cleanup pass (shared SKIP_CLEAN=true only defers it in the Core base
# layer), the kasm-user bashrc merge, and a prune that keeps common/** +
# */startup.sh (the runtime module layer) so per-app runtime hooks survive.
ARG APT_DEBUG=false

RUN set -eux; \
    GREEN=$(printf '\033[0;32m'); RED=$(printf '\033[0;31m'); NC=$(printf '\033[0m'); \
    apt-get update; \
    SCRIPTS=( \
      "/ubuntu/install/tools/install_tools.sh" \
      "/ubuntu/install/common/00_apt_helper.sh" \
      "/ubuntu/install/desktop/install.sh" \
      "/ubuntu/install/bitcurator5/install_bitcurator5.sh" \
    ); \
    for SCRIPT in "${SCRIPTS[@]}"; do \
      echo ">>> Executing Module: ${SCRIPT}"; \
      ARGS=(); \
      [[ "${SCRIPT}" == *"desktop/install.sh" ]] && ARGS=("bitcurator5"); \
      if bash "${INST_DIR}${SCRIPT}" "${ARGS[@]}"; then \
        echo "${GREEN}>>> SUCCESS: ${SCRIPT} applied successfully${NC}"; \
      else \
        rc=$?; \
        echo "${RED}>>> FAILED: ${SCRIPT} (exit ${rc}) - see the module's own log output directly above for the failing step${NC}"; \
        exit "$rc"; \
      fi; \
    done; \
    echo "${GREEN}>>> All BitCurator 5 prerequisite modules applied successfully${NC}"; \
    if SKIP_CLEAN=false bash "${INST_DIR}/ubuntu/install/common/01_cleanup.sh"; then \
      echo "${GREEN}>>> SUCCESS: common/01_cleanup.sh applied successfully${NC}"; \
    else \
      rc=$?; \
      echo "${RED}>>> FAILED: common/01_cleanup.sh (exit ${rc}) - see the log output directly above for the failing step${NC}"; \
      exit "$rc"; \
    fi; \
    if [ -f /home/kasm-user/.bashrc ]; then \
      cat /home/kasm-user/.bashrc >> "${HOME}/.bashrc"; \
      rm /home/kasm-user/.bashrc; \
    fi; \
    cp -a /home/kasm-user/. "${HOME}/" 2>/dev/null || true; \
    rm -rf /home/kasm-user; \
    "${STARTUPDIR}/set_user_permission.sh" "${HOME}"; \
    chown 1000:0 "${HOME}"; \
    mkdir -p /home/kasm-user; \
    chown -R 1000:0 /home/kasm-user; \
    find "${INST_DIR}/ubuntu/install" -type f ! -name 'startup.sh' ! -path '*/common/*' -delete; \
    find "${INST_DIR}/ubuntu/install" -type d -empty -delete; \
    rm -rf /tmp/* /var/cache/salt; \
    echo "${GREEN}>>> BitCurator 5 workspace build complete${NC}"

# ############################################################################
# ------------------------- RUNTIME STARTUP HOOK -------------------------- #
# ############################################################################
# Kasm executes ${STARTUPDIR}/custom_startup.sh at session start. This is the
# only entrypoint into the per-app runtime module chain (master_startup.sh ->
# */startup.sh).
COPY ./src/ubuntu/startup/custom_startup.sh /dockerstartup/custom_startup.sh
RUN chmod 0755 /dockerstartup/custom_startup.sh

# ############################################################################
# -------------------------- SECURITY METADATA LAYER ----------------------- #
# ############################################################################
RUN mkdir -p /opt/vex
COPY images/vex_ubuntu_common.json /opt/vex/vex.json

# NOTE: no embedded .trivyignore here - this image is never Trivy-scanned in
# CI (only ubuntu-noble-core is; BitCurator 5 builds FROM that already-scanned
# base). It also isn't in production yet (images.json .enabled = false).

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
