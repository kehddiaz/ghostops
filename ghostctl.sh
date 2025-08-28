#!/usr/bin/env bash
# ┌────────────────────────────────────────────────────────────────┐
# │ ghostctl.sh v1.2.2 — GhostOps Unified Control Suite           │
# ├────────────────────────────────────────────────────────────────┤
# │ Author: Kehd Emmanuel H. Diaz                                  │
# │ Location: ~/ghostops/ghostctl.sh                               │
# │ Modules: ghostmode, vpnkill, audit, status, dry-run, reset     │
# │ Version: 1.2.2                                                 │
# │ Last Updated: 2025-08-28                                       │
# └────────────────────────────────────────────────────────────────┘

set -euo pipefail

# ---[ paths and config ]------------------------------------------------------
CMD="${1:-}"
BASE_DIR="$HOME/ghostops"
GHOST_SCRIPT="$BASE_DIR/scripts/ghostmode.sh"
VPN_SCRIPT="$BASE_DIR/scripts/vpnkill.sh"

AUDIT_DIR="${AUDIT_DIR:-$BASE_DIR/logs}"
SNAP_DIR="$AUDIT_DIR/snapshots"
AUDIT_LOG="$AUDIT_DIR/ghostctl.log"

mkdir -p "$AUDIT_DIR" "$SNAP_DIR"

# ---[ usage/help ]------------------------------------------------------------
show_help() {
  cat <<EOF

GhostCTL v1.2.2 — Modular Privacy & Stealth Suite
Author: Kehd Emmanuel H. Diaz
Last Updated: 2025-08-28

Usage: ghostctl <command>

Available Commands:
  on           Enable Ghost Mode (stealth firewall rules)
  off          Disable Ghost Mode
  vpn-on       Activate VPN Kill-Switch (block non-VPN traffic)
  vpn-off      Disable VPN Kill-Switch
  stealth      Enable both Ghost Mode and VPN Kill-Switch
  status       Show current interface and IP address
  audit        View recent logs and snapshots
  dry-run      Preview Ghost Mode rules without applying them
  reset        Clear logs and snapshots
  autorun      Enable GhostOps autorun on system startup
  --version    Show script metadata
  --help       Display this usage guide

EOF
}

# ---[ logging ]---------------------------------------------------------------
log_action() {
  local msg="$1"
  local MAX_LOG_SIZE=51200 # 50KB

  if [[ -f "$AUDIT_LOG" && $(stat -c%s "$AUDIT_LOG") -gt $MAX_LOG_SIZE ]]; then
    mv -f "$AUDIT_LOG" "$AUDIT_LOG.bak"
    : > "$AUDIT_LOG"
  fi

  printf '%s | %s\n' "$(date '+%F %T')" "$msg" >> "$AUDIT_LOG"
}

# ---[ status helpers ]--------------------------------------------------------
resolve_default_iface() {
  local dev
  dev=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++){if($i=="dev"){print $(i+1); exit}}}')
  [[ -z "${dev:-}" ]] && dev=$(ip -o -4 route show default 2>/dev/null | awk '{print $5}' | head -n1)
  [[ -z "${dev:-}" ]] && dev=$(ip -o link show up 2>/dev/null | awk -F': ' '{print $2}' | grep -Ev '^(lo|docker[0-9]*|veth.*|br-.*)$' | head -n1)
  printf '%s' "${dev:-}"
}

get_ipv4_for_iface() {
  local iface="$1"
  ip -o -4 addr show dev "$iface" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1
}

list_active_ifaces_clean() {
  ip -o link show up 2>/dev/null | awk -F': ' '{print $2}' | grep -Ev '^(lo|docker[0-9]*|veth.*|br-.*)$' | tr '\n' ' ' | sed 's/[[:space:]]*$//'
}

snapshot_status() {
  local gm="$1" iface="$2" ip="$3" iflist="$4" ts
  ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  mkdir -p "$SNAP_DIR"
  {
    echo "timestamp_utc=$ts"
    echo "ghost_mode=$gm"
    echo "iface=$iface"
    echo "ip=$ip"
    echo "active_ifaces=$iflist"
  } > "$SNAP_DIR/status_${ts}.log"
}

# ---[ command implementations ]-----------------------------------------------
on_command() {
  echo "🔒 Enabling Ghost Mode..."
  log_action "Ghost Mode ON"
  "$GHOST_SCRIPT" on
}

off_command() {
  echo "🔓 Disabling Ghost Mode..."
  log_action "Ghost Mode OFF"
  "$GHOST_SCRIPT" off
}

