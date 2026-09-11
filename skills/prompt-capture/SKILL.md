---
name: prompt-capture
description: Use when work surfaces a prerequisite that lives outside the current repo — installing a tool, adding a vendor apt repo, wiring up auth, a systemd unit, a DNS/firewall change, anything machine-wide — and especially when the assistant is about to say "first we need to install X", "that needs sudo, so let's set it up", or "quick detour". Also use when the user says "write that up as a prompt", "add it to the prompts directory", "park that for later", or "don't go down that rabbit hole".
argument-hint: "<topic>"
---

# prompt-capture

A project session notices something has to be set up **outside** the repo. Doing it now costs
the session: it needs `sudo` the user has to type, a decision the user has to make, or an hour
that belongs to the project. Writing "TODO: install X" instead loses everything this session
already knows.

This skill takes the third path — turn what this session has **already proven** into a
self-contained prompt file, then get back to work. The user runs it later, so the current
session stays on task and the deferred work can run whenever there's spare time or usage room.

## Why the verifying matters more than the writing

The prompt files that worked did one non-obvious thing: they reached the future session
carrying facts already checked, not questions. The difference is between

> `gnome-keyring` and `libsecret-tools` are already installed.

and

> Investigate the auth setup.

The first spends this session's context to save the future session's. The second **defers**
the work — the future session opens the file knowing exactly what a sticky note would have
told it, except now it must also rediscover what this session had in context and threw away.

So the order is **verify, then write**, and the gate in Step 3 enforces it. A prompt whose
load-bearing claims were never checked is worse than no prompt, because it looks like
preparation.

## Step 0 — Should this be a prompt file at all?

Three findings mean **don't write one**. Say which, and drop it:

- **An existing plan already owns it.** Check the target repo's `NEXT-SESSION.md`, `docs/`,
  and `~/.claude/plans/` before writing. A prompt file that duplicates a milestone already
  scoped in a repo is two sources of truth for one job. If the job genuinely has a
  machine-level slice that the repo plan does not cover, narrow the prompt to that slice and
  say so in its first paragraph — don't quietly restate the whole milestone.
- **It isn't actually out-of-repo.** Work that touches only files in the current project is
  project work, however tedious. This skill is for things that live on the machine.
- **It's a one-liner with no decision in it.** If the whole job is a command the user can
  paste in ten seconds, hand them the command. A prompt file is for jobs with steps,
  trade-offs, or a decision the user has to make.

## Step 1 — Route it: machine, or project?

| The job belongs to | Write to | Because |
|---|---|---|
| the machine — a tool, a daemon, auth, anything system-wide | `~/Prompts/<topic>.md` | it is run from a `$HOME` session that assumes no repo |
| this project, but a future session — a migration, a data pull, a rework | `<repo>/prompts/<topic>.md` | it needs the repo's CLAUDE.md, git history and tree |

Ask the one question if it is genuinely ambiguous; otherwise route it and say which you chose.
Creating `prompts/` in a repo is fine, and everything in a project directory is
version-controlled without asking.

**Naming:** kebab-case `<topic>.md`, one runnable job per file. Observed house pattern is a
noun phrase or noun-verb naming the *outcome*, no dates and no numbers:
`vendor-repo-setup`, `keyring-auth`, `startup-mount`, `split-oversized-skill`.

## Step 2 — Build the fact table

Before writing a word of prompt, list every claim the future session would **act on** — a
path it will open, a command it will run, a package state it will rely on, a decision already
made. Not background colour; load-bearing claims only.

Tag each one. **These tags stay in this table and never appear in the emitted file** — no
exemplar carries them, and the exemplars are the spec.

| Tag | Means | How it reaches the file |
|---|---|---|
| `[verified-here]` | you ran a command this session and read its literal output | stated flat and unhedged |
| `[cited]` | it comes from a doc, research file or URL you read, not a command you ran | stated flat, naming its source and date so it can be re-checked |
| `[unverifiable]` | needs `sudo`, needs the network, or needs the user — you cannot close it | **must become an instruction** (Step 3) |

Three states, not two: much of what you know is `[cited]` rather than first-hand, and a
two-state gate would either block every emit or launder citations as things you proved.

Verify with the tools that don't lie here: `type -t` and `dpkg-query -W`, never `command -v`;
`command grep` for the real GNU grep; `wc -c`/`wc -l` for sizes; `ls -la` for paths;
`systemctl --user is-active`/`is-enabled` for units. Read the result back — an exit code is
not the check.

## Step 3 — The gate: count the table, then decide

Print the count. A number is a gate; a sentence about being careful is advice.

```
prompt-capture gate — <topic>.md
  N load-bearing claims: X [verified-here], Y [cited], Z [unverifiable]
  Z unverifiable → each must become an explicit instruction before emit
  EMIT CLEARED  |  EMIT BLOCKED
```

`Z` is not a failure — it is the normal state, because `sudo` cannot authenticate from the
Bash tool and the user's intent is never a command's output. The gate is blocked only while an
unverifiable claim is still sitting in the file **as if it were a fact**. Convert each one
and the gate clears:

