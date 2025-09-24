SPDX-License-Identifier: MIT
© 2023-2025 Kehd Emmanuel H. Diaz

#!/usr/bin/env bash
# 
┌─────────────────────────
──────────────────────────
─────────┐
# │ ghostmode.sh v1.2.3 — GhostOps Stealth Firewall Module     │
# 
├─────────────────────────
──────────────────────────
─────────┤
# │ Author: Kehd Emmanuel H. Diaz                              │
# │ Purpose: Block LAN/multicast exposure while keeping WAN    │
# │ Modules: dry-run, snapshot, iface fallback, HOME fallback  │
# │ Last Updated: 2025-08-30                                   │
# 
└─────────────────────────
──────────────────────────
─────────┘

set -euo pipefail
: "${HOME:=/home/kehd}"  # Shell-safe fallback for sterile environments

CMD="${1:-}"
TABLE="ghost"

# Interface fallback: try nmcli, then default route
IFACE="$(ip route | awk '/default/ {print $5; exit}')"
IFACE="${IFACE:-wlan0}"  # Fallback to wlan0 if nothing found

# Defaults — override via env if needed
LAN_SUBNET="${LAN_SUBNET:-192.168.100.0/24}"
V6_LL="fe80::/10"
V6_MC="ff00::/8"

SNAPSHOT_DIR="$HOME/.ghostmode"
mkdir -p "$SNAPSHOT_DIR"

emit_rules() {
  cat <<RULES
add table inet ${TABLE}
add chain inet ${TABLE} input  { type filter hook input priority 0; policy 
accept; }
add chain inet ${TABLE} output { type filter hook output priority 0; policy 
accept; }

# Loopback
add rule inet ${TABLE} input  iif lo accept
add rule inet ${TABLE} output oif lo accept

# Established sessions
add rule inet ${TABLE} input  ct state established,related accept
add rule inet ${TABLE} output ct state established,related accept

# DHCP lease renewals (v4)
add rule inet ${TABLE} output meta oifname "${IFACE}" udp sport 68 udp dport 
67 accept
add rule inet ${TABLE} input  meta iifname "${IFACE}" udp sport 67 udp dport 
68 accept

# Block all IPv4 LAN traffic (including router UI)
add rule inet ${TABLE} input  meta iifname "${IFACE}" ip saddr ${LAN_SUBNET} 
log prefix "GHOST v4 IN " limit rate 10/minute drop
add rule inet ${TABLE} output meta oifname "${IFACE}" ip daddr ${LAN_SUBNET} 
log prefix "GHOST v4 OUT " limit rate 10/minute drop

# Block IPv6 link-local & multicast
add rule inet ${TABLE} input  meta iifname "${IFACE}" ip6 saddr ${V6_LL} drop
add rule inet ${TABLE} output meta oifname "${IFACE}" ip6 daddr ${V6_LL} drop
add rule inet ${TABLE} input  meta iifname "${IFACE}" ip6 saddr ${V6_MC} drop
add rule inet ${TABLE} output meta oifname "${IFACE}" ip6 daddr ${V6_MC} drop

# Block IPv4 multicast
add rule inet ${TABLE} input  meta iifname "${IFACE}" ip saddr 224.0.0.0/4 
drop
add rule inet ${TABLE} output meta oifname "${IFACE}" ip daddr 224.0.0.0/4 
drop
RULES
}

case "$CMD" in
  "--dry-run")
    echo "🔍 Dry-run: Previewing Ghost Mode rules for 
IFACE='${IFACE:-unknown}' and LAN='${LAN_SUBNET}'"
    emit_rules
    ;;

  "on")
    SNAPSHOT_FILE="${SNAPSHOT_DIR}/snapshot-before-$(date -u 
+%Y%m%dT%H%M%SZ).nft"
    sudo nft list ruleset > "$SNAPSHOT_FILE"
    emit_rules | sudo nft -f -
    echo "✅ Ghost Mode enabled on IFACE='${IFACE:-unknown}'. Table: 
${TABLE}"
    ;;

  "off")
    sudo nft delete table inet ${TABLE} 2>/dev/null || true
    echo "🧹 Ghost Mode disabled. Table ${TABLE} removed."
    ;;

  *)
    echo "Usage: $0 on|off|--dry-run"
    exit 1
    ;;
esac








