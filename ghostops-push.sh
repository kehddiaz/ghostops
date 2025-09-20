#!/usr/bin/env bash
# ============================================
#  GhostOps Push Ritual v2
#  Starts SSH agent, loads key, verifies GitHub,
#  syncs with remote, and pushes changes.
# ============================================

# 1. Start SSH agent
eval "$(ssh-agent -s)" >/dev/null

# 2. Load your new ED25519 key
ssh-add -q ~/.ssh/id_ed25519

# 3. Verify GitHub authentication (parse output instead of exit code)
echo "[GhostOps] Testing GitHub connection..."
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "[GhostOps] SSH authentication OK"
else
    echo "[GhostOps] SSH test failed"
    exit 1
fi

# 4. Sync with remote main branch
echo "[GhostOps] Pulling latest changes..."
git pull --rebase origin main || { echo "[GhostOps] Pull failed"; exit 1; }

# 5. Push local commits
echo "[GhostOps] Pushing to GitHub..."
git push origin main && echo "[GhostOps] Push complete!"