vpn_on_command() {
  echo "🛡️ Enabling VPN Kill-Switch..."
  log_action "VPN Kill-Switch ON"
  "$VPN_SCRIPT" on
}

vpn_off_command() {
  echo "🧼 Disabling VPN Kill-Switch..."
  log_action "VPN Kill-Switch OFF"
  "$VPN_SCRIPT" off
}

stealth_command() {
  echo "🕶️ Activating Full Stealth Mode..."
  log_action "Stealth Mode Activated"
  "$VPN_SCRIPT" on || echo "[i] VPN script skipped or failed."
  "$GHOST_SCRIPT" on
}

status_command() {
  local gm_state iface ip iflist
  if command -v nft >/dev/null 2>&1; then
    if sudo nft list table inet ghost &>/dev/null; then
      gm_state="ACTIVE"
    else
      gm_state="OFF"
    fi
  else
    gm_state="UNKNOWN"
  fi

  iface="$(resolve_default_iface)"
  iflist="$(list_active_ifaces_clean)"
  ip="$(get_ipv4_for_iface "$iface")"

  [[ -z "${ip:-}" ]] && ip="N/A"
  [[ -z "${iface:-}" ]] && iface="N/A"
  [[ -z "${iflist:-}" ]] && iflist="N/A"

  case "$gm_state" in
    ACTIVE) echo -e "\e[32m🟢 Ghost Mode is ACTIVE\e[0m" ;;
    OFF)    echo -e "\e[31m🔴 Ghost Mode is OFF\e[0m" ;;
    *)      echo -e "\e[33m🟡 Ghost Mode state: UNKNOWN (nft not found)\e[0m" ;;
  esac

  echo "🌐 Interface: $iface"
  echo "📡 IP Address: $ip"
  echo "🧭 Active ifaces: $iflist"

  snapshot_status "$gm_state" "$iface" "$ip" "$iflist"
}

audit_command() {
  echo "📁 Recent Snapshots:"
  if compgen -G "$SNAP_DIR/status_*.log" > /dev/null; then
    ls -lt "$SNAP_DIR"/status_*.log | head -n 5
  else
    echo "  (no snapshots yet)"
  fi

  echo "📜 Recent Logs:"
  [[ -f "$AUDIT_LOG" ]] && tail -n 20 "$AUDIT_LOG" || echo "  (no ghostctl.log yet)"

  if command -v journalctl >/dev/null 2>&1; then
    echo "🗄️  journalctl (last 20 matching 'GHOST'):"
    journalctl -g "GHOST" -n 20 || true
  fi
}

dry_run_command() {
  echo "🧪 Dry-run: Previewing Ghost Mode rules..."
  "$GHOST_SCRIPT" --dry-run
}

reset_command() {
  echo "🧹 Resetting GhostOps logs and snapshots..."
  rm -f "$SNAP_DIR"/status_*.log 2>/dev/null || true
  : > "$AUDIT_LOG"
  echo "✅ Cleanup complete."
}

autorun_command() {
  local svc_path="/etc/systemd/system/ghostops.service"
  echo "⚙️ Setting up GhostOps autorun via systemd..."
  log_action "Autorun setup initiated"

  sudo tee "$svc_path" > /dev/null <<EOF
[Unit]
Description=GhostOps Stealth Suite
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=$BASE_DIR/ghostctl.sh stealth
RemainAfterExit=true
StandardOutput=append:$AUDIT_LOG
StandardError=append:$AUDIT_LOG

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reexec
  sudo systemctl daemon-reload
  sudo systemctl enable ghostops.service

  echo "✅ GhostOps will now run stealth mode on every startup."
  log_action "Autorun enabled via systemd"
}

version_command() {
  echo "GhostOps Control Suite — ghostctl.sh"
  echo "Version: 1.2.2"
  echo "Author: Kehd Emmanuel H. Diaz"
  echo "Last Updated: 2025-08-28"
  echo "Modules: ghostmode, vpnkill, audit, stealth, status, reset, autorun"
}

# ---[ main ]------------------------------------------------------------------
case "$CMD" in
  on)        on_command ;;
  off)       off_command ;;
  vpn-on)    vpn_on_command ;;
  vpn-off)   vpn_off_command ;;
  stealth)   stealth_command ;;
  status)    status_command ;;
  audit)     audit_command ;;
  dry-run)   dry_run_command ;;
  reset)     reset_command ;;
  autorun)   autorun_command ;;
  --version) version_command ;;
  --help)    show_help ;;
  *)         echo "❌ Unknown command: $CMD"; show_help; exit 1 ;;
esac

