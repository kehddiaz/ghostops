# 🕶️ GhostOps — Cockpit‑Grade Privacy & Stealth Suite

**GhostOps** is a modular, audit‑safe control suite for stealth networking on Linux.  
It unifies nftables‑based LAN/multicast isolation, a VPN kill‑switch, audit logging, snapshot rollback, and systemd autorun — all via `ghostctl`.

## 🚀 Features
- 🔒 **Ghost Mode** — Block LAN snooping, multicast leaks, router UI
- 🛡️ **VPN Kill‑Switch** — No traffic outside VPN tunnel
- 🧪 **Dry‑Run Mode** — Preview rules before applying
- 🧾 **Audit Logs** — Timestamped, rotated, interface‑aware
- 🧯 **Snapshot Recovery** — Rollback‑ready rulesets
- 🌐 **Interface Fallback** — Auto‑detect active NIC
- 🔁 **Systemd Autorun** — Optional stealth on boot
- ♻️ **Post‑Reboot Persistence** — Stealth flag survives cold boots

## 📦 Layout
| Path                  | Purpose                          |
|-----------------------|----------------------------------|
| `ghostctl`            | Unified control suite            |
| `scripts/ghostmode.sh`| Stealth firewall logic            |
| `scripts/vpnkill.sh`  | VPN kill‑switch logic             |
| `logs/ghostctl.log`   | Suite‑level audit log             |

## 🔧 Usage
```bash
./ghostctl ghostmode     # Enable Ghost Mode
./ghostctl vpnkill       # Enable VPN Kill‑Switch
./ghostctl stealth       # Both modules
./ghostctl dry-run       # Preview rules
./ghostctl status        # Check status
./ghostctl audit         # View logs/snapshots
./ghostctl reset         # Clear logs/snapshots
./ghostctl autorun       # Enable autorun

📌 v1.3.0 Highlights
✅ Verified post‑reboot stealth flag persistence

✅ Updated ghostctl status logic

✅ .gitignore cleanup for backup artifacts

✅ Docs refreshed for autorun & persistence
