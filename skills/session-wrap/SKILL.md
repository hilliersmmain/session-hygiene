---
name: session-wrap
description: Use when the user says "wrap up", "session wrap", or "update CLAUDE.md from this session", or when the session is ending and about to be compacted.
disable-model-invocation: true
---

Manually invoked, never auto-run. **Run it BEFORE compacting.** It reviews the session's
conversation, and compaction destroys the exact wording, corrections and verifications it
needs; after compaction it produces a vaguer, less useful diff.

## Delegation — always dispatch

**Always run this as a subagent, never inline.** Pass the model explicitly on the Agent
call; never pin one in a skill.

This is a split, not a hand-off of the whole skill:

- **The orchestrator does Step 3 itself, before compacting** (the reason this skill runs
  pre-compaction at all) — it reviews its own conversation and writes a findings file, sorted
  by the Step 1 table's targets (global CLAUDE.md items, reference-file stories under a named
  heading, project-file items, memory items), to `~/.claude/plans/`.
- **The subagent has no conversation to review.** It gets that findings file plus the exact
  cwd and the exact memory-store path (never let it guess or derive the path), and runs
  Steps 1, 2, 4, 5, 6 against it: re-read every target from disk, cross-check each proposed
  item against what's actually live (parallel sessions write these files too, and a findings
  file can predate another session's edit), run the drift check, and write a
  `...findings.proposals.md` sibling file. It saves memory items normally (not gated) but
  applies nothing to any CLAUDE.md and does not touch the reference files either — proposals
  only, for the user to approve.

## Step 1 — Where am I, and which files may this session touch?

`pwd`, then use the row that matches. Never hardcode the memory-store path: it is in the
system prompt and is derived from the working directory, so a project session and a
home-directory session have *different* stores.

| Session is in | May propose to | Only for |
|---|---|---|
| a project directory, or any git repo or real source tree | that project's `CLAUDE.md` and that directory's auto-memory store | anything about this project |
| same | the global `~/.claude/CLAUDE.md` | a new fact about the machine or the user (rare) |
| same | a notes or reference directory | only if the user's CLAUDE.md names one |
| `~` | the global `~/.claude/CLAUDE.md`, the `~` memory store | machine and user facts; churn |
| anywhere else (e.g. `/tmp`, a downloads folder, `/etc`) | that directory's memory store; a notes or reference directory if the user's CLAUDE.md names one | — |

A project with real content but no `CLAUDE.md`: offer to create one from a template if the
user's CLAUDE.md names one; never create it silently. `~` is machine administration, not a
code project.

## Step 2 — Re-read every target from disk, in full, right now

Parallel sessions share these paths and have demonstrably written to them mid-session. A
diff built on remembered content silently clobbers someone else's edit. `pgrep -x claude`
(not `-f`, which matches itself) tells you how many sessions are live.

## Step 3 — Review the session for what is durable

- Corrections the user gave about how to work that read as standing rules, not one-off
  preferences.
- Explicit confirmations of a non-obvious approach that worked.
- New facts about the machine, about the user, or about this project, **with how they were
  proven**: the command and the date.
- Traps that cost time.

## Step 4 — Sort, with the story test

For each item ask: **can it be written as an imperative in two lines with no narrative?**

- **Yes**: it is a CLAUDE.md line. It goes to the file the Step 1 table allows, under the
  best existing heading, dated where a date makes it falsifiable.
- **No**: it is a story. It goes to the notes or reference directory the user's CLAUDE.md
  names (appended under a fitting heading), or to the memory store, and the CLAUDE.md gets
  at most a one-line pointer. Stories inside a CLAUDE.md are how a global file can double in
  days.
- In-progress state, open questions, anything still being figured out: memory store only.

## Step 5 — Local drift check, before showing anything

**No byte budget. Do not print one.**

Instead, before appending to a section, **re-verify the claims already in that section that
name a file, command, path or setting.** One or two commands each: `ls -la` a path,
`type -t` or `dpkg-query -W` a tool (never `command -v` — false positives in this tool), a
fresh `Read` of a settings key, `systemctl --user` a unit, a glob for a directory
convention. Propose any failure as a **correction diff alongside the append**, with the
literal command output. A claim needing `sudo` is reported UNVERIFIABLE, never as passing.

This is the local version of the full audit in the `session-hygiene:context-cleanup` skill;
that one sweeps the whole file, this one covers the neighbourhood you are writing into.

If the user's CLAUDE.md sets a recommended length limit, surface a number only when a
proposed append would cross it, and then say so in one sentence as a review prompt, not a
refusal.

## Step 6 — Show diffs; apply nothing to a CLAUDE.md

**Put the proposals where the user will actually read them.** Show the diffs in chat by
default, or open the proposals file the way the user's CLAUDE.md specifies if it names an
editor habit. Pick one way and keep it consistent across sessions.

One visually separate diff per target file, each approved independently. Memory-store items
are saved the normal way and listed. Once approved: **append only**. Rewriting, reordering
or deleting existing lines is a separate ask with its own sign-off. "Nothing for global, two
project lines, one memory" is a good result; never invent an addition to have output.

## Writing rules that stay falsifiable

- **A line states a stable fact or a pointer, never a volatile value.** If a command or a
  parallel session can rewrite it, name the command that reports it and don't quote the
  value. Example of the shape: the kernel line says "check `uname -r`" rather than a version.
- **Never report the model-selection keys in settings.json as drift; the user changes them
  by hand and on purpose.**
- Never write "settled, stop re-checking" into any of these files. A rule that closes a
  question *and* forbids re-checking survives being wrong forever. Write **"verified X on
  DATE — re-check if it matters"**. Both stop the nagging; only one stays falsifiable.
- Record how something was proven, not the conclusion alone. "Port 111 closed" ages badly;
  "`ss -tln` shows only 22, verified DATE" can be re-run.
- No sensitive personal detail (financial specifics, health, journal content) in any of
  these files; they are working-rules files, not a life record.

## What NOT to do

- Don't wire this into a hook that runs unattended. Human-gated by design: every line in
  these files is a standing instruction to every future session, so an unreviewed write is
  a hazard, not untidiness.
- Don't run this inline as the orchestrator past Step 3 — see "Delegation" above: dispatch to
  a subagent, model chosen by the orchestrator.
