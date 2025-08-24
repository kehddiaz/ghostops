#!/usr/bin/env bash
# ┌────────────────────────────────────────────────────────────┐
# │ ghostctl.sh v1.1 — GhostOps Unified Control Suite          │
# ├────────────────────────────────────────────────────────────┤
# │ Author: Kehd Emmanuel H. Diaz                              │
# │ Location: ~/ghostops/ghostctl.sh                           │
# │ Modules: ghostmode, vpnkill, audit, status, dry-run, reset │
# │ Version: 1.1                                               │
# │ Last Updated: 2025-08-24 22:18 PST                         │
# ├────────────────────────────────────────────────────────────┤
# │ Changelog:                                                 │
# │ - Unified ghostmode and vpnkill into stealth mode          │
# │ - Added timestamped audit logging to ghostctl.log          │
# │ - Modular command parsing with fallback help               │
# │ - Status module shows active interface and IP              │
# │ - Audit module tails kernel logs and ghostctl actions      │
# └────────────────────────────────────────────────────────────┘

set -euo pipefail

CMD="${1:-}"
GHOST_SCRIPT="$HOME/scripts/ghostmode.sh"
VPN_SCRIPT="$HOME/scripts/vpnkill.sh"
AUDIT_LOG="$HOME/ghostops/logs/ghostctl.log"

function show_help() {
  cat <<EOF

GhostCTL v1.1 — Modular Privacy & Stealth Suite
Author: Kehd Emmanuel H. Diaz
Last Updated: 2025-08-24

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
  --version    Show script metadata
  --help       Display this usage guide

EOF
}

function log_action() {
  echo "$(date '+%F %T') | $1" >> "$AUDIT_LOG"
}

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
  --version)
    echo "GhostOps Control Suite — ghostctl.sh"
    echo "Version: 1.1"
    echo "Author: Kehd Emmanuel H. Diaz"
    echo "Last Updated: 2025-08-24"
    echo "Modules: ghostmode, vpnkill, audit, stealth, status, reset"
    ;;
  --help)
    show_help
    ;;
  *)
    show_help
    ;;
esac
