---
name: context-cleanup
description: Use when the user asks to cut startup context, says /context is too high, runs a periodic cleanup, or asks whether CLAUDE.md has drifted.
context: fork
agent: general-purpose
background: false
---

# Context cleanup

Reduce what every new session loads before a word is typed. Run this periodically, or
whenever a session's startup context feels heavy — on the order of tens of thousands of
tokens for a plain "hi".

**Never propose a saving you have not measured.** That rule is the whole point of this
skill — every plausible-sounding lever below was tested, and one of the most promising
(`disabledBuiltinTools`) turned out to do nothing at all.

## Step 1 — Measure

### 1a. The real number: an interactive session's transcript

**`claude -p` does not measure what a session costs.** Print mode ships a smaller tool set
and no skills listing, and reads meaningfully lower than a real interactive first turn from
the same directory — a gap of several thousand to tens of thousands of tokens. Every `-p`
figure in `reference/settings-keys.md` is a *customization delta*, never a total.

Ground truth is the API's own accounting, recorded in the session transcript:

```bash
first_turn(){ grep '"type":"assistant"' "$1" | head -1 \
  | jq -r '.message.usage | (.input_tokens + .cache_read_input_tokens + .cache_creation_input_tokens)'; }

# Session transcripts live under ~/.claude/projects/<slug>/*.jsonl, where <slug> is the
# measured directory's absolute path with every / replaced by - (so ~/Projects/foo for
# user alice becomes -home-alice-Projects-foo). Derive it from pwd — don't hardcode it:
slug=$(pwd | tr '/' '-')
first_turn "$(ls -t ~/.claude/projects/"$slug"/*.jsonl | head -1)"
```

Start a fresh session in the directory being measured, type one word, then read *that*
transcript. Anything pasted before the first assistant turn is counted in it, so measure
from a clean start or subtract what you pasted.

`/context` estimates the same quantity but is not exact: it prints before the turn is
assembled, so it misses the messages and any mode preamble that follow it. Since this skill
runs without an interactive session, it cannot run `/context` itself — ask the user to run
`/context all` in an interactive session as an optional cross-check; this skill runs without
it.

**`/context` totals are per-model and are NOT comparable across a model change.** Switching
the model shifts the system-prompt and system-tools accounting on its own, independent of
any real config change, so most of an apparent gap between two `/context` readings can come
from the model rather than from a setting. This is the same trap this section already
records for `-p` (a parallel session flipping the default model can move a reading by
several thousand tokens). If the user reports numbers from more than one `/context` run,
ask what model header each one carried before comparing them — readings under different
models are not comparable.

The spread across sessions is wide, driven by directory, model, and what was pasted in.
**There is no single startup number; measure per directory.**

### 1b. A/B deltas: `claude -p`, with a control

`-p` is still the right tool for "does this key do anything?" — both arms carry the same
blind spot, so it cancels out of a difference.

```bash
m(){ timeout 180 claude -p --output-format json --no-session-persistence \
       --model <fixed-model> --max-turns 1 "$@" 'hi' 2>/dev/null < /dev/null \
     | jq -r '"\((.usage.input_tokens)+(.usage.cache_creation_input_tokens)+(.usage.cache_read_input_tokens)) turns=\(.num_turns)"'; }

for d in ~ ~/Projects/<one-representative-project>; do   # measure from BOTH: a project session is the number that matters
  cd "$d"; echo "$d: safe=$(m --safe-mode) default=$(m)"; done
```

Pass `--model` explicitly everywhere `<fixed-model>` appears above — any fixed model works,
but it must be the same one on every measurement, or the comparison is meaningless.

`~` loads its own memory store; a project loads the global `CLAUDE.md` plus its own file.
Report both. Pick a project whose `CLAUDE.md` is representative of what the user actually
carries: a large project file costs meaningfully more tokens than a near-empty one, so an
almost-blank project is a floor, not a typical case — swap in one of the user's real
projects.

**Track `DEF - SAFE`, not `DEF`, and re-measure `SAFE` for every directory, every time.**
The control is not a constant. It can shift on an unchanged binary for no identified
reason, and it can differ between directories on the same day. Never compare today's `DEF`
against a `DEF` from another day, and never subtract one directory's control from another
directory's `DEF`.

Three traps, all hit for real:

- **`.usage` in the result JSON is summed over every API turn.** Without `--max-turns 1`, a
  project whose CLAUDE.md nudges the model into a tool call on "hi" reads roughly double for
  the same directory. Keep `--max-turns 1` and print `num_turns`.
- **Always pass `--model`.** Without it, `-p` uses whatever the current default is. A
  parallel session switching the default model can move the reading by several thousand
  tokens and make a genuine saving look like a regression.
- **Reproducible ≠ correct.** Identical readings in a row can still measure the wrong thing.
  If a number moves the wrong way, re-measure `--safe-mode` first — if the control moved
  too, the cause is environmental, not your edit.

## Step 2 — Inventory

Ask the user to run `/context all` in an interactive session as an optional cross-check and
report the six category numbers; this skill runs without it. Then:

```bash
jq -r '.enabledPlugins | to_entries[] | "\(.value)\t\(.key)"' ~/.claude/settings.json
wc -c ~/.claude/CLAUDE.md <memory-store-path>/MEMORY.md
ls -la ~/.claude/skills/
find ~ -name CLAUDE.md -not -path '*/plugins/*' -not -path '*/node_modules/*' 2>/dev/null
```

`<memory-store-path>` is the per-directory memory path for the directory being measured —
the same directory whose `pwd`-derived `<slug>` Step 1a uses for the transcript path.

