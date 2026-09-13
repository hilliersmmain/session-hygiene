#!/usr/bin/env bash
# Run before every push. Four checks; all must pass.
#
#   1. the scrub gate            — nothing machine-specific or personal in a tracked file
#   2. the plugin manifest       — .claude-plugin/*.json, strict (unrecognized fields fail)
#   3. the marketplace manifest  — .claude-plugin/marketplace.json, strict
#   4. the components            — skills/, strict
#
# Checks 2 and 3 BOTH name their file explicitly, and must keep doing so. `claude plugin
# validate .` resolves the directory to ONE manifest, and which one depends on what exists:
# with only plugin.json present it picks plugin.json, but the moment marketplace.json is added
# it silently switches to that instead and reports contents: []. A directory-target check
# therefore changes meaning under you — it validated the plugin manifest when it was written
# and the marketplace manifest a commit later, leaving plugin.json checked by nothing.
# Measured 2026-09-13 (claude 2.1.268) by adding marketplace.json and re-reading .target.
#
# Why check 2 is JSON-and-jq rather than `validate --strict .`:
# --strict on the repo root also walks the root CLAUDE.md and warns that it "is not loaded as
# project context", then fails because --strict treats warnings as errors. That warning is
# about plugin CONSUMERS, who do not receive this file — it is correct and irrelevant, since
# this CLAUDE.md exists for people working in the repo, where it does load. There is no
# suppression flag (validate --help offers only --json and --strict), so the check asserts on
# manifest.errors and manifest.warnings directly: strictness on the manifest is preserved,
# and only the one known CLAUDE.md note is tolerated. Verified 2026-09-13, claude 2.1.268.
set -uo pipefail
cd "$(dirname "$0")/.."
fail=0

echo "== 1/4 scrub gate =="
if ./scripts/scrub-gate.sh; then echo "   ok"; else echo "   FAIL"; fail=1; fi

echo "== 2/4 plugin manifest (strict) =="
report=$(claude plugin validate --json .claude-plugin/plugin.json 2>/dev/null) || true
if ! printf '%s' "$report" | jq -e . >/dev/null 2>&1; then
  echo "   FAIL — validate did not return JSON:"; printf '%s\n' "$report"; fail=1
else
  manifest_problems=$(printf '%s' "$report" \
    | jq -r '[.manifest.errors[]?, .manifest.warnings[]?] | length')
  unexpected=$(printf '%s' "$report" | jq -r '
    [ .contents[]?
      | (.errors[]? | "ERROR \(.path // "?"): \(.message)"),
        (.warnings[]?
         | select(.message | test("CLAUDE\\.md at the plugin root") | not)
         | "WARN \(.path // "?"): \(.message)") ] | .[]')
  if [ "$manifest_problems" != "0" ] || [ -n "$unexpected" ]; then
    echo "   FAIL"
    printf '%s' "$report" | jq -r '.manifest.errors[]?, .manifest.warnings[]? | "   manifest: \(.message)"'
    [ -n "$unexpected" ] && printf '   %s\n' "$unexpected"
    fail=1
  else
    echo "   ok (manifest clean; the known root-CLAUDE.md note is expected)"
  fi
fi

echo "== 3/4 marketplace manifest (strict) =="
if claude plugin validate --strict .claude-plugin/marketplace.json >/dev/null 2>&1; then echo "   ok"
else echo "   FAIL"; claude plugin validate --strict .claude-plugin/marketplace.json 2>&1 | tail -20; fail=1; fi

echo "== 4/4 components (strict) =="
if claude plugin validate --strict skills/ >/dev/null 2>&1; then echo "   ok"
else echo "   FAIL"; claude plugin validate --strict skills/ 2>&1 | tail -20; fail=1; fi

echo
[ $fail -eq 0 ] && { echo "preflight: PASS"; exit 0; }
echo "preflight: FAIL"; exit 1
