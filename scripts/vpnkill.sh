#!/bin/bash
# GhostOps VPN Kill-Switch v1.0
# Blocks all traffic except via tun0 (VPN), logs dropped packets

VPN_IF="tun0"
LOG_PREFIX="GHOST-KILL"
AUDIT_LOG="$HOME/ghostops/logs/vpnkill.log"

echo "[+] Activating VPN Kill-Switch for interface: $VPN_IF"
echo "$(date '+%F %T') | VPN Kill-Switch activated" >> "$AUDIT_LOG"

# Flush existing rules
iptables -F
iptables -X

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow VPN traffic only
iptables -A INPUT -i "$VPN_IF" -j ACCEPT
iptables -A OUTPUT -o "$VPN_IF" -j ACCEPT

# Drop and log everything else
iptables -A INPUT -j LOG --log-prefix "$LOG_PREFIX DROP IN: "
iptables -A INPUT -j DROP
iptables -A OUTPUT -j LOG --log-prefix "$LOG_PREFIX DROP OUT: "
iptables -A OUTPUT -j DROP

echo "[✓] VPN Kill-Switch active. Non-VPN traffic blocked."
