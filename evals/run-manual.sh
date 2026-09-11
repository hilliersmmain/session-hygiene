#!/usr/bin/env bash
# Manual stand-in for `claude plugin eval`, which is early access and enabled per organization.
#
# For one case under evals/: build its scenario from scaffold.sh in a throwaway workspace, then
# run the prompt once WITH the plugin (--plugin-dir) and once WITHOUT, each in a fresh
# CLAUDE_CONFIG_DIR so none of the operator's own CLAUDE.md, skills or memory load in either
# arm. A fresh config dir has no login, so the credentials file is copied in for the run and
# deleted afterwards, which is what the official runner does too. Grading is by reading the
# two replies and traces it leaves under evals/results/ against the case's graders/ rubrics.
#
# usage: evals/run-manual.sh <case-dir-name> [model]        model defaults to sonnet
set -euo pipefail

PLUGIN=$(cd "$(dirname "$0")/.." && pwd)
CASE=${1:?usage: run-manual.sh <case-dir-name> [model]}
MODEL=${2:-sonnet}
CASE_DIR=$PLUGIN/evals/$CASE
[ -f "$CASE_DIR/prompt.md" ] || { echo "no prompt.md in $CASE_DIR" >&2; exit 2; }
CREDS=${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.credentials.json
[ -f "$CREDS" ] || { echo "no credentials file at $CREDS; log in to claude first" >&2; exit 2; }

OUT=$PLUGIN/evals/results/manual-$(date +%Y%m%d-%H%M%S)-$CASE
mkdir -p "$OUT"

# prompt.md is YAML frontmatter between the first two '---' lines, then the prompt body.
PROMPT=$(awk 'c>=2{print} /^---$/{c++}' "$CASE_DIR/prompt.md")
MAX_TURNS=$(sed -n 's/^max_turns: *//p' "$CASE_DIR/prompt.md"); MAX_TURNS=${MAX_TURNS:-10}
mapfile -t TOOLS < <(sed -n 's/^allowed_tools: *\[\(.*\)\] *$/\1/p' "$CASE_DIR/prompt.md" \
  | tr ',' '\n' | sed 's/^[ "'"'"']*//; s/[ "'"'"']*$//' | sed '/^$/d')

SCRATCH=$(mktemp -d "${TMPDIR:-/tmp}/eval-$CASE.XXXXXX"); chmod 700 "$SCRATCH"
trap 'rm -rf "$SCRATCH"' EXIT   # the credentials copies never outlive the script

run_arm() {   # $1 is "with" or "without"
  local arm=$1 ws=$SCRATCH/ws-$1 cfg=$SCRATCH/cfg-$1
  mkdir -p "$ws" "$cfg"; chmod 700 "$cfg"
  cp "$CREDS" "$cfg/.credentials.json"; chmod 600 "$cfg/.credentials.json"
  if [ -f "$CASE_DIR/scaffold.sh" ]; then (cd "$ws" && bash "$CASE_DIR/scaffold.sh"); fi

  local plugin=() allow=()
  [ "$arm" = with ] && plugin=(--plugin-dir "$PLUGIN")
  [ ${#TOOLS[@]} -gt 0 ] && allow=(--allowedTools "${TOOLS[@]}")

  echo "== $arm arm: model=$MODEL max_turns=$MAX_TURNS tools=${TOOLS[*]:-none}"
  ( cd "$ws" && CLAUDE_CONFIG_DIR="$cfg" claude -p --model "$MODEL" --max-turns "$MAX_TURNS" \
      --no-session-persistence --permission-mode dontAsk --output-format stream-json --verbose \
      "${allow[@]}" "${plugin[@]}" "$PROMPT" ) > "$OUT/$arm.jsonl" 2> "$OUT/$arm.stderr" \
    || echo "   claude exited non-zero; see $OUT/$arm.stderr"

  jq -r 'select(.type=="result") | .result // ""' "$OUT/$arm.jsonl" > "$OUT/$arm.reply.md"
  jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use")
         | "\(.name) \(.input|tostring|.[0:100])"' "$OUT/$arm.jsonl" > "$OUT/$arm.trace.txt"
  (cd "$ws" && git status --porcelain 2>/dev/null || true) > "$OUT/$arm.files.txt"
  rm -rf "$ws/.git"; cp -r "$ws" "$OUT/$arm.workspace"
  rm -rf "$cfg" "$ws"

  local turns cost fired
  turns=$(jq -r 'select(.type=="result") | .num_turns' "$OUT/$arm.jsonl" | head -1)
  cost=$(jq -r 'select(.type=="result") | .total_cost_usd' "$OUT/$arm.jsonl" | head -1 | cut -c1-6)
  fired=$(grep -c '^Skill ' "$OUT/$arm.trace.txt" || true)
  echo "   turns=${turns:-?} cost_usd=${cost:-?} skill_calls=${fired:-0} reply=$OUT/$arm.reply.md"
}

echo "case: $CASE"
run_arm with
run_arm without
echo "== done. Grade with.reply.md and without.reply.md against $CASE_DIR/graders/; traces in *.trace.txt"
