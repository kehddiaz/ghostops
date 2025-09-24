SPDX-License-Identifier: MIT
© 2023-2025 Kehd Emmanuel H. Diaz

#!/usr/bin/env bash
# ==============================================================
#  GhostMaint – Pre‑reboot Release Ritual
# --------------------------------------------------------------
#  Author: Kehd Emmanuel H. Diaz
#  Created: $(date '+%Y-%m-%d')   # update as needed
#  Purpose:
#    Runs a pre‑reboot maintenance ritual:
#      - Logs start of ritual to ghostops log
#      - Executes cleanup script
#      - Scans non‑root partitions for filesystem checks
#      - Skips swap, root, and whole‑disk devices with mounted children
#      - Runs fsck on safe, unmounted partitions
#
#  Requirements:
#    - ghostlog command available in PATH
#    - /usr/local/bin/cleanup-before-reboot.sh script present and executable
#    - sudo privileges for fsck
#
#  Usage:
#    Source in your shell or .bashrc:
#      source /path/to/ghostmaint.sh
#    Then run:
#      ghostmaint
#
#  Notes:
#    - All actions are logged to $HOME/ghostops/ghostmaint.log
#    - Designed for audit‑safe, legacy‑grade maintenance rituals
# ==============================================================
ghostmaint() {
    local LOG="$HOME/ghostops/ghostmaint.log"
    local TIMESTAMP
    TIMESTAMP="$(date '+%F %T')"
    local TAG="maint-$(date +%Y.%m.%d)"

    echo "[$TIMESTAMP]  GhostMaint starting..." | tee -a "$LOG"
    ghostlog "maint:start" "GhostMaint ritual initiated @ $TIMESTAMP"

    # Cleanup
    if sudo /usr/local/bin/cleanup-before-reboot.sh; then
        echo "[$TIMESTAMP] Cleanup script completed." | tee -a "$LOG"
    else
