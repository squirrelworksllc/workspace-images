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

# DEV NOTE: The tag can change as Kasm changes, use stable and not rolling.
ARG BASE_TAG="1.18.0"
# DEV NOTE: If Ubuntu version changes, make a new Dockerfile.
ARG BASE_IMAGE="core-ubuntu-noble"

# ############################################################################
# ------------------------------ BASE STAGE -------------------------------- #
# ############################################################################
FROM kasmweb/${BASE_IMAGE}:${BASE_TAG} AS base

USER root

ENV HOME=/home/kasm-default-profile
ENV STARTUPDIR=/dockerstartup
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

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG HADOLINT_VERSION="v2.12.0"

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl shellcheck \
    && rm -rf /var/lib/apt/lists/*

# Install pinned hadolint (x86_64). If you build on ARM64, tell me and I’ll adapt it.
RUN curl -fsSL -o /usr/local/bin/hadolint \
      "https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-Linux-x86_64" \
    && chmod +x /usr/local/bin/hadolint \
    && hadolint --version

WORKDIR /src
COPY . /src

# Lint THIS Dockerfile (path inside repo)
RUN hadolint --ignore DL3008 /src/images/ubuntu-noble-dind/Dockerfile

# Shellcheck scripts in the repo
RUN find /src/src /src/tools /src/common -type f -name "*.sh" -print0 2>/dev/null | xargs -0 -r shellcheck
USER 1000

# ############################################################################
# -------------------------- COMMON BUILD TARGET --------------------------- #
# ############################################################################
FROM base AS build

# Copy install payload (repo-root/src contains ubuntu/)
COPY ./src/ ${INST_DIR}

# Startup scripts specific to DIND
COPY ./src/ubuntu/install/dind/custom_startup.sh ${STARTUPDIR}/custom_startup.sh
COPY ./src/ubuntu/install/dind/dockerd.conf /etc/supervisor/conf.d/
RUN chmod 0755 ${STARTUPDIR}/custom_startup.sh

# Run installations
# - one apt-get update here
# - scripts should use 00_apt_helper.sh and avoid per-script cleanup
RUN set -eux; \
    apt-get update; \
    SCRIPTS="/ubuntu/install/tools/install_tools.sh \
             /ubuntu/install/dind/install_dind.sh"; \
    if [ "${SKIP_CHROMIUM}" != "true" ]; then \
      SCRIPTS="${SCRIPTS} /ubuntu/install/chrome/install_chromium.sh"; \
    else \
      echo ">>> SKIP_CHROMIUM=true; skipping Chromium installer"; \
    fi; \
    SCRIPTS="${SCRIPTS} /ubuntu/install/vs_code/install_vs_code.sh \
                     /ubuntu/install/common/01_cleanup.sh"; \
    for SCRIPT in ${SCRIPTS}; do \
      echo ">>> Running ${SCRIPT}"; \
      bash "${INST_DIR}${SCRIPT}" || { echo "FAILED: ${SCRIPT}"; exit 1; }; \
    done; \
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