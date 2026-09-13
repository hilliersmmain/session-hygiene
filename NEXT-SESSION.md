This repo is the `session-hygiene` Claude Code plugin: four skills (take-stock,
prompt-capture, session-wrap, context-cleanup), generalized from a personal skills directory
and published as its own single-plugin marketplace. Read `CLAUDE.md` first — it holds the
pre-push checks and, more importantly, what those checks do *not* catch.

State as of 2026-09-13. `.claude-plugin/plugin.json`
carries `license`, `repository` and keywords; `.claude-plugin/marketplace.json` lists this
directory with `"source": "./"`; README, LICENSE and CLAUDE.md are written;
`scripts/preflight.sh` runs four checks and passes. Two `plugin-dev` review agents were run
and their findings applied — the notable ones: `take-stock`'s `allowed-tools` had forbidden
the very commands its own first step tells it to run, `prompt-capture` contradicted itself
about whether a launch command belongs in an emitted prompt file, and `context-cleanup`
hardcoded a `~/Projects/*` glob that silently returns an empty audit on any machine that
keeps code elsewhere.

One trap is worth carrying forward, because it cost a silent false pass here:
`claude plugin validate <dir>` resolves a directory to exactly one manifest, and which one
depends on what exists. Adding `marketplace.json` made the root check stop looking at
`plugin.json` without any edit to the check and without changing its green output. Both
manifest checks now name their file explicitly. Do not point a manifest check at a directory.

Left to do, in this order:

1. Name the cost first (about $2 to $4, 5 to 10 minutes, four `claude -p` runs on sonnet),
   then `evals/run-manual.sh take-stock-zero-milestone` and
   `evals/run-manual.sh prompt-capture-gate`. Grade both replies against each case's
   `graders/` by hand. `claude plugin eval` is early access and enabled per organization; it
   was gated off for this account. Do not try to enable it or guess at enablement variables.
   Two grader shapes (`target: { source: file, path: ... }` and `scaffold_script` as a path)
   follow the embedded reference and are still unverified against the real runner.
2. Fill the README's empty "Results" section. Summarize; never paste reply text, which quotes
   scaffold paths.
3. In a fresh session, confirm the skills load as `session-hygiene:<skill>`. Already
   answered for the inventory: `disable-model-invocation: true` does **not** hide
   `session-wrap` from `plugin details`, and it still costs its ~60 always-on tokens. What
   remains is whether it is absent from the model's own runtime skill list, which is the
   thing the field actually suppresses.
4. Run the original `session-wrap` while it still exists, then retire the four originals from
   the personal skills directory to a dated backup directory. Copy
   `skills/context-cleanup/reference/settings-keys.md` across first. `ls` both directories
   afterwards as the check — `mv` into an existing directory is one of the commands that
   succeeds while doing the wrong thing.
5. Add the repo URL to the portfolio roadmap in the companion repo, as a dated append; the
   earlier "not yet published" line is history and stays.
6. Open question, not yet investigated: the `remember` plugin writes a `.remember/` store
   from a SessionStart hook. Does it replace, duplicate, or complement `session-wrap`?

Every review finding, applied and deferred, is logged at
`~/.claude/plans/2026-09-13-session-hygiene-review-findings.md` — read it before touching a
skill, so a deferred item is not rediscovered as if new. The highest-value deferred one is
measured: `prompt-capture`'s description alone is ~180 of the plugin's ~392 always-on tokens.
