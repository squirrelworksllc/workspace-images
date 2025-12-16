# This script prompts the user to select one of the pre-defined images/builds
#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-prod}"   # prod | dev | lint
CONFIG=".vscode/images.json"

command -v jq >/dev/null 2>&1 || { echo "jq is required. Install jq and retry."; exit 1; }

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
context="$(jq -r '.context' <<<"$img")"
repo="$(jq -r '.repo' <<<"$img")"

case "$MODE" in
  dev)
    tag="$(jq -r '.devTag' <<<"$img")"
    target="$(jq -r '.devTarget' <<<"$img")"
    echo ""
    echo "Building DEV: ${repo}:${tag} (target=${target})"
    docker build --target "$target" -f "$dockerfile" -t "${repo}:${tag}" "$context"
    ;;
  lint)
    target="$(jq -r '.lintTarget // "lint"' <<<"$img")"
    lint_context="$(jq -r '.lintContext // .context' <<<"$img")"
    echo ""
    echo "Running LINT build: (target=${target})"
    # no tag on purpose (lint is a check, not an artifact)
    docker build --progress=plain --no-cache --target "$target" -f "$dockerfile" "$lint_context"
    ;;
  prod|production)
    tag="$(jq -r '.prodTag' <<<"$img")"
    echo ""
    echo "Building PROD: ${repo}:${tag}"
    docker build -f "$dockerfile" -t "${repo}:${tag}" "$context"
    ;;
  *)
    echo "Unknown mode: $MODE (use prod|dev|lint)"
    exit 4
    ;;
esac