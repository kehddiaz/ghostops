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

---

## 📦 Repo Layout

| Path                        | Purpose                                      |
|-----------------------------|----------------------------------------------|
| `ghostctl.sh`               | Main control suite                          |
| `scripts/ghostmode.sh`      | Stealth firewall logic (nftables)           |
| `scripts/vpnkill.sh`        | VPN kill-switch logic                       |
| `logs/ghostctl.log`         | Timestamped audit log                       |
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

Usage:
ghostmode.sh on         # Apply Ghost Mode rules
ghostmode.sh off        # Remove Ghost Mode table
ghostmode.sh --dry-run  # Preview rules without applying

Highlights:

    Encapsulated nftables rule emission via heredoc

    Snapshot logging before rule changes

    Interface auto-detection via nmcli and route fallback

    IPv4 LAN, IPv6 link-local, and multicast blocking

    Audit-safe and rollback-ready
