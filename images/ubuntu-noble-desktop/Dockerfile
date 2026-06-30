# syntax=docker/dockerfile:1.7

################################################################################
# SquirrelWorks 1.1 - Ubuntu Noble Desktop
# 
# ARCHITECTURE: Modular Registry
# BUILD CONTEXT: Repo Root
# DESIGN PHILOSOPHY: 
#   1. Install (Static) -> 2. Configure (UI/Policies) -> 3. Startup (Runtime)
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
    INST_DIR=/dockerstartup/install \
    INSTALL_CHROME=true

WORKDIR ${HOME}

# ############################################################################
# ------------------------------ LINT TARGET ------------------------------- #
# ############################################################################
FROM base AS lint

WORKDIR /src
COPY . /src

# Validates syntax and shell standards before building
RUN bash /src/tools/ci/lint_installers.sh
RUN bash /src/tools/ci/lint-dockerfile.sh /src/images/ubuntu-noble-desktop/Dockerfile
RUN bash /src/tools/ci/lint-shell.sh

USER 1000

# ############################################################################
# -------------------------- COMMON BUILD TARGET --------------------------- #
# ############################################################################
FROM base AS build
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# --- Context Guard ---
# Fail fast if build context isn't repo root
COPY ./src/ubuntu/install/ ./__context_check__/ubuntu_install/
RUN rm -rf ./__context_check__

# --- Stage Resources ---
COPY ./src/ubuntu/ ${INST_DIR}/ubuntu/
COPY ./images/ubuntu-noble-desktop/README.md /src/README.md
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
      # GROUP 1: Core System Tools & Helpers
      "/ubuntu/install/tools/install_tools.sh" \
      "/ubuntu/install/common/00_apt_helper.sh" \
      \
      # GROUP 2: Hardened Browser Stack (Non-Snap Native)
      "/ubuntu/install/chrome/install_chrome.sh" \
      "/ubuntu/install/firefox/install_firefox.sh" \
      "/ubuntu/install/chromium/install_chromium.sh" \
      \
      # GROUP 3: Developer & Productivity Suite
      "/ubuntu/install/vs_code/install_vs_code.sh" \
      "/ubuntu/install/ansible/install_ansible.sh" \
      "/ubuntu/install/libre_office/install_libre_office.sh" \
      "/ubuntu/install/remmina/install_remmina.sh" \
      "/ubuntu/install/gimp/install_gimp.sh" \
      "/ubuntu/install/obsidian/install_obsidian.sh" \
      "/ubuntu/install/filezilla/install_filezilla.sh" \
      \
      # GROUP 4: InfoSec & Malware Analysis Modules
      "/ubuntu/install/infosec_yara/install_infosec_yara.sh" \
      "/ubuntu/install/tesseract_ocr/install_tesseract_ocr.sh" \
      "/ubuntu/install/tor_browser/install_tor_browser.sh" \
      "/ubuntu/install/torsocks/install_torsocks.sh" \
      "/ubuntu/install/recoll/install_recoll.sh" \
      "/ubuntu/install/qbittorrent/install_qbittorrent.sh" \
      "/ubuntu/install/origamindee/install_origamindee.sh" \
      "/ubuntu/install/zbar/install_zbar.sh" \
      \
      # GROUP 5: Communication (Autostart Suppressed)
      "/ubuntu/install/signal/install_signal.sh" \
      "/ubuntu/install/slack/install_slack.sh" \
      "/ubuntu/install/discord/install_discord.sh" \
      "/ubuntu/install/teams/install_teams.sh" \
      "/ubuntu/install/telegram/install_telegram.sh" \
      "/ubuntu/install/thunderbird/install_thunderbird.sh" \
      \
      # GROUP 6: Branding & Final Polish
      "/ubuntu/install/desktop/install.sh" \
      "/ubuntu/install/common/01_cleanup.sh" \
      \
      # GROUP 7: Automated Remediation & Purge (MUST BE LAST)
      "/ubuntu/install/common/02_remediation.sh" \
    ); \
    \
    # Execution Loop
    for SCRIPT in "${SCRIPTS[@]}"; do \
      echo ">>> Executing Module: ${SCRIPT}"; \
      if [[ "${SCRIPT}" == *"desktop/install.sh" ]]; then \
        bash "${INST_DIR}${SCRIPT}" noble; \
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
    # Cleanup only the ephemeral build scripts, keeping the shared common tools
    rm -rf "${INST_DIR}/ubuntu/install"

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
