#!/usr/bin/env bash
# hud.sh — statusline proxy in front of claude-hud, plus an ASCII robot.
#
# Claude Code calls THIS (settings.json statusLine.command), not claude-hud.
# We forward stdin to claude-hud, then render a 5-line robot below it and a
# Nerd-Font dispatch line.
#
# NO external deps for layout: the robot is positioned with pure bash math on
# OUR OWN ascii strings (the bubble width = len(msg)+6), never by measuring
# claude-hud's output. The statusline env lacks perl on PATH, so anything that
# shelled out to measure width collapsed live — this avoids that entirely.
# Box-drawing art only; Nerd Font icons embedded as UTF-8 bytes. bash 3.2 ok.

set -uo pipefail
sp() { printf '%*s' "$1" ''; }

input=$(cat)

HUD_DIST=$(find "$HOME/.claude/plugins/cache/claude-hud/claude-hud" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort -V | tail -1)/dist/index.js
hud=""
[[ -f "$HUD_DIST" ]] && hud=$(printf '%s' "$input" | node "$HUD_DIST" 2>/dev/null)

dir=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // "."' 2>/dev/null)
[[ -n "$dir" ]] || dir="."
root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || true)

G=$'\033[32m'; Y=$'\033[33m'; B=$'\033[38;5;208m'; DIM=$'\033[2m'; X=$'\033[0m'

# Nerd Font glyphs (UTF-8 bytes): rocket, play, warning-triangle
I_DISP=$(printf '\xef\x84\xb5'); I_RUN=$(printf '\xef\x81\x8b'); I_STUCK=$(printf '\xef\x81\xb1')

# --- always-on dispatch line --------------------------------------------------
# "running" = worktree alive + touched recently; "stuck" = self-reported blocked
# OR in_progress but untouched for 2h+ (dead).
dispatch_line() {
  local run=0 stuck=0 f st wt up ue age now
  now=$(date -u +%s)
  if [[ -n "$root" && -d "$root/.dispatch/status" ]]; then
    while IFS= read -r f; do
      st=$(grep -m1 -E '^- \*\*status\*\*:' "$f" 2>/dev/null | sed -E 's/^.*:[[:space:]]*//' | awk '{print $1}')
      case "$st" in in_progress|blocked) ;; *) continue ;; esac
      wt=$(grep -m1 -E '^- \*\*worktree\*\*:' "$f" 2>/dev/null | sed -E 's/^.*:[[:space:]]*//')
      [[ -n "$wt" && -d "$wt" ]] || continue
      if [[ "$st" == blocked ]]; then stuck=$((stuck+1)); continue; fi
      up=$(grep -m1 -E '^- \*\*updated\*\*:' "$f" 2>/dev/null | sed -E 's/^.*:[[:space:]]*//')
      ue=$(date -ju -f "%Y-%m-%dT%H:%M:%SZ" "$up" +%s 2>/dev/null || echo 0)
      age=$(( now - ue ))
      if (( ue > 0 && age > 7200 )); then stuck=$((stuck+1)); else run=$((run+1)); fi
    done < <(find "$root/.dispatch/status" -maxdepth 1 -name '*.md' 2>/dev/null)
  fi
  local rc=$DIM sc=$DIM
  (( run )) && rc=$G; (( stuck )) && sc=$Y
  printf '%s%s ᴅɪꜱᴘᴀᴛᴄʜ%s   %s%s %d running%s   %s%s %d stuck%s' \
    "$B" "$I_DISP" "$X" "$rc" "$I_RUN" "$run" "$X" "$sc" "$I_STUCK" "$stuck" "$X"
}

# --- compose: claude-hud, then the dispatch line ------------------------------
out="$hud"
out+=$'\n'"$(dispatch_line)"
printf '%s' "$out"
