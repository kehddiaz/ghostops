SPDX-License-Identifier: MIT
© 2023–2025 Kehd Emmanuel H. Diaz

#!/usr/bin/env bash
# ============================================
#  GhostOps Push Ritual v2.1
#  Starts SSH agent if needed, loads key,
#  verifies GitHub, syncs with remote,
#  and pushes changes.
# ============================================

# 1. Start SSH agent if not running
if ! ssh-add -l >/dev/null 2>&1; then
    echo "[GhostOps] Starting SSH agent..."
    eval "$(ssh-agent -s)" >/dev/null
    ssh-add -q ~/.ssh/id_ed25519
fi

# 2. Verify GitHub authentication
echo "[GhostOps] Testing GitHub connection..."
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "[GhostOps] SSH authentication OK"
else
    echo "[GhostOps] SSH test failed — check your key, agent, or GitHub 
settings"
    exit 1
fi

# 3. Sync with remote main branch
echo "[GhostOps] Pulling latest changes..."
git pull --rebase origin main || { echo "[GhostOps] Pull failed"; exit 1; }

# 4. Push local commits
echo "[GhostOps] Pushing to GitHub..."
git push origin main && echo "[GhostOps] Push complete!"
