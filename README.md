# 🕶️ GhostOps — Cockpit-Grade Privacy & Stealth Suite

GhostOps is a modular control suite for stealth networking on Linux. It combines nftables-based LAN/multicast isolation (Ghost Mode), a VPN kill-switch, timestamped audit logs, and snapshot-based rollback — all orchestrated through a unified command-line interface.

---

## 🚀 Features

- 🔒 **Ghost Mode**: Blocks LAN snooping, multicast leaks, and router UI access  
- 🛡️ **VPN Kill-Switch**: Ensures no traffic escapes outside VPN tunnel  
- 🧪 **Dry-Run Mode**: Preview firewall rules before applying  
- 🧾 **Audit Logging**: Timestamped logs of every action  
- 🧯 **Snapshot Recovery**: Saves nftables rulesets before changes  
- 🌐 **Interface Fallback**: Auto-detects active network interface  
- 🧹 **Reset & Cleanup**: Clears logs and snapshots safely  
- 🧠 **Symbolic Invocation**: Tactical wrappers for upstream validation  

---

## 📦 Repo Layout

| Path                        | Purpose                                      |
|-----------------------------|----------------------------------------------|
| `ghostctl.sh`               | Main control suite                          |
| `scripts/ghostmode.sh`      | Stealth firewall logic (nftables)           |
| `scripts/vpnkill.sh`        | VPN kill-switch logic                       |
| `logs/ghostctl.log`         | Timestamped audit log                       |
| `logs/vpnkill.log`          | VPN interface status and activation log     |
| `docs/ghostmode.md`         | Operational philosophy and suite overview   |
| `~/.ghostmode/`             | Snapshot directory (not tracked by Git)     |

---

## 🧭 Usage

```bash
# Enable Ghost Mode
./ghostctl.sh on

# Enable VPN Kill-Switch
./ghostctl.sh vpn-on

# Full Stealth Mode (both)
./ghostctl.sh stealth

# Preview rules without applying
./ghostctl.sh dry-run

# Check status
./ghostctl.sh status

# View logs and snapshots
./ghostctl.sh audit

# Reset logs and snapshots
./ghostctl.sh reset

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

---

This version is clean, readable, and contributor-ready. Want to scaffold a `ghostctl.md` next for suite-level flags and symbolic wrappers? Or prep a `CONTRIBUTING.md` with onboarding logic and visual identity assets? Let’s keep the cockpit sharp.