- needs `sudo` → an instruction to run it, inside the single batched paste block
- needs the user's intent → "re-confirm they still want X rather than assuming"
- may have drifted → "re-verify X before building on it; parallel sessions write here"

Never report a claim that needs `sudo` as passing. That is the same rule
`session-hygiene:session-wrap`'s drift check runs on, and it is the property worth copying —
not a printed budget.

## Step 4 — Write it

**Inline or delegated is the orchestrator's call, per session** — never pinned here, the same
way `session-hygiene:session-wrap` refuses to pin a model. Write it inline when your context is
roomy and the current task is not demanding. Delegate when the session is deep in hard work
and you'd rather not spend the context, or when the fact table is long.

If you delegate: pass the model explicitly on the Agent call; never pin one in a skill — an
omitted model otherwise inherits the main model.

Either way, one property has to hold, and it is the reason delegation was ever worth it:

> **The writing step consumes the fact table and nothing else.**

A writer given only the table *cannot* write "investigate X" — it has no other context to
defer to, and it cannot smuggle in an assumption the orchestrator never checked. Writing
inline is fine, but you have to hold yourself to the same line: write from the table, not
from memory of the conversation.

### Two modes in the emitted text, and only two

- **A verified fact, stated flat.** "`gnome-keyring` and `libsecret-tools` are already
  installed." No hedging, no "should be", no "I believe".
- **An explicit instruction for anything that could not be closed.** "Re-confirm they still
  want it rather than assuming." "Re-verify both before acting, since they may have drifted."

Nothing else. Ban from the emitted file: "investigate", "figure out", "look into", "TBD",
"research whether", "determine if". Each one hands the future session a question this session
was better placed to answer.

### The shape, as the exemplars set it

Read a recent file from the prompts directory the user's CLAUDE.md names (default
`~/Prompts/`) or its archive before writing, if one exists; if none exists, follow the shape
below. The shape:

1. **Opening frame.** Where the session runs (`$HOME` vs the repo). If the job reopens
   something previously deferred or overlaps a plan, say so in the first paragraph and tell
   the session **not to treat the prompt's own existence as the user's confirmation**.
2. **The job**, in a paragraph — and *why*, including the user's reasoning where you know it,
   so the session isn't following orders blind.
3. **"Established facts — use these, don't rediscover them."** The table's contents as flat
   prose. Where drift is plausible, add the instruction to re-verify.
4. **The work**, numbered, when there's a sequence.
5. **What to settle with the user** — a recommendation each with its trade-off named, never a
   bare menu.
6. **House rules that actually bite this job.** The `sudo`-has-no-TTY batched paste block;
   never `curl | sudo bash`; back up before rewriting; `type -t` not `command -v`; let the
   user type the steps that are theirs to learn. Only the ones that apply — a job with no
   privileged step says so instead of carrying a paste-block rule it doesn't need.
7. **The close.** Run `session-hygiene:session-wrap`, then a paste-ready line saying how to
   resume: the literal launch command and which file to paste next.

**Prompt text only.** No launch command, no model line, no status table, no commentary before
or after — the user select-alls and pastes the whole file. Context for *them* goes in your
reply, never in the file.

## Step 5 — Read the emitted file back

Writing it is not evidence it is right. Re-read the file from disk and check:

- no tag leaked through, and no banned deferral word survived. One command reports both,
  and prints nothing when the file is clean:

  ```bash
  command grep -nEi 'verified-here|\[cited\]|unverifiable|investigate|figure out|look into|TBD|research whether|determine if' <file>
  ```

- every `[unverifiable]` row from the table appears in the file as an instruction
- it opens as a prompt, not as a note about a prompt
- nothing about the model is quoted anywhere except the closing line

Then tell the user it exists, in one line, and return to the task that was interrupted. Going
back to the original work is the whole point — the file is a side effect, not a new project.

## Lifecycle: write → run → archive

- **Write**: `~/Prompts/<topic>.md` or `<repo>/prompts/<topic>.md`.
- **Run**: the user pastes it into a fresh session, whenever suits them.
- **Archive**: once the job is genuinely done, `git mv`/`mv` it to an `archived/` subdirectory
  of the prompts directory (`~/Prompts/archived/` or `<repo>/prompts/archived/`). A session
  that *completes* one of these jobs archives the file as part of finishing, so the directory
  stays a to-do list rather than a pile. Don't delete it — the archived files are the working
  spec for this skill.

There is deliberately no index. A status table in `~/Prompts/` would go stale the first time a
job ran; the files are the state.

## What NOT to do

- **Don't write one to look productive.** Step 0 refusing the job is a good outcome, and
  saying "this is already milestone 1 of that repo's plan" is worth more than a file.
- **Don't emit an unverified prompt because time is short.** That is precisely the case the
  gate exists for — the rushed prompt is the one that arrives as a sticky note.
- **Don't turn the detour into the session.** Verifying facts you already gathered is
  minutes. If closing the table means real investigation, that *is* the job — write what you
  have, mark the rest as instructions, and let the future session do it.
- **Don't append to any CLAUDE.md as part of this.** Every line there is a standing
  instruction to every future session; those edits are human-gated and separate.
