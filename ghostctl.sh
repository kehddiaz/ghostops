#!/usr/bin/env bash
# ┌────────────────────────────────────────────────────────────────────────────┐
# │ ghostctl.sh v1.3 — GhostOps Unified Control Suite                          │
# ├────────────────────────────────────────────────────────────────────────────┤
# │ Author: Kehd Emmanuel H. Diaz                                              │
# │ Location: ~/ghostops/ghostctl.sh                                           │
# │ Modules: ghostmode, vpnkill, audit, status, dry-run, reset, ghostnet       │
# │ + ghostvpn (vpn-up, vpn-connect, vpn-server-up, vpn-debug)                 │
# │ + ghosttest-suite (stress test)                                            │
# │ Version: 1.3                                                               │
# │ Last Updated: 2025-09-11 11:55 PST                                         │
# ├────────────────────────────────────────────────────────────────────────────┤
# │ Changelog:                                                                 │
# │ - Added ghostvpn-up and ghostvpn-connect for chained VPN rituals           │
# │ - Added ghostvpn-server-up and ghostvpn-debug for remote verification      │
# │ - Added ghosttest-suite for symbolic stress testing                        │
# │ - Modularized ghostnet helpers and dispatcher entries                      │
# └────────────────────────────────────────────────────────────────────────────┘

set -euo pipefail

CMD="${1:-}"
GHOST_SCRIPT="$HOME/scripts/ghostmode.sh"
VPN_SCRIPT="$HOME/scripts/vpnkill.sh"
GHOSTNET_SCRIPT="$HOME/ghostops/modules/ghostnet.sh"
AUDIT_LOG="$HOME/ghostops/logs/ghostctl.log"

# === ghostvpn variables ===
SERVER_HOST="${SERVER_HOST:-120.29.90.241}"
SERVER_USER="${SERVER_USER:-kehd}"
OVPN_FILE="${OVPN_FILE:-$HOME/ghostops/vpn/client1.ovpn}"
LOG_DIR="${LOG_DIR:-$HOME/ghostops/logs}"
mkdir -p "$LOG_DIR"

# === ghostvpn helpers ===
ghostvpn::_ts() { date '+%Y-%m-%d %H:%M:%S'; }
ghostvpn::_log() { echo "[$(ghostvpn::_ts)] $1" | tee -a "$2"; }

ghostvpn-server-up() {
  local LOG="$LOG_DIR/vpn-server.log"
  ghostvpn::_log "🚀 Starting VPN server on $SERVER_HOST" "$LOG"
  ssh "${SERVER_USER}@${SERVER_HOST}" "sudo systemctl start openvpn-server@server && sudo systemctl enable openvpn-server@server"
  ssh "${SERVER_USER}@${SERVER_HOST}" "sudo ss -lunpt | grep 1194" | tee -a "$LOG"
  ghostvpn::_log "✅ VPN server ritual complete." "$LOG"
}

ghostvpn-connect() {
  local LOG="$LOG_DIR/vpn-client.log"
  local TMP_OVPN="$(mktemp)"
  cp "$OVPN_FILE" "$TMP_OVPN"
  sed -i 's/^verb[[:space:]]\+[0-9]\+/verb 5/' "$TMP_OVPN"
  ghostvpn::_log "🔐 Connecting via OpenVPN..." "$LOG"
  trap 'ghostvpn::_log "🛑 Interrupted. Tearing down VPN." "$LOG"; sudo killall openvpn' INT TERM
  sudo openvpn --config "$TMP_OVPN" 2>&1 | tee -a "$LOG"
  rm -f "$TMP_OVPN"
}

ghostvpn-up() {
  local LOG="$LOG_DIR/vpn-up.log"
  ghostvpn::_log "⛓️  Starting chained VPN ritual..." "$LOG"
  ghostvpn-server-up
  ghostvpn-connect
  ghostvpn::_log "✅ VPN tunnel established." "$LOG"
}

ghostvpn-debug() {
  local LOG="$LOG_DIR/vpn-debug.log"
  ghostvpn::_log "🔎 VPN debug ritual" "$LOG"
  ssh "${SERVER_USER}@${SERVER_HOST}" "sudo systemctl status openvpn-server@server" | tee -a "$LOG"
  ssh "${SERVER_USER}@${SERVER_HOST}" "sudo ss -lunpt | grep 1194" | tee -a "$LOG"
  ghostvpn::_log "✅ Debug complete." "$LOG"
}

ghosttest-suite() {
  local LOG="$LOG_DIR/stress-suite.log"
  ghostvpn::_log "🚨 Starting GhostOps stress test suite" "$LOG"
  for i in {1..5}; do ghostvpn-up && ghostvpn::_log "Cycle $i complete" "$LOG"; sleep $((RANDOM % 3 + 1)); done
  ghostvpn-connect &
  sleep 3
  "$VPN_SCRIPT" on
  sleep 2
  "$VPN_SCRIPT" off
  killall -INT openvpn 2>/dev/null || true
  for iface in eth0 wlan0 lo ghost0; do ghostvpn::_log "Interface test: $iface" "$LOG"; done
  for i in {1..500}; do echo "Log entry $i" >> "$LOG_DIR/vpn-client.log"; done
  ghostvpn::_log "✅ Stress suite complete." "$LOG"
}

