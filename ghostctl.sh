#!/usr/bin/env bash
# ┌────────────────────────────────────────────────────────────┐
# │ ghostctl.sh v1.2 — GhostOps Unified Control Suite          │
# ├────────────────────────────────────────────────────────────┤
# │ Author: Kehd Emmanuel H. Diaz                              │
# │ Location: ~/ghostops/ghostctl.sh                           │
# │ Modules: ghostmode, vpnkill, audit, status, dry-run, reset │
# │ + ghostnet (rotate-net, verify-net)                        │
# │ Version: 1.2                                               │
# │ Last Updated: 2025-08-31 10:20 PST                         │
# ├────────────────────────────────────────────────────────────┤
# │ Changelog:                                                 │
# │ - Unified ghostmode and vpnkill into stealth mode          │
# │ - Added timestamped audit logging to ghostctl.log          │
# │ - Modular command parsing with fallback help               │
# │ - Status module shows active interface and IP              │
# │ - Audit module tails kernel logs and ghostctl actions      │
# │ - Added ghostnet module for MAC/IP rotation + verification │
# └────────────────────────────────────────────────────────────┘

set -euo pipefail

CMD="${1:-}"
GHOST_SCRIPT="$HOME/scripts/ghostmode.sh"
VPN_SCRIPT="$HOME/scripts/vpnkill.sh"
GHOSTNET_SCRIPT="$HOME/ghostops/modules/ghostnet.sh"
AUDIT_LOG="$HOME/ghostops/logs/ghostctl.log"

function show_help() {
  cat <<EOF

GhostCTL v1.2 — Modular Privacy & Stealth Suite
Author: Kehd Emmanuel H. Diaz
Last Updated: 2025-08-31

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
  rotate-net   Rotate MAC/IP (DHCP or static) via ghostnet module
  verify-net   Show current MAC/IP/SSID and last rotation log
  --version    Show script metadata
  --help       Display this usage guide

EOF
}

function log_action() {
  echo "$(date '+%F %T') | $1" >> "$AUDIT_LOG"
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
  if [[ -f "$HOME/ghostops/logs/ghostnet.log" ]]; then
    echo "🧾 Last rotation:"
    tail -n 1 "$HOME/ghostops/logs/ghostnet.log"
  else
    echo "🧾 No ghostnet.log found."
  fi
}

# === Dispatcher ===
case "$CMD" in
  on)
    echo "🔒 Enabling Ghost Mode..."
    log_action "Ghost Mode ON"
    "$GHOST_SCRIPT" on
    ;;
  off)
    echo "🔓 Disabling Ghost Mode..."
    log_action "Ghost Mode OFF"
    "$GHOST_SCRIPT" off
    ;;
  vpn-on)
    echo "🛡️ Enabling VPN Kill-Switch..."
    log_action "VPN Kill-Switch ON"
    "$VPN_SCRIPT" on
    ;;
  vpn-off)
    echo "🧼 Disabling VPN Kill-Switch..."
    log_action "VPN Kill-Switch OFF"
    "$VPN_SCRIPT" off
    ;;
  stealth)
    echo "🕶️ Activating Full Stealth Mode..."
    log_action "Stealth Mode Activated"
    "$VPN_SCRIPT" on
    "$GHOST_SCRIPT" on
    ;;
  status)
    if sudo nft list table inet ghost &>/dev/null; then
      echo "🟢 Ghost Mode is ACTIVE"
    else
      echo "🔴 Ghost Mode is OFF"
    fi
    IFACE=$(nmcli -t -f DEVICE,STATE d | grep ":connected" | cut -d: -f1 || echo "unknown")
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
  --version)
    echo "GhostOps Control Suite — ghostctl.sh"
    echo "Version: 1.2"
    echo "Author: Kehd Emmanuel H. Diaz"
    echo "Last Updated: 2025-08-31"
    echo "Modules: ghostmode, vpnkill, audit, stealth, status, reset, ghostnet"
    ;;
  --help)
    show_help
    ;;
  *)
    show_help
    ;;
esac



