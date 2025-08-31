#!/usr/bin/env bash
#===============================================================================
#  GhostOps Control Script - ghostctl.sh
#-------------------------------------------------------------------------------
#  Description : Unified control interface for GhostOps modules.
#                Provides network identity rotation (ghostnet) and verification.
#  Author      : Kehd Emmanuel H. Diaz
#  Version     : 1.3
#  Created     : 2025-08-31
#  License     : MIT
#-------------------------------------------------------------------------------
#  Usage:
#    ./ghostctl.sh rotate-net [--static|--dhcp] [--iface IFACE] [--verify-after] [--dry-run] [--note "text"]
#    ./ghostctl.sh verify-net [--iface IFACE] [--run-id ID] [--no-public]
#===============================================================================

set -Eeuo pipefail

#--- Config --------------------------------------------------------------------
GHOSTOPS_HOME="/home/kehd/ghostops"
LOG_DIR="$GHOSTOPS_HOME/logs"
GHOSTCTL_LOG="$LOG_DIR/ghostctl.log"
GHOSTNET_BIN="$GHOSTOPS_HOME/modules/ghostnet.sh"

mkdir -p "$LOG_DIR"

#--- Helpers -------------------------------------------------------------------
gen_run_id() {
  printf "%s-%s" \
    "$(date -u +%Y%m%dT%H%M%S%3NZ)" \
    "$(head -c 4 /dev/urandom | od -An -tx1 | tr -d ' \n')"
}

json_escape() {
  local s="$1"
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\n'/ }
  s=${s//$'\r'/ }
  printf '%s' "$s"
}

log_json() {
  local level="$1"; shift
  local event="$1"; shift
  local msg="$1"; shift
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%S%3NZ)"
  local extra=""
  while (( "$#" )); do
    kv="$1"; shift
    key="${kv%%=*}"; val="${kv#*=}"
    if [[ -n "$key" && -n "$val" ]]; then
      if [[ "$val" =~ ^[0-9]+$ ]]; then
        extra="${extra},\"$(json_escape "$key")\":${val}"
      else
        extra="${extra},\"$(json_escape "$key")\":\"$(json_escape "$val")\""
      fi
    fi
  done
  printf '{"ts":"%s","component":"ghostctl","level":"%s","event":"%s","msg":"%s"%s}\n' \
    "$ts" "$(json_escape "$level")" "$(json_escape "$event")" "$(json_escape "$msg")" "$extra" >> "$GHOSTCTL_LOG"
}

usage() {
  cat <<'EOF2'
ghostctl - GhostOps control

Commands:
  rotate-net   Rotate MAC/IP via ghostnet module
  verify-net   Verify network state

Examples:
  ./ghostctl.sh rotate-net --static --iface wlan0 --verify-after
  ./ghostctl.sh verify-net --iface eth0
EOF2
}

#--- Commands ------------------------------------------------------------------
rotate_net() {
  local mode="" iface="" verify_after=0 dry_run=0 note=""
  iface="${IFACE:-$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}' || true)}"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --static|--dhcp) mode="$1"; shift ;;
      --iface) iface="$2"; shift 2 ;;
      --verify-after) verify_after=1; shift ;;
      --dry-run) dry_run=1; shift ;;
      --note) note="$2"; shift 2 ;;
      *) echo "Unknown flag: $1" >&2; exit 2 ;;
    esac
  done

  local run_id; run_id="$(gen_run_id)"
  log_json info rotate_net_start "network rotation starting" run_id="$run_id" mode="$mode" iface="$iface" dry_run="$dry_run" note="$note"

  local args=()
  [[ -n "$mode" ]] && args+=("$mode")
  [[ -n "$iface" ]] && args+=(--iface "$iface")
  [[ $dry_run -eq 1 ]] && args+=(--dry-run)
  [[ -n "$note" ]] && args+=(--log-note "$note")
  args+=(--run-id "$run_id")

  set +e
  sudo -n "$GHOSTNET_BIN" "${args[@]}"
  local rc=$?
  set -e

  if [[ $rc -eq 0 ]]; then
    log_json info rotate_net_ok "network rotation completed" run_id="$run_id"
  else
    log_json error rotate_net_fail "network rotation failed" run_id="$run_id" rc="$rc"
    exit $rc
  fi

  if [[ $verify_after -eq 1 ]]; then
    verify_net --run-id "$run_id" --iface "$iface" || true
  fi
}

verify_net() {
  local run_id="" iface="" check_public=1
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --run-id) run_id="$2"; shift 2 ;;
      --iface) iface="$2"; shift 2 ;;
      --no-public) check_public=0; shift ;;
      *) echo "Unknown flag: $1" >&2; exit 2 ;;
    esac
  done

  [[ -z "$iface" ]] && iface="${IFACE:-$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}' || true)}"

  local state mac ip4 defrt pubip=""
  state="$(ip -o link show "$iface" 2>/dev/null | awk '{print $9}' || true)"
  mac="$(cat /sys/class/net/"$iface"/address 2>/dev/null || true)"
  ip4="$(ip -o -4 addr show dev "$iface" 2>/dev/null | awk '{print $4}' || true)"
  defrt="$(ip route show default 2>/dev/null | awk '/default/ {print $3}' || true)"

  if [[ $check_public -eq 1 ]]; then
    pubip="$(curl -4sS --max-time 3 https://ifconfig.io || true)"
  fi

  local ok=1
  [[ "$state" == "UP" ]] || ok=0
  [[ -n "$ip4" ]] || ok=0
  [[ -n "$defrt" ]] || ok=0

  log_json info verify_net "verify summary" run_id="$run_id" iface="$iface" state="$state" mac="$mac" ip4="$ip4" default_gw="$defrt" public_ip="${pubip:-n/a}" ok="$ok"
  [[ $ok -eq 1 ]]
}

#--- Main ----------------------------------------------------------------------
cmd="${1:-}"; shift || true
case "$cmd" in
  rotate-net) rotate_net "$@" ;;
  verify-net) verify_net "$@" ;;
  *) usage; [[ -n "$cmd" ]] && exit 2 ;;
esac
