# syntax=docker/dockerfile:1.7

# ----------------------------- DESCRIPTION -----------------------------
# Ubuntu Noble (Kasm base) + Docker-in-Docker workspace.
# Provides:
#   - lint target (hadolint + shellcheck)
#   - develop target
#   - production target (default)
#
# IMPORTANT:
# This Dockerfile assumes the BUILD CONTEXT is the REPO ROOT.
# Example builds:
#   Lint: docker build --target lint -f images/ubuntu-noble-dind/Dockerfile .
#   Prod: docker build -t squirrelworksllc/ubuntu-noble-dind:1.18.0 -f images/ubuntu-noble-dind/Dockerfile .
#   Dev : docker build --target develop -t squirrelworksllc/ubuntu-noble-dind:develop -f images/ubuntu-noble-dind/Dockerfile .
# ----------------------------------------------------------------------

# ----------------------------- BASE IMAGE -----------------------------
ARG BASE_IMAGE="squirrelworksllc/ubuntu-noble-core"
ARG BASE_TAG="1.18.0"

# ############################################################################
# ------------------------------ BASE STAGE -------------------------------- #
# ############################################################################
FROM ${BASE_IMAGE}:${BASE_TAG} AS base

USER root

ENV HOME=/home/kasm-default-profile \
    STARTUPDIR=/dockerstartup \
    WORKDIR=${HOME}

WORKDIR ${HOME}

# If Chrome is being installed in the image:
#   INSTALL_CHROME=true and SKIP_CHROMIUM=false
# If you want to force Chrome and skip Chromium, set SKIP_CHROMIUM=true
ENV INSTALL_CHROME=false \
    SKIP_CHROMIUM=false

# Environment config
ENV DEBUG=false \
    DEBIAN_FRONTEND=noninteractive \
    SKIP_CLEAN=true \
    KASM_RX_HOME=${STARTUPDIR}/kasmrx \
    DONT_PROMPT_WSL_INSTALL="No_Prompt_please" \
    INST_DIR=${STARTUPDIR}/install

# ############################################################################
# ------------------------------ LINT TARGET ------------------------------- #
# ############################################################################
FROM base AS lint

WORKDIR /src
COPY . /src

RUN bash /src/tools/ci/lint_installers.sh
RUN bash /src/tools/ci/lint-dockerfile.sh /src/images/ubuntu-noble-dind/Dockerfile
RUN bash /src/tools/ci/lint-shell.sh

USER 1000

# ############################################################################
# -------------------------- COMMON BUILD TARGET --------------------------- #
# ############################################################################
FROM base AS build
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Guard: fail fast if build context isn't repo root (COPY fails if missing)
COPY ./src/ubuntu/install/ ./__context_check__/ubuntu_install/
RUN rm -rf ./__context_check__

# Copy ubuntu/ into /dockerstartup/install/ubuntu/
COPY ./src/ubuntu/ ${INST_DIR}/ubuntu/

# Startup scripts specific to DIND
COPY ./src/ubuntu/install/dind/custom_startup.sh ${STARTUPDIR}/custom_startup.sh
COPY ./src/ubuntu/install/dind/dockerd.conf /etc/supervisor/conf.d/
RUN chmod 0755 ${STARTUPDIR}/custom_startup.sh

# Move validation script to base tools folder.
RUN mkdir -p /dockerstartup/tools
COPY ./src/tools/runtime/runtime_validation.sh /dockerstartup/tools/runtime_validation.sh
RUN chmod 0755 /dockerstartup/tools/runtime_validation.sh

# Run installations
#
# Debug toggle:
#   docker build --progress=plain --no-cache --build-arg APT_DEBUG=true ...
ARG APT_DEBUG=false

RUN set -eux; \
    apt-get update; \
    \
    SCRIPTS=( \
      "/ubuntu/install/tools/install_tools.sh" \
      "/ubuntu/install/dind/install_dind.sh" \
    ); \
    \
    if [ "${SKIP_CHROMIUM}" != "true" ]; then \
      SCRIPTS+=( "/ubuntu/install/chromium/install_chromium.sh" ); \
    else \
      echo ">>> SKIP_CHROMIUM=true; skipping Chromium installer"; \
    fi; \
    \
    SCRIPTS+=( \
      "/ubuntu/install/vs_code/install_vs_code.sh" \
      "/ubuntu/install/common/01_cleanup.sh" \
    ); \
    \
    for SCRIPT in "${SCRIPTS[@]}"; do \
      echo ">>> Running ${SCRIPT}"; \
      bash "${INST_DIR}${SCRIPT}" || { \
        rc=$?; \
        echo "FAILED: ${SCRIPT} (rc=$rc)"; \
        if [ "${APT_DEBUG}" = "true" ]; then \
          echo "----- apt logs (tail) -----"; \
          tail -n 200 /var/log/apt/term.log 2>/dev/null || true; \
          tail -n 200 /var/log/apt/history.log 2>/dev/null || true; \
          echo "----- dpkg log (tail) -----"; \
          tail -n 200 /var/log/dpkg.log 2>/dev/null || true; \
          echo "----- free -h -----"; \
          free -h || true; \
          echo "----- df -h -----"; \
          df -h || true; \
          echo "----- ps (top RSS) -----"; \
          ps aux --sort=-rss | head -n 15 || true; \
        fi; \
        exit "$rc"; \
      }; \
    done; \
    \
    "${STARTUPDIR}/set_user_permission.sh" "${HOME}"; \
    rm -f /etc/X11/xinit/Xclients; \
    chown 1000:0 "${HOME}"; \
    mkdir -p /home/kasm-user; \
    chown -R 1000:0 /home/kasm-user; \
    rm -rf "${INST_DIR}"

# Userspace Runtime
ENV HOME=/home/kasm-user
WORKDIR ${HOME}
USER 1000
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
