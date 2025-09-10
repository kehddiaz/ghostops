# 🕶️ GhostOps Control Suite — `ghostctl.sh`

**Author:** Kehd Emmanuel H. Diaz  
**Version:** 1.1  
**Last Updated:** 2025-08-24  
**Location:** `~/ghostops/ghostctl.sh`

---

## 🔧 Overview

`ghostctl` is a unified command-line tool for managing stealth networking, VPN kill-switches, audit logs, and privacy hardening. Built for modular control and forensic traceability.

---

## 🚀 Usage

```bash
ghostctl [command]

### Available Commands:

| Command        | Description                                      |
|----------------|--------------------------------------------------|
| `on`           | Enable Ghost Mode (stealth firewall rules)       |
| `off`          | Disable Ghost Mode                               |
| `vpn-on`       | Activate VPN Kill-Switch (block non-VPN traffic) |
| `vpn-off`      | Disable VPN Kill-Switch                          |
| `stealth`      | Enable both Ghost Mode and VPN Kill-Switch       |
| `status`       | Show current interface and IP address            |
| `audit`        | View recent logs and snapshots                   |
| `dry-run`      | Preview Ghost Mode rules without applying them   |
| `reset`        | Clear logs and snapshots                         |
| `--version`    | Show script metadata                             |
| `--help`       | Display usage guide and available commands       |

