---
name: take-stock
description: Use when the user asks "what's left", "where are we", "what have we actually got", or wants to regroup, pause, or resume after a break — even offhand, or after a context compaction, since a sense of what is done is the thing that drifts.
allowed-tools: Read, Glob, Grep, Bash(git log:*), Bash(git status:*), Bash(find:*), Bash(wc:*), Bash(ls:*)
---

# Take stock

Reconstruct the true state of the work, from evidence, and report it plainly.

## Why this exists

Deciding something and building it leave almost identical traces in a
conversation. Both produce long discussion, weighed trade-offs, a confident
resolution, a sense of closure. Read back later, *"we settled that VTE is the
right terminal widget"* and *"the terminal pane works"* are nearly
indistinguishable — one is a sentence in a document, the other is code.

So a long session is the least reliable narrator of its own progress, and it is
the source you will reach for first if you are not deliberate. This gets sharply
worse after a compaction, because a summary has already done the flattening for
you: it records that a topic was resolved, not whether anything was built.

The discipline is one sentence:

> **Derive status from artifacts. Treat the conversation as a list of claims to
> go verify.**

Everything below is that sentence, made operational.

## Step 1 — Find the one command

The highest-value check, and the one to run first:

> **What is the single command that would fail if this weren't actually built?**

Instantiate it for the project in front of you:

| Project shape | The command |
|---|---|
| Python package or app | `python3 -m <pkg>`, or the console entry point |
| CLI tool | run it with `--help` or its most basic subcommand |
| Web service | start it, `curl` the health route |
| Library | import it and call the headline function |
| Config / docs work | `cat` the file and look for the thing that should be in it |
| Infra | the read-only status or plan command |

Run it. **Paste the real output, including the failure.** A raw
`No module named perch` is a more honest status line than any prose summary you
could write, and it costs one second. If you cannot find such a command, that is
itself a finding worth reporting — it usually means nothing runnable exists yet.

Then run the tests, and ask the sharper question: do they cover the thing whose
status is in doubt, or only the scaffolding around it? A green suite proves the
tests pass, not that the feature exists.

## Step 2 — Measure what exists

Cheap, factual, hard to argue with:

```bash
git log --oneline -15
git status --short --branch          # dirty? unpushed? both are status
find <src> -name '*.py' -exec wc -l {} +   # or the language's equivalent
```

Line counts are crude but they puncture inflated impressions fast. A package
whose entire contents are docstrings and `__init__.py` files is at zero, however
much was discussed. Separate *application* code from tests, scaffolding, spikes
and generators — it is common and easy to miss that all the code written so far
sits around the thing rather than being it.

If there is a plan or design doc, read it now and diff its milestones against
what you just measured. Do not trust its own checkboxes.

## Step 3 — Re-check earlier handoffs

Anything a previous session handed the user to do — a command to run, a file to
check, a confirmation to give back — **is unverified until you check it now.**

This step reliably produces the most valuable findings, for a structural reason:
these items are invisible to git, no tool tracks them, and the session that
created them ended before they could be confirmed. Expect a meaningful fraction
of them to have quietly not happened.

Check each one directly rather than asking. `ls` the path, re-run the verify
command, read the file. Then report which held and which did not.

## Step 4 — Sort into three buckets

The sorting *is* the deliverable. Keep the buckets separate even when it makes
the picture look thinner than it felt:

1. **Built and verified** — with the evidence beside it. Naming the evidence is
   what makes this bucket trustworthy; a claim with no check next to it belongs
   in bucket 3.
2. **Decided, not built** — settled designs, chosen stacks, resolved trade-offs.
   This is genuine work product and should be credited as such, but it is not
   code and must never be listed as though it were.
3. **Open** — split into *remaining work* and *open loops*, where an open loop
   is anything handed to the user, or to a future session, that was never
   confirmed done. Include non-code loops: an unapplied recommendation, an
   untested config change, a cleanup command never run.

## Reporting

Lead with the blunt version. If a milestone is at zero, say zero and show the
command that proves it — the user asked precisely because their impression had
drifted, so softening it defeats the purpose. Being encouraging about a state
they will discover for themselves in ten minutes costs you their trust.

A workable shape, adapted to the situation rather than followed rigidly:

```
## What's actually finished     (table: claim | evidence)
## What's left                  (lead with the blunt headline + the command output)
## Open loops                   (things handed over and never confirmed)
## The next decision            (one line — what the break should end with)
```

Two habits that keep this useful:

- **Distinguish project work from side-quest housekeeping.** Long sessions
  accumulate renames, config fixes and cleanups that feel like progress and are
  not progress on the actual goal. Both are worth listing; conflating them is
  how a session ends up feeling productive while the milestone sits at zero.
- **Never report a status you did not verify in this pass.** Write "unverified"
  and move on. Inherited confidence is the exact failure the skill exists to
  prevent, and re-asserting it under a heading called *verified* makes things
  worse than saying nothing.

Close by naming the next decision — not a re-plan, just the one choice the user
faces coming out of the break. If a prerequisite that was blocking work has
since been cleared, say so explicitly; that fact is easy to lose in a long
session and it is often the whole reason the next step is now unblocked.

## Not this skill

`session-hygiene:session-wrap` answers *"what from this session should persist into CLAUDE.md or
memory?"* and runs at the end. This one answers *"where does the work actually
stand right now?"* and runs mid-flight, when the user has lost the thread and
work is about to continue. If the user wants durable rules captured rather than
an orientation, use that skill instead.

Do not use this to re-plan, re-litigate settled decisions, or restart
brainstorming. It is a report on reality, and it ends with the user knowing what
is true — not with a new plan.
