🕶️ GhostOps — Cockpit-Grade Privacy & Symbolic Stealth Suite
GhostOps is a modular, audit-safe control suite for stealth networking on Linux. It orchestrates nftables-based LAN/multicast isolation (Ghost Mode), a VPN kill-switch, timestamped audit logs, and snapshot-based rollback — all through a unified symbolic interface: ghostctl.

🚀 Features
🔒 Ghost Mode: Blocks LAN snooping, multicast leaks, and router UI access

🛡️ VPN Kill-Switch: Ensures no traffic escapes outside VPN tunnel

🧪 Dry-Run Mode: Preview firewall rules before applying

🧾 Audit Logging: Timestamped logs of every action

🧯 Snapshot Recovery: Saves nftables rulesets before changes

🌐 Interface Fallback: Auto-detects active network interface

🧹 Reset & Cleanup: Clears logs and snapshots safely

🧠 Symbolic Invocation: Tactical wrappers for upstream validation

🔁 Systemd Autorun: Optional autorun logic for RTC wake rituals

📦 Repo Layout
Path	Purpose
ghostctl	Unified symbolic control suite
scripts/ghostmode.sh	Stealth firewall logic (nftables)
scripts/vpnkill.sh	VPN kill-switch logic
logs/ghostctl.log	Timestamped audit log
# Enable Ghost Mode
./ghostctl ghostmode

# Enable VPN Kill-Switch
./ghostctl vpnkill

# Full Stealth Mode (both)
./ghostctl stealth

# Preview rules without applying
./ghostctl dry-run

# Check status
./ghostctl status

# View logs and snapshots
./ghostctl audit

# Reset logs and snapshots
./ghostctl reset

# Enable systemd autorun
./ghostctl autorun

🔧 Module: ghostmode.sh v1.2.2
Modular stealth firewall ruleset for LAN/multicast blocking with WAN passthrough. Supports dry-run previews, snapshot logging, and interface fallback logic.

Usage
ghostmode.sh on         # Apply Ghost Mode rules  
ghostmode.sh off        # Remove Ghost Mode table  
ghostmode.sh --dry-run  # Preview rules without applying  

Highlights

Encapsulated nftables rule emission via heredoc

Snapshot logging before rule changes

Interface auto-detection via nmcli and route fallback

IPv4 LAN, IPv6 link-local, and multicast blocking

Audit-safe and rollback-ready

🔐 Module: vpnkill.sh v1.2.3
Enforces VPN-only traffic by flushing all iptables rules and allowing only loopback and VPN interface (tun0). If the VPN is inactive, the script aborts to prevent accidental lockdown.

Usage
vpnkill.sh               # Activate kill-switch  
vpnkill.sh --dry-run     # Preview actions  
vpnkill.sh --intercede   # Symbolic wrapper for upstream validation  

Highlights

Pre-checks for active tun0 before applying rules

Symbolic invocation via --intercede for tactical diagnostics

Audit logs interface status and activation timestamp

Rotates logs at 50KB to prevent bloat

Snapshot-aware and rollback-safe

🧾 Audit Logging Philosophy
GhostOps treats every action as a forensic event. Logs are timestamped, interface-aware, and rotated to prevent chain bloat. Snapshots are stored before rule changes for rollback clarity.

Log File	Contents
ghostctl.log	Suite-level actions and status checks
vpnkill.log	VPN interface status and kill-switch logs

🧭 Philosophy
GhostOps is built for reproducibility, audit clarity, and stealth-grade privacy. Every module is modular, snapshot-aware, and contributor-friendly. Whether you're securing a workstation, onboarding a rental property, or invoking symbolic intercession — GhostOps is your cockpit.
