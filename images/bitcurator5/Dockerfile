WIP - NOT WORKING
# syntax=docker/dockerfile:1.7
# ----------------------------- DESCRIPTION -----------------------------
# BitCurator5 Kasm image.
# This image is built *on top of your* squirrelworksllc's ubuntu-noble-dind image,
# then runs BitCurator installer scripts.
#
# Provides:
#   - lint target (hadolint + shellcheck)
#   - develop target
#   - production target (default)
#
# IMPORTANT:
# Build context is repo root.
#   Lint: docker build --target lint -f images/bitcurator/Dockerfile .
#   Prod: docker build -t squirrelworksllc/bitcurator:latest -f images/bitcurator/Dockerfile .
#   Dev : docker build --target develop -t squirrelworksllc/bitcurator:develop -f images/bitcurator/Dockerfile .
# ----------------------------------------------------------------------

ARG DIND_REPO="squirrelworksllc/ubuntu-noble-dind"
ARG DIND_TAG="1.18.0"

# ############################################################################
# -------------------------------- BASE ----------------------------------- #
# ############################################################################
FROM ${DIND_REPO}:${DIND_TAG} AS base

USER root

# These should already exist in dind image, but keeping them consistent just in case.
ENV HOME=/home/kasm-default-profile
ENV STARTUPDIR=/dockerstartup
WORKDIR ${HOME}

ENV DEBIAN_FRONTEND=noninteractive \
    SKIP_CLEAN=true \
    KASM_RX_HOME=${STARTUPDIR}/kasmrx \
    DONT_PROMPT_WSL_INSTALL="No_Prompt_please" \
    INST_DIR=${STARTUPDIR}/install


# ############################################################################
# ------------------------------ LINT TARGET ------------------------------- #
# ############################################################################
FROM base AS lint

ARG HADOLINT_VERSION="v2.12.0"

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl shellcheck \
    && rm -rf /var/lib/apt/lists/*

# Install pinned hadolint (x86_64).
RUN curl -fsSL -o /usr/local/bin/hadolint \
      "https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-Linux-x86_64" \
    && chmod +x /usr/local/bin/hadolint \
    && hadolint --version

WORKDIR /src
COPY . /src

# Lint THIS Dockerfile
RUN hadolint /src/images/bitcurator/Dockerfile

# Shellcheck scripts in repo
RUN find /src/src /src/tools /src/common -type f -name "*.sh" -print0 2>/dev/null | xargs -0 -r shellcheck


# ############################################################################
# ------------------------------ BUILD TARGET ------------------------------ #
# ############################################################################
FROM base AS build

ENV INST_SCRIPTS="/ubuntu/install/tools/install_tools.sh \
/ubuntu/install/bitcurator/install_bitcurator5.sh \
/ubuntu/install/common/01_cleanup.sh"

# Copy install payload from repo-root/src (contains ubuntu/)
COPY ./src/ ${INST_DIR}

RUN set -eux; \
    apt-get update; \
    for SCRIPT in ${INST_SCRIPTS}; do \
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
