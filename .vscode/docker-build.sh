#!/usr/bin/env bash
# Build images defined in .vscode/images.json
# Always uses REPO ROOT as the Docker build context.

set -euo pipefail

export DOCKER_BUILDKIT=1

MODE="${1:-prod}"   # prod | dev | lint
CONFIG=".vscode/images.json"

command -v jq >/dev/null 2>&1 || { echo "jq is required. Install jq and retry."; exit 1; }

# Force repo root, regardless of where called from (VS Code, terminal, subfolder, etc.)
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "${REPO_ROOT}" ]]; then
  echo "ERROR: must be run from inside a git repo (could not determine repo root)."
  exit 10
fi
cd "${REPO_ROOT}"

# Repo-root context is non-negotiable going forward
ROOT_CONTEXT="."

# Build list of keys
mapfile -t KEYS < <(jq -r '.images[].key' "$CONFIG")

if [[ "${#KEYS[@]}" -eq 0 ]]; then
  echo "No images found in $CONFIG"
  exit 2
fi

# Prompt user to pick an image key
echo ""
echo "Select image:"
select KEY in "${KEYS[@]}"; do
  if [[ -n "${KEY:-}" ]]; then
    break
  fi
  echo "Invalid selection."
done

img="$(jq -r --arg key "$KEY" '.images[] | select(.key==$key)' "$CONFIG")"
if [[ -z "$img" || "$img" == "null" ]]; then
  echo "Image key '$KEY' not found in $CONFIG"
  exit 3
fi

dockerfile="$(jq -r '.dockerfile' <<<"$img")"
repo="$(jq -r '.repo' <<<"$img")"

# Friendly warning if images.json still defines context fields (ignored)
json_context="$(jq -r '.context // empty' <<<"$img" || true)"
json_lint_context="$(jq -r '.lintContext // empty' <<<"$img" || true)"

echo ""
echo "Key:        $KEY"
echo "Dockerfile: $dockerfile"
echo "Context:    ${ROOT_CONTEXT} (repo root enforced)"
if [[ -n "${json_context}" || -n "${json_lint_context}" ]]; then
  echo "Note: images.json context/lintContext values are ignored (repo root is required)."
fi

case "$MODE" in
  dev)
    tag="$(jq -r '.devTag' <<<"$img")"
    target="$(jq -r '.devTarget' <<<"$img")"
    echo ""
    echo "Building DEV: ${repo}:${tag} (target=${target})"
    docker build \
      --progress=plain \
      --target "$target" \
      -f "$dockerfile" \
      -t "${repo}:${tag}" \
      "${ROOT_CONTEXT}"
    ;;
  lint)
    target="$(jq -r '.lintTarget // "lint"' <<<"$img")"
    echo ""
    echo "Running LINT build: (target=${target})"
    # no tag on purpose (lint is a check, not an artifact)
    docker build \
      --progress=plain \
      --no-cache \
      --target "$target" \
      -f "$dockerfile" \
      "${ROOT_CONTEXT}"
    ;;
  prod|production)
    tag="$(jq -r '.prodTag' <<<"$img")"
    echo ""
    echo "Building PROD: ${repo}:${tag}"
    docker build \
      --progress=plain \
      -f "$dockerfile" \
      -t "${repo}:${tag}" \
      "${ROOT_CONTEXT}"
    ;;
  *)
    echo "Unknown mode: $MODE (use prod|dev|lint)"
    exit 4
    ;;
esac
