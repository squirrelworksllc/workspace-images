#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

###############################################################################
# runtime_validation.sh
#
# Runs runtime validation checks for this image/session.
#
# DESIGN GOALS
#   - Safe by default: a missing validator is skipped, never an error.
#   - Modular: each app drops an executable validator into VALIDATORS_DIR
#     (default /dockerstartup/tools/validators). This script discovers and runs
#     them - no per-app wiring is needed here, mirroring master_startup.sh.
#
# MODES  (VALIDATE_MODE, default: soft)
#   soft  - a validator that runs and fails -> log a warning, keep going
#   hard  - a validator that runs and fails -> exit nonzero (fails session start)
#           A *missing* validator is skipped in both modes.
#
# The mode is exported to each validator as VALIDATE_MODE (and, for backwards
# compatibility, VALIDATE_TORSOCKS_MODE).
###############################################################################

log()  { echo "[validate] $*"; }
warn() { echo "[validate] WARN: $*" >&2; }
err()  { echo "[validate] ERROR: $*" >&2; }

MODE="${VALIDATE_MODE:-soft}"
VALIDATORS_DIR="${VALIDATORS_DIR:-/dockerstartup/tools/validators}"
SOFT_FAILURES=0

run_validator() {
  local name="$1" path="$2"

  if [ ! -x "$path" ]; then
    log "skip: ${name} (missing or not executable): ${path}"
    return 0
  fi

  log "run: ${name} -> ${path}"

  local rc=0
  VALIDATE_MODE="$MODE" VALIDATE_TORSOCKS_MODE="$MODE" "$path" || rc=$?

  if [ "$rc" -eq 0 ]; then
    log "pass: ${name}"
    return 0
  fi

  if [ "$MODE" = "hard" ]; then
    err "fail: ${name} (rc=${rc})"
    return "$rc"
  fi

  warn "fail: ${name} (rc=${rc}) - continuing (mode=soft)"
  SOFT_FAILURES=$((SOFT_FAILURES + 1))
  return 0
}

main() {
  log "runtime validation starting (mode=${MODE}, dir=${VALIDATORS_DIR})"

  if [ ! -d "$VALIDATORS_DIR" ]; then
    log "no validators directory; nothing to check"
    return 0
  fi

  shopt -s nullglob
  local validators=( "${VALIDATORS_DIR}"/*.sh )
  shopt -u nullglob

  if [ "${#validators[@]}" -eq 0 ]; then
    log "no validators present; nothing to check"
    return 0
  fi

  local hard_failures=0 v name
  for v in "${validators[@]}"; do
    name="$(basename "$v" .sh)"
    run_validator "$name" "$v" || hard_failures=$((hard_failures + 1))
  done

  if [ "$hard_failures" -gt 0 ]; then
    err "${hard_failures} validator(s) failed"
    return 1
  fi

  log "runtime validation complete (${SOFT_FAILURES} soft failure(s))"
  return 0
}

main "$@"