## Step 3 — Audit, highest measured yield first

1. **The CLAUDE.md files — not against a fixed byte ceiling.** If the user's own CLAUDE.md
   sets recommended lengths for its files, read them from there rather than assuming a number;
   crossing one means *schedule a review*, not *demote or refuse*. What replaces a hard
   ceiling is **Step 6, the drift audit** — run that. If a file is genuinely sprawling,
   demote stories to a reference directory, don't squeeze.
   `find ~ -name CLAUDE.md -not -path '*/plugins/*' -not -path '*/node_modules/*' 2>/dev/null | while read -r f; do printf '%4d %s\n' "$(wc -l <"$f")" "$f"; done`
   (Not a `~/Projects/*` glob — projects live under different roots on different machines, and
   a glob that matches nothing returns a clean-looking but empty audit.)
2. **Memory store** — the index file loads every session; the individual memory bodies do
   not, so tighten the index first. If the user's CLAUDE.md sets a recommended length for it,
   read that from there too. **The honest caveat, kept because it argues against the
   current instrument:** a line count is a poor proxy for cost — a short index can still be
   heavy if individual entries have grown long, and raw bytes track cost better than lines
   do. Lines win as the metric anyway, because for files this size the raw token cost is a
   rounding error against the context window; what actually degrades in a long instruction
   file is instruction-following, and length proxies that better than weight. If the user
   ever runs a much smaller context window, that reasoning flips and bytes matter again.
3. **Plugins** — disabling unused plugins was measured as the single biggest lever, once.
   **It may not be any more**: if that pruning already happened and the survivors are in
   active use, there is nothing left to take. Check what is actually enabled before
   assuming otherwise.
4. **Skill frontmatter** — every skill's `description` loads in every session forever. A
   verbose one costs more than a small plugin.
5. **MCP servers** — prefer a CLI tool plus a thin skill wrapping it, where one exists.

A/B any candidate without touching real config:

```bash
m --settings '{"enabledPlugins":{"some-plugin@marketplace":false}}'
```

## Step 4 — Propose

This skill does not touch config itself. It outputs the proposed change as a diff plus the
exact commands to apply it, and the user runs them:

- Back up first: `mkdir -p ~/.claude/backups && cp ~/.claude/settings.json ~/.claude/backups/settings.json.bak-$(date +%F)`
  (`cp` does not create the parent directory, and fails outright if it is missing.)
- Edit with `jq` into a temp file, then `mv` into place, so a failure can't truncate the
  file.
- **Propose a diff and get approval before touching CLAUDE.md** — treat it as append-only
  by default, and a restructure as a deliberate, separately-approved exception.
- **Split, never delete.** Move detail to a reference directory and leave a pointer line.
  Verify nothing was lost by grepping distinctive terms across the new file and the
  reference directory before reporting done.

## Step 5 — Re-measure and report

Report **actual vs. predicted** for each change. If a lever underdelivers, say so and
record that where the user's own notes live, not in `reference/settings-keys.md` — that file
ships inside the plugin, so it is read-only in a normal install and is overwritten on the next
update. A lever measured as useless must not be proposed again next time, which means writing
it somewhere that survives.

## Step 6 — Drift audit: are the always-loaded files still *true*?

Size was never the binding constraint here; staleness is. Don't gate these files on a byte
ceiling — a claim can go stale within hours of being written, regardless of how short the
file holding it is; this audit is the check for that. Run this occasionally — monthly, or
whenever a file crosses a recommended length the user has set for it — not every session.

**The audit re-derives its own checks. There is no manifest.** A second file listing what
to verify would itself drift, with nothing checking *it*. Instead, read the target file and
pull out every claim matching one of these shapes, because those are the ones with a
mechanical proving command:

| Claim shape | Proving command |
|---|---|
| a path or file exists | `ls -la` on it |
| a tool is installed | `type -t`, `dpkg-query -W` — **never `command -v`**, false positives in this tool |
| a settings key holds a value | a fresh `Read` of the JSON (not a cached one, not a backup) — **confirm before flagging the model-selection keys: many people change them by hand between sessions, so ask rather than assuming intent or rot** |
| a service or unit state | `systemctl --user status`, `flatpak override --show` |
| a directory convention holds | glob the projects and report the **hit rate**, not a yes/no |
| a hardware or firmware fact | the `/sys/class/dmi/id/*`, `lsblk`, `lspci` reading |
| an alias or shell function | `type -t` after sourcing, or grep the rc file — PATH lookups miss aliases |

Everything else — judgement, preference, a rule about how to work — is not mechanically
checkable. Don't guess at it; list it as **unchecked** so the count is honest.

**Output:** a PASS / FAIL / UNVERIFIABLE table, with the literal command output for every
FAIL and a proposed correction diff for the user to approve. `sudo`-gated claims (a
firewall rule, a hardware serial number) are **UNVERIFIABLE, never PASS** — the Bash tool
has no TTY.

**This skill already runs in its own context.** Run the proving commands directly, and fan
out to further subagents (model passed explicitly) only if the file is very long — it is
otherwise a wide fan-out of cheap independent commands. Return the PASS / FAIL /
UNVERIFIABLE table as this skill's result; the invoking session reads the table, not the
work.

**Then correct in the right direction.** A CLAUDE.md line and a memory note can disagree,
and the one that reads as authoritative is not always the one that's actually current —
prove which side is wrong with a live command before editing either.

## Verified levers

Full detail, including what does *not* work, in `reference/settings-keys.md`.
