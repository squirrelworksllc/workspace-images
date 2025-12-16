#!/usr/bin/env bash
# runs lint checks against dockerfiles
set -euo pipefail

DOCKERFILE="${1:?Usage: lint-dockerfile.sh <path-to-Dockerfile>}"

CONFIG="/src/.hadolint.yaml"

if [[ ! -f "$DOCKERFILE" ]]; then
  echo "Dockerfile not found: $DOCKERFILE"
  exit 1
fi

echo "Hadolint: $DOCKERFILE"

if [[ -f "$CONFIG" ]]; then
  hadolint -c "$CONFIG" "$DOCKERFILE"
else
  hadolint "$DOCKERFILE"
fi
