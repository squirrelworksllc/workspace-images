#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

###############################################################################
# validate_torsocks.sh
#
# Runtime validation for torsocks + Tor SOCKS reachability.
#
# Modes:
#   VALIDATE_TORSOCKS_MODE=soft (default)
#     - Skip safely (exit 0) if torsocks/curl missing, or Tor SOCKS not reachable.
#   VALIDATE_TORSOCKS_MODE=hard
#     - Fail loudly (exit nonzero) if torsocks/curl missing, or Tor SOCKS not reachable,
#       or torsocks-wrapped curl fails.
#
# Defaults:
#   Tor SOCKS host: 127.0.0.1
#   Tor SOCKS ports tried: 9050 then 9150 (Tor Browser commonly uses 9150)
#
# Env overrides:
#   VALIDATE_TORSOCKS_MODE (default: soft)  # soft|hard
#   TOR_SOCKS_HOST         (default: 127.0.0.1)
#   TOR_SOCKS_PORT         (default: auto)  # if set, only that port is tested
#   TOR_TEST_URL           (default: https://check.torproject.org/api/ip)
#   CURL_BIN               (default: curl)
#   TORSOCKS_BIN           (default: torsocks)
###############################################################################

log()  { echo "[torsocks] $*"; }
warn() { echo "[torsocks] WARN: $*" >&2; }
err()  { echo "[torsocks] ERROR: $*" >&2; }

MODE="${VALIDATE_TORSOCKS_MODE:-soft}"
TOR_SOCKS_HOST="${TOR_SOCKS_HOST:-127.0.0.1}"
TOR_SOCKS_PORT="${TOR_SOCKS_PORT:-}"
TOR_TEST_URL="${TOR_TEST_URL:-https://check.torproject.org/api/ip}"
CURL_BIN="${CURL_BIN:-curl}"
TORSOCKS_BIN="${TORSOCKS_BIN:-torsocks}"

fail_or_skip() {
  local msg="$1"
  if [ "$MODE" = "hard" ]; then
    err "$msg"
    exit 1
  fi
  log "$msg (mode=soft) -> skipping"
  exit 0
}

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    fail_or_skip "missing required command: $cmd"
  fi
}

check_socks_reachable() {
  local host="$1" port="$2"
  if (exec 3<>"/dev/tcp/${host}/${port}") >/dev/null 2>&1; then
    exec 3<&- 3>&-
    return 0
  fi
  return 1
}

pick_port() {
  # If a port is specified, only test that one.
  if [ -n "$TOR_SOCKS_PORT" ]; then
    if check_socks_reachable "$TOR_SOCKS_HOST" "$TOR_SOCKS_PORT"; then
      echo "$TOR_SOCKS_PORT"
      return 0
    fi
    echo ""
    return 0
  fi

  # Defaults: 9050 (system tor) then 9150 (Tor Browser)
  if check_socks_reachable "$TOR_SOCKS_HOST" 9050; then
    echo 9050
    return 0
  fi
  if check_socks_reachable "$TOR_SOCKS_HOST" 9150; then
    echo 9150
    return 0
  fi

  echo ""
}

main() {
  log "starting torsocks validation (mode=${MODE})"

  need_cmd "$TORSOCKS_BIN"
  need_cmd "$CURL_BIN"

  log "checking Tor SOCKS reachability on ${TOR_SOCKS_HOST} (9050 then 9150 unless overridden)"
  local port
  port="$(pick_port)"

  if [ -z "$port" ]; then
    fail_or_skip "Tor SOCKS not reachable at ${TOR_SOCKS_HOST}:${TOR_SOCKS_PORT:-9050/9150}"
  fi

  log "Tor SOCKS reachable at ${TOR_SOCKS_HOST}:${port}"

  log "running torsocks-wrapped curl test (max 20s) to: ${TOR_TEST_URL}"
  if ! TOR_SOCKS_HOST="$TOR_SOCKS_HOST" TOR_SOCKS_PORT="$port" \
      "$TORSOCKS_BIN" "$CURL_BIN" -fsSL --max-time 20 "$TOR_TEST_URL" >/dev/null; then
    if [ "$MODE" = "hard" ]; then
      err "torsocks-wrapped curl failed"
      exit 1
    fi
    warn "torsocks-wrapped curl failed (mode=soft) -> continuing"
    exit 0
  fi

  log "torsocks traffic test passed"
  log "Tor check response (truncated):"
  TOR_SOCKS_HOST="$TOR_SOCKS_HOST" TOR_SOCKS_PORT="$port" \
    "$TORSOCKS_BIN" "$CURL_BIN" -fsSL --max-time 20 "$TOR_TEST_URL" | head -c 200 || true
  echo ""

  log "torsocks validation complete"
}

main "$@"
