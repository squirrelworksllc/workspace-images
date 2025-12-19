#!/usr/bin/env bash
# Interactive builder for repo images (always repo-root context)
set -euo pipefail

export DOCKER_BUILDKIT=1

CONFIG=".vscode/images.json"

command -v jq >/dev/null 2>&1 || { echo "jq is required. Install jq and retry."; exit 1; }

# Ensure we're at repo root (works even if launched from elsewhere)
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "${REPO_ROOT}" ]] || { echo "ERROR: must be run inside a git repo"; exit 10; }
cd "${REPO_ROOT}"

# Extract BASE_TAG from a Dockerfile (for prod tagging)
get_base_tag() {
  local df="$1"
  local tag=""

  # Match lines like: ARG BASE_TAG="1.18.0-rolling-weekly"
  tag="$(
    awk '
      /^[[:space:]]*ARG[[:space:]]+BASE_TAG=/ {
        sub(/^[[:space:]]*ARG[[:space:]]+BASE_TAG=/, "", $0)
        gsub(/"/, "", $0)
        gsub(/\047/, "", $0) # strip single quotes
        print $0
        exit
      }
    ' "$df"
  )"

  if [[ -z "${tag}" ]]; then
    echo "ERROR: Could not determine BASE_TAG from ${df} (expected: ARG BASE_TAG=...)" >&2
    exit 20
  fi

  printf '%s' "${tag}"
}

# Mode picker (default: lint)
echo ""
read -r -p "Select mode [lint/prod/dev] (default: lint): " MODE_IN
MODE="${MODE_IN:-lint}"

case "$MODE" in
  lint|prod|production|dev|develop) ;;
  *)
    echo "Unknown mode: $MODE (use lint|prod|dev)"
    exit 4
    ;;
esac

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

echo ""
echo "Key:        $KEY"
echo "Dockerfile: $dockerfile"
echo "Context:    . (repo root enforced)"

# Enforce repo-root context no matter what images.json says
ROOT_CONTEXT="."

case "$MODE" in
  dev|develop)
    # Always tag dev builds as :develop
    tag="develop"
    target="$(jq -r '.devTarget' <<<"$img")"
    echo ""
    echo "Building DEV: ${repo}:${tag} (target=${target})"
    docker build --progress=plain --target "$target" -f "$dockerfile" -t "${repo}:${tag}" "$ROOT_CONTEXT"
    ;;
  lint)
    target="$(jq -r '.lintTarget // "lint"' <<<"$img")"
    echo ""
    echo "Running LINT build: (target=${target})"
    docker build --progress=plain --no-cache --target "$target" -f "$dockerfile" "$ROOT_CONTEXT"
    ;;
  prod|production)
    # Prod tag derived from Dockerfile ARG BASE_TAG
    tag="$(get_base_tag "$dockerfile")"
    echo ""
    echo "Building PROD: ${repo}:${tag}"
    docker build --progress=plain -f "$dockerfile" -t "${repo}:${tag}" "$ROOT_CONTEXT"
    ;;
esac
