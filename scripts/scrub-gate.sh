#!/usr/bin/env bash
# Scrub gate: fail if anything machine-specific or personal made it into a tracked file.
#
# These skills were generalized from a personal ~/.claude/skills/ directory. This gate is what
# keeps the scrub from rotting: any path, hostname, hardware detail, security-posture note or
# personal reference that comes back shows up here. Run it before every push.
#
# PASS is EMPTY OUTPUT and exit 0. Any line printed is a hit to fix, not to exclude.
#
# It gates TRACKED FILES ONLY (git ls-files), because what ships is what matters — that also
# keeps untracked scratch and plugin working directories from producing phantom hits.
# /usr/bin/grep, not `grep`: some harnesses shadow grep with a wrapper that has its own regex
# limits, and `command grep` cannot be used through xargs because it is a shell builtin.
set -uo pipefail
cd "$(dirname "$0")/.."

# Excluded, each for a stated reason:
#   .claude-plugin/*.json  author / owner name, public by design
#   LICENSE                copyright holder, public by design
#   scripts/scrub-gate.sh  this file — it contains the patterns, so it matches itself
# NEXT-SESSION.md is deliberately NOT excluded: it ships with the repo, so it is gated like
# everything else. It was rewritten public-safe on 2026-09-13 rather than exempted.
EXCLUDE='^(\.claude-plugin/.*\.json|LICENSE|scripts/scrub-gate\.sh)$'

# 'hilliersm\b' deliberately does NOT match the GitHub handle 'hilliersmmain', which is public
# and appears in the README install lines; it still catches the bare username and home path.
PATTERN='hilliersm\b|\bsam\b|8CG3312|192\.168|tailscale|ufw|luks|threat|fable|advisor'
PATTERN+='|gnome-text-editor|espanso|/home/|sams-|pi3|hillier\.org|app state|precision'

mapfile -t FILES < <(git ls-files | /usr/bin/grep -Ev "$EXCLUDE")
[ ${#FILES[@]} -eq 0 ] && { echo "scrub-gate: no files to check" >&2; exit 2; }

if /usr/bin/grep -niE "$PATTERN" "${FILES[@]}"; then
  echo "scrub-gate: FAIL — fix the hits above; do not widen the exclude list." >&2
  exit 1
fi
exit 0
