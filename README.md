# 🕶️ GhostOps — Privacy & Stealth Suite

Modular, audit‑safe control suite for stealth networking on Linux.  
Blocks LAN snooping, enforces VPN kill‑switch, rotates MACs, logs every change, and recovers fast.

## 🚀 Features
- 🔒 Ghost Mode — LAN/multicast isolation
- 🛡️ VPN Kill‑Switch — No leaks outside tunnel
- 🔄 MAC Rotation — Randomize hardware address on demand or boot
- 🧾 JSONL Audit Logs — Forensic‑complete, rotated
- 📡 Verify‑Net — MAC/IP/gateway/public IP snapshot
- 🧯 Snapshot Rollback — Safe recovery
- 🔁 Systemd Autorun — Stealth on boot

## 🔧 Usage
```bash
./ghostctl ghostmode     # Enable Ghost Mode
./ghostctl vpnkill       # Enable VPN Kill‑Switch
./ghostctl stealth       # Both modules
./ghostctl mac-rotate    # Rotate MAC address
./ghostctl verify-net    # Log & show network state
./ghostctl status        # Check status

📌 v1.4.0 — Added verify-net, MAC rotation, refined logs, improved status output

<<<<<<< HEAD
If you want, I can also give you a **one‑liner Quick Start** to drop right under the title so new users can clone and run GhostOps in seconds — that would make this minimal README even more powerful for onboarding.
=======
✅ Updated ghostctl status logic

✅ .gitignore cleanup for backup artifacts

✅ Docs refreshed for autorun & persistence

>>>>>>> 851683c (Refresh: symbolic timestamp update — no functional changes)

