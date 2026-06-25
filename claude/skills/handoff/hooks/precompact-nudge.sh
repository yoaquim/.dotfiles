#!/usr/bin/env bash
# PreCompact hook (matcher "auto") — nudge toward a deliberate /handoff.
#
# Fires when Claude Code is about to AUTO-compact: the window filled before you
# handed off. Compaction is lossy — rejected approaches, exact next steps, and
# stated constraints often vanish. This prints a notice the USER sees (Claude
# can't act on PreCompact stderr) and does NOT block: blocking a full window
# would trap the session. Real prevention is the claude-hud context bar + a
# timely /handoff; this is the last-ditch reminder.
#
# Exit 0 always — never interfere with compaction itself.

set -uo pipefail
trap 'exit 0' ERR

cat >&2 <<'EOF'
⚠️  Auto-compact is firing — context will be summarized lossily (rejected paths,
    next steps, constraints often drop). Next time run /handoff at a clean
    boundary (~70%) before this point. To recover deliberately now: /clear, then
    /pickup the latest handoff (write one first if you haven't).
EOF
exit 0
