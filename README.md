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

---

## ✅ Step 2: Save and Commit

```bash
git add README.md
git commit -m "docs: update README for ghostctl v1.2 with usage, layout, safety"
git push origin main
