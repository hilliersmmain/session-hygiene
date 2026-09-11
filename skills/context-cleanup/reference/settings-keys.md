# Claude Code settings keys affecting startup context

Verified by measurement, not by reading docs. Re-check after a major version bump.

## Works

| Key | Type | Verdict |
|---|---|---|
| `enabledPlugins` | map of `"plugin@marketplace": bool` | Disabling unused plugins measurably cuts startup tokens. |
| `disableBundledSkills` | bool (env: `CLAUDE_CODE_DISABLE_BUNDLED_SKILLS`) | Measurably cuts startup tokens by disabling all built-in skills. |

Trimming a CLAUDE.md file measurably cuts startup tokens, roughly in proportion to the
bytes removed — useful for estimating a saving, never for reporting an exact one.

## Does NOT work — do not propose these again

| Key / flag | Why not |
|---|---|
| `disabledBuiltinTools` | Real key, accepted without error, measured **zero** effect. Tool schemas stay in the prompt regardless. |
| `--tools` | CLI-only, no settings equivalent, so it cannot be made persistent. Also variadic — it swallows the prompt argument unless the prompt comes via stdin. |

**Built-in tool schemas are not reducible.** They are consistently the single largest
category in `/context`, and there is no supported way to shrink that category.

## Measurement cautions

- **Every `-p` figure here is a delta, never a total.** `claude -p` totals are not
  interactive-session totals; only the *difference* between two `-p` runs under the same
  conditions is meaningful. See `SKILL.md` Step 1a before quoting one as a session cost.
- **Always pass `--max-turns 1` and print `num_turns`.** The result JSON's `.usage` is
  summed over every API turn; without the cap, a CLAUDE.md that nudges the model into a
  tool call on a one-word prompt reads roughly double for the same directory.
- **Always pass `--model` explicitly — a fixed model, the same one on every measurement.**
  Without it, `-p` uses whatever the current default is, and a parallel session changing
  that default can make a genuine saving look like a regression, or the reverse.
- **Re-measure the `--safe-mode` control every time, per directory.** It is not a constant
  — it can shift on an unchanged binary for no identified reason, and it can differ between
  directories on the same day. Track `DEF - SAFE`, never `DEF` alone, and never subtract
  one directory's control from another directory's `DEF`. If a number moves the wrong way,
  re-measure the control first — if it moved too, the cause is environmental, not the edit
  under test.
