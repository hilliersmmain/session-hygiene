# session-hygiene

A Claude Code plugin: four skills for keeping a long session honest about its own state.

Long sessions drift. The model reports progress it inferred rather than checked, chases
prerequisites that belong in another session, and loses the thread across a compaction.
These skills each interrupt one of those failure modes with a procedure that has to touch
evidence before it can produce an answer.

## The skills

| Skill | Fires when | What it does |
|---|---|---|
| `take-stock` | "what's left", "where are we", resuming after a break or a compaction | Rebuilds the project's state from git log, the filesystem and the tests — not from the conversation's own claims |
| `prompt-capture` | a detour surfaces: installing a tool, adding a repo, wiring auth, a systemd unit | Parks it as a standalone prompt file instead of doing it now; verifies every load-bearing fact first and refuses to emit a prompt built on guesses |
| `session-wrap` | "wrap up", "update CLAUDE.md from this session" | Sorts what was learned into the right instruction file, one line per durable rule, with the story going elsewhere |
| `context-cleanup` | `/context` is too high, or a periodic audit of what loads at startup | Audits always-on context and re-verifies the claims in `CLAUDE.md` against the machine |

Each carries one piece of skill frontmatter deliberately: `allowed-tools` (take-stock),
`argument-hint` (prompt-capture), `disable-model-invocation` (session-wrap), and
`context: fork` with `agent` and `background` (context-cleanup).

## Install

```
/plugin marketplace add hilliersmmain/session-hygiene
/plugin install session-hygiene@session-hygiene
```

The repo is its own marketplace — `.claude-plugin/marketplace.json` lists this directory as
the single plugin source, so there is nothing else to add.

Verify:

```bash
claude plugin list
claude plugin details session-hygiene   # inventory and projected always-on token cost
```

## Origin, and what that means for you

These started as personal skills in a single `~/.claude/skills/` directory and were
generalized for publication: every machine-specific path, hostname, hardware detail,
security-posture note and personal reference was stripped, and the repo carries a grep gate
(`scripts/scrub-gate.sh`) that fails before a push if any of it comes back. What remains is the
procedure, not the setup it grew up in.

Consequence worth naming: the skills still assume some conventions they were written
against. They work without them, but they are most useful if you already work this way, or
are willing to.

- A project keeps a `CLAUDE.md`, and `~/.claude/CLAUDE.md` holds machine-level rules.
- `prompt-capture` has somewhere to write — `prompts/` in-repo, or a prompts directory at
  `$HOME` (it defaults to `~/Prompts/` when your `CLAUDE.md` does not name one).
- `session-wrap` writes its findings file to `~/.claude/plans/`, and creates it if absent.
- The verification idioms are Linux-flavoured: `dpkg-query`, `flatpak`, `systemctl --user`,
  `/sys/class/dmi`. The reasoning transfers; the exact commands are Debian/Ubuntu.

## Evals

Two cases live under `evals/`, in the layout `claude plugin eval` expects:

```bash
evals/run-manual.sh take-stock-zero-milestone
evals/run-manual.sh prompt-capture-gate
```

- `take-stock-zero-milestone` — a repo with commits but no finished milestone, asked "where
  are we?". Checks that the answer is built from a check that was actually run, not from the
  prompt's framing.
- `prompt-capture-gate` — a session that surfaces a machine-wide prerequisite mid-task.
  Checks that it is parked as a prompt file, that the verification gate is printed, and that
  the prompt file contains no deferral language.

**Why a hand-rolled runner.** `claude plugin eval` is in early access and is enabled per
organization; it was gated off for the account these cases were written on, printing
"currently in early access" and exiting 1. `evals/run-manual.sh` is the stand-in: for one
case it builds the scenario from `scaffold.sh` in a throwaway workspace, then runs the prompt
twice — once with `--plugin-dir` and once without — each in a fresh `CLAUDE_CONFIG_DIR` so no
local `CLAUDE.md`, skill or memory loads in either arm. It writes both transcripts under
`evals/results/` (gitignored) and prints turns, cost and skill calls per arm. Grading is by
reading the two replies against the case's `graders/` rubrics.

**Unverified against the real runner.** Two grader shapes follow the CLI's embedded reference
but have never been executed by `claude plugin eval` itself, because it could not be run:
`target: { source: file, path: ... }` for grading a file the run produced, and
`scaffold_script` as a path in `case.yaml`. Treat both as best-effort until someone with
early access confirms them.

### Results

Not yet run. The A/B comparison is the next thing this repo needs; this section will carry
the per-case summary once it exists.

## License

MIT — see `LICENSE`.
