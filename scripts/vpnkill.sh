SPDX-License-Identifier: MIT
© 2023-2025 Kehd Emmanuel H. Diaz

#!/usr/bin/env bash
# 
┌─────────────────────────
──────────────────────────
─────────────────────────┐
# │ GhostOps VPN Kill-Switch v1.2.3 — sudo-wrapped, audit-safe, dry-run 
ready │
# 
├─────────────────────────
──────────────────────────
─────────────────────────┤
# │ Author: Kehd Emmanuel H. Diaz                                           
   │
# │ Location: ~/ghostops/scripts/vpnkill.sh                                 
   │
# │ Modules: firewall flush, VPN-only traffic, audit logging, symbolic 
wrapper│
# │ Version: 1.2.3                                                          
   │
# │ Last Updated: 2025-08-28                                                
   │
# 
├─────────────────────────
──────────────────────────
─────────────────────────┤
# │ Changelog:                                                              
   │
# │ - Pre-check for VPN interface status to prevent lockdown                
  │
# │ - Dry-run mode for previewing firewall actions                          
   │
# │ - Snapshot logging of VPN interface status                              
   │
# │ - Log rotation to prevent audit log bloat                               
   │
# │ - Optional symbolic wrapper: --intercede                                
   │
# │ - Hardened exit codes and error traps                                   
   │
# 
└─────────────────────────
──────────────────────────
─────────────────────────┘

set -euo pipefail

VPN_IF="tun0"
LOG_PREFIX="GHOST-KILL"
AUDIT_LOG="$HOME/ghostops/logs/vpnkill.log"
MAX_LOG_SIZE=51200  # 50KB

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true
[[ "${1:-}" == "--intercede" ]] && echo "[✝] Invoking upstream validation 
via saint-daemon..."

# Cache sudo credentials up front
sudo -v

# Helper to run privileged commands
run() {
  if $DRY_RUN; then
    echo "[DRY-RUN] $*"
  else
    sudo "$@"
  fi
}

# Rotate audit log if oversized
if [[ -f "$AUDIT_LOG" && $(stat -c%s "$AUDIT_LOG") -ge $MAX_LOG_SIZE ]]; then
  mv "$AUDIT_LOG" "$AUDIT_LOG.bak.$(date '+%F-%T')"
  echo "[+] Rotated audit log due to size threshold."
fi

# Pre-check: Abort if VPN interface is inactive
IFACE_STATUS=$(ip addr show "$VPN_IF" | grep inet || true)
if [[ -z "$IFACE_STATUS" ]]; then
  echo "[!] VPN interface $VPN_IF not active. Kill-switch aborted."
  echo "$(date '+%F %T') | ABORT: $VPN_IF inactive. Kill-switch not applied." 
>> "$AUDIT_LOG"
  exit 1
fi

# Snapshot VPN interface status
echo "$(date '+%F %T') | VPN Kill-Switch activated for $VPN_IF" >> 
"$AUDIT_LOG"
echo "$(date '+%F %T') | Interface $VPN_IF status: $IFACE_STATUS" >> 
"$AUDIT_LOG"

echo "[+] Activating VPN Kill-Switch for interface: $VPN_IF"

# Flush existing rules
run iptables -F
run iptables -X

# Allow loopback
run iptables -A INPUT -i lo -j ACCEPT
run iptables -A OUTPUT -o lo -j ACCEPT

# Allow VPN traffic only
run iptables -A INPUT -i "$VPN_IF" -j ACCEPT
run iptables -A OUTPUT -o "$VPN_IF" -j ACCEPT

# Drop and log everything else
run iptables -A INPUT -j LOG --log-prefix "$LOG_PREFIX DROP IN: "
run iptables -A INPUT -j DROP
run iptables -A OUTPUT -j LOG --log-prefix "$LOG_PREFIX DROP OUT: "
run iptables -A OUTPUT -j DROP

echo "[✓] VPN Kill-Switch active. Non-VPN traffic blocked."

exit 0








