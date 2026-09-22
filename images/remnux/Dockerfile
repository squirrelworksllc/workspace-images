# syntax=docker/dockerfile:1.7

################################################################################
# SquirrelWorks 1.1 - Ubuntu (Noble) REMNux Forensics Workstation for Kasm
# 
# ARCHITECTURE: Modular Registry + SaltStack Overlay
# BUILD CONTEXT: Repo Root
# DESIGN PHILOSOPHY: Pre-condition -> Install REMNux -> Polish -> Cleanup
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
FROM base AS lint
WORKDIR /src
COPY . /src
RUN bash /src/tools/ci/lint_installers.sh
RUN bash /src/tools/ci/lint-dockerfile.sh /src/images/remnux/Dockerfile
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
COPY ./images/remnux/README.md /src/README.md
RUN find "${INST_DIR}/ubuntu/install" -maxdepth 4 -type f -name '*.sh' -exec chmod +x {} \;

# --- Runtime Validation Tools ---
RUN mkdir -p /dockerstartup/tools
COPY ./src/tools/runtime/runtime_validation.sh /dockerstartup/tools/runtime_validation.sh
RUN chmod 0755 /dockerstartup/tools/runtime_validation.sh

# --- Global Build Orchestration ---
# SquirrelWorks module registry (REMnux prerequisites), run in order:
#   GROUP 1: core system + REMnux "Salt-fail" prevention (gnome-keyring stub)
#   GROUP 2: forensic UI tools REMnux expects pre-installed (Firefox, VS Code,
#            Wireshark)
#   GROUP 3: Wine, for binary compatibility / analysis
#   GROUP 4: desktop branding (remnux theme)
# Then the REMnux SaltStack cloud installer, a PulseAudio restore Salt tends to
# remove, and the shared cleanup pass. Prune keeps common/** + */startup.sh
# (the runtime module layer) so per-app runtime hooks survive into the image.
ARG APT_DEBUG=false

RUN set -eux; \
    GREEN=$(printf '\033[0;32m'); RED=$(printf '\033[0;31m'); YELLOW=$(printf '\033[0;33m'); NC=$(printf '\033[0m'); \
    apt-get update; \
    SCRIPTS=( \
      "/ubuntu/install/tools/install_tools.sh" \
      "/ubuntu/install/common/00_apt_helper.sh" \
      "/ubuntu/install/gnome_keyring/install_gnome_keyring_stub.sh" \
      "/ubuntu/install/firefox/install_firefox.sh" \
      "/ubuntu/install/vs_code/install_vs_code.sh" \
      "/ubuntu/install/wireshark/install_wireshark.sh" \
      "/ubuntu/install/wine/install_wine.sh" \
      "/ubuntu/install/desktop/install.sh" \
    ); \
    for SCRIPT in "${SCRIPTS[@]}"; do \
      echo ">>> Executing Module: ${SCRIPT}"; \
      ARGS=(); \
      [[ "${SCRIPT}" == *"desktop/install.sh" ]] && ARGS=("remnux"); \
      if bash "${INST_DIR}${SCRIPT}" "${ARGS[@]}"; then \
        echo "${GREEN}>>> SUCCESS: ${SCRIPT} applied successfully${NC}"; \
      else \
        rc=$?; \
        echo "${RED}>>> FAILED: ${SCRIPT} (exit ${rc}) - see the module's own log output directly above for the failing step${NC}"; \
        exit "$rc"; \
      fi; \
    done; \
    echo "${GREEN}>>> All REMnux prerequisite modules applied successfully${NC}"; \
    log() { echo "[REMNUX-INSTALLER] $*"; }; \
    ARCH="$(dpkg --print-architecture)"; \
    if [ "${ARCH}" != "amd64" ]; then \
      echo "${RED}>>> FAILED: the REMnux SaltStack installer is amd64-only (found ${ARCH})${NC}"; \
      exit 1; \
    fi; \
    log "Downloading REMnux SaltStack Installer..."; \
    curl -fsSL -o /tmp/remnux-installer https://remnux.org/remnux; \
    chmod +x /tmp/remnux-installer; \
    log "Running REMnux (Cloud Mode)... this will take time."; \
    if /tmp/remnux-installer install --mode=cloud --user=kasm-user; then \
      echo "${GREEN}>>> SUCCESS: REMnux SaltStack install completed${NC}"; \
    else \
      rc=$?; \
      echo "${YELLOW}>>> WARNING: REMnux SaltStack install exited non-zero (rc=${rc}) - continuing; individual Salt states can report failure without the workstation being unusable${NC}"; \
    fi; \
    log "Restoring Kasm-critical dependencies (PulseAudio)..."; \
    apt-get update && apt-get install -y --no-install-recommends pulseaudio; \
    log "Running Global SquirrelWorks Cleanup..."; \
    SKIP_CLEAN=false bash "${INST_DIR}/ubuntu/install/common/01_cleanup.sh"; \
    if [ -f /home/kasm-user/.bashrc ]; then \
      cat /home/kasm-user/.bashrc >> "${HOME}/.bashrc"; \
      rm /home/kasm-user/.bashrc; \
    fi; \
    cp -a /home/kasm-user/. "${HOME}/" || true; \
    rm -rf /home/kasm-user; \
    "${STARTUPDIR}/set_user_permission.sh" "${HOME}"; \
    chown 1000:0 "${HOME}"; \
    mkdir -p /home/kasm-user; \
    chown -R 1000:0 /home/kasm-user; \
    find "${INST_DIR}/ubuntu/install" -type f ! -name 'startup.sh' ! -path '*/common/*' -delete; \
    find "${INST_DIR}/ubuntu/install" -type d -empty -delete; \
    rm -rf /tmp/* /var/cache/salt; \
    echo "${GREEN}>>> REMnux workspace build complete${NC}"

# ############################################################################
# ------------------------- RUNTIME STARTUP HOOK -------------------------- #
# ############################################################################
# Kasm executes ${STARTUPDIR}/custom_startup.sh at session start. This is the
# only entrypoint into the per-app runtime module chain (master_startup.sh ->
# */startup.sh), e.g. the VS Code profile-permission sync.
COPY ./src/ubuntu/startup/custom_startup.sh /dockerstartup/custom_startup.sh
RUN chmod 0755 /dockerstartup/custom_startup.sh

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