# === ghostnet helpers ===
function rotate_net() {
  echo "⚡️ Rotating MAC/IP (args: $*)"
  log_action "Network rotation initiated: $*"
  if [[ -x "$GHOSTNET_SCRIPT" ]]; then
    sudo bash "$GHOSTNET_SCRIPT" "$@"
  else
    echo "❌ ghostnet module not found at $GHOSTNET_SCRIPT"
    exit 1
  fi
}

function verify_net() {
  IFACE="${1:-wlan0}"
  echo "🔎 Verifying network identity on $IFACE"
  MAC="$(cat /sys/class/net/$IFACE/address 2>/dev/null || echo unknown)"
  IP4="$(ip -4 -o addr show dev "$IFACE" | awk '{print $4}' | cut -d/ -f1 || true)"
  SSID="$(nmcli -t -f active,ssid dev wifi | awk -F: '$1=="yes"{print $2; exit}' || true)"
  GW="$(ip route | awk '/default/ && /'"$IFACE"'/ {print $3; exit}' || true)"
  echo "    • MAC:  $MAC"
  echo "    • IPv4: ${IP4:-none}"
  echo "    • SSID: ${SSID:-none}"
  echo "    • GW:   ${GW:-auto}"
  if [[ -f "$LOG_DIR/ghostnet.log" ]]; then
    echo "🧾 Last rotation:"
    tail -n 1 "$LOG_DIR/ghostnet.log"
  else
    echo "🧾 No ghostnet.log found."
  fi
}

function show_help() {
  cat <<EOF

GhostCTL v1.3 — Modular Privacy & Stealth Suite
Author: Kehd Emmanuel H. Diaz
Last Updated: 2025-09-11

Usage: ghostctl <command>

Available Commands:
  on             Enable Ghost Mode
  off            Disable Ghost Mode
  vpn-on         Activate VPN Kill-Switch
  vpn-off        Disable VPN Kill-Switch
  stealth        Enable both Ghost Mode and VPN Kill-Switch
  status         Show current interface and IP
  audit          View recent logs and snapshots
  dry-run        Preview Ghost Mode rules
  reset          Clear logs and snapshots
  rotate-net     Rotate MAC/IP via ghostnet module
  verify-net     Show current MAC/IP/SSID
  vpn-up         Run full VPN ritual (server + client)
  vpn-connect    Connect VPN client only
  vpn-server-up  Start VPN server remotely
  vpn-debug      Run VPN diagnostics
  stress         Run full GhostOps stress test suite
  --version      Show script metadata
  --help         Display this usage guide

EOF
}

function log_action() {
  echo "$(date '+%F %T') | $1" >> "$AUDIT_LOG"
}

# === Dispatcher ===
case "$CMD" in
  on) echo "🔒 Enabling Ghost Mode..."; log_action "Ghost Mode ON"; "$GHOST_SCRIPT" on ;;
  off) echo "🔓 Disabling Ghost Mode..."; log_action "Ghost Mode OFF"; "$GHOST_SCRIPT" off ;;
  vpn-on) echo "🛡️ Enabling VPN Kill-Switch..."; log_action "VPN Kill-Switch ON"; "$VPN_SCRIPT" on ;;
  vpn-off) echo "🧼 Disabling VPN Kill-Switch..."; log_action "VPN Kill-Switch OFF"; "$VPN_SCRIPT" off ;;
  stealth) echo "🕶️ Activating Full Stealth Mode..."; log_action "Stealth Mode Activated"; "$VPN_SCRIPT" on; "$GHOST_SCRIPT" on ;;
  status)
    if sudo nft list table inet ghost &>/dev/null; then echo "🟢 Ghost Mode is ACTIVE"; else echo "🔴 Ghost Mode is OFF"; fi
    IFACE=$(nmcli -t
    IP=$(ip addr show "$IFACE" | grep 'inet ' | awk '{print $2}' || echo "N/A")
    echo "🌐 Interface: $IFACE"
    echo "📡 IP Address: $IP"
    ;;
  audit)
    echo "📁 Recent Snapshots:"
    ls -lt ~/.ghostmode/ | head -n 5
    echo "📜 Recent Logs:"
    sudo journalctl -g "GHOST v4" -n 20
    echo "🧾 ghostctl actions:"
    tail -n 10 "$AUDIT_LOG"
    ;;
  dry-run)
    echo "🧪 Dry-run: Previewing Ghost Mode rules..."
    "$GHOST_SCRIPT" --dry-run
    ;;
  reset)
    echo "🧹 Resetting GhostOps logs and snapshots..."
    rm -rf ~/.ghostmode/*
    > "$AUDIT_LOG"
    echo "✅ Cleanup complete."
    ;;
  rotate-net)
    shift
    rotate_net "$@"
    ;;
  verify-net)
    shift
    verify_net "$@"
    ;;
  vpn-up)
    ghostvpn-up
    ;;
  vpn-connect)
    ghostvpn-connect
    ;;
  vpn-server-up)
    ghostvpn-server-up
    ;;
  vpn-debug)
    ghostvpn-debug
    ;;
  stress)
    ghosttest-suite
    ;;
  --version)
    echo "GhostOps Control Suite — ghostctl.sh"
    echo "Version: 1.3"
    echo "Author: Kehd Emmanuel H. Diaz"
    echo "Last Updated: 2025-09-11"
    echo "Modules: ghostmode, vpnkill, audit, stealth, status, reset, ghostnet, ghostvpn, ghosttest-suite"
    ;;
  --help)
    show_help
    ;;
  *)
    show_help
    ;;
esac


