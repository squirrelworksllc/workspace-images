# syntax=docker/dockerfile:1.7
# ----------------------------- DESCRIPTION -----------------------------
# Template Kasm image Dockerfile for the SquirrelWorksLLC workspace-images repo.
#
# Provides:
#   - lint target (hadolint + shellcheck)
#   - develop target
#   - production target (default)
#
# IMPORTANT:
# This Dockerfile assumes the BUILD CONTEXT is the REPO ROOT (.)
# ----------------------------------------------------------------------

# ----------------------------- BASE CONFIG -----------------------------
# Define the base image. For images in this repo, it's usually another
# SquirrelWorksLLC image. For external images, use the full name (e.g., kasmweb/...).
ARG BASE_IMAGE="squirrelworksllc/ubuntu-noble-core"
ARG BASE_TAG="1.18.0"

# ############################################################################
# ------------------------------ BASE STAGE -------------------------------- #
# ############################################################################
# The --platform=$BUILDPLATFORM flag is crucial for multi-arch builds.
# It ensures this stage runs on the native architecture of the build machine.
FROM --platform=$BUILDPLATFORM ${BASE_IMAGE}:${BASE_TAG} AS base

USER root

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
# This stage does not need --platform as it only deals with source code.

WORKDIR /src
COPY . /src

# Run the standard repo linters.
# The lint-dockerfile.sh script uses hadolint.
#
# IMPORTANT: Update the path below to point to THIS Dockerfile.
RUN bash /src/tools/ci/lint_installers.sh
RUN bash /src/tools/ci/lint-dockerfile.sh /src/images/example_folder/Dockerfile
RUN bash /src/tools/ci/lint-shell.sh

USER 1000

# ############################################################################
# ------------------------------ BUILD TARGET ------------------------------ #
# ############################################################################
# This is the main build stage where software is installed.
# It also uses --platform=$BUILDPLATFORM to run on the native build arch.
FROM --platform=$BUILDPLATFORM base AS build

# If your image uses installer scripts under repo-root/src/ubuntu/install/<something>/,
# define them here in a space-separated list.
# The order matters!
ENV INST_SCRIPTS="/ubuntu/install/tools/install_tools.sh \
/ubuntu/install/common/01_cleanup.sh"

# Copy the entire 'src' directory which contains all shared installer logic.
COPY ./src/ ${INST_DIR}

# Run the installer scripts defined in INST_SCRIPTS.
# This block performs a single `apt-get update` for efficiency.
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

# Final userspace runtime configuration.
ENV HOME=/home/kasm-user
WORKDIR ${HOME}
USER 1000

CMD ["--tail-log"]

# ############################################################################
# ----------------------------- DEVELOP IMAGE ------------------------------ #
# ############################################################################
# The 'develop' target is for development builds. It inherits from 'build'
# and sets DEBUG=true. You can add dev-only tools here if needed.
FROM build AS develop
ENV DEBUG=true

# Example for adding a dev-only tool:
# USER root
# RUN apt-get update && apt-get install -y --no-install-recommends vim && rm -rf /var/lib/apt/lists/*
# USER 1000

# ############################################################################
# --------------------------- PRODUCTION IMAGE ----------------------------- #
# ############################################################################
# The 'production' target is the final, clean image for release.
# It inherits from 'build' and sets DEBUG=false.
FROM build AS production
ENV DEBUG=false
