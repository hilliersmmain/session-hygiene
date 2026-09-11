This repo is the `session-hygiene` Claude Code plugin: four skills (take-stock, prompt-capture,
session-wrap, context-cleanup) copied from `~/.claude/skills/` and scrubbed of anything
machine-specific or personal, to be published on GitHub as its own marketplace. The full plan,
with the decisions table and research appendix, is
`~/.claude/plans/read-claude-md-first-then-idempotent-tarjan.md`; read it before doing anything.

Already done, verified 2026-09-11: the four skills are in `skills/` with their new frontmatter
fields; `claude plugin validate --strict .` passes; `claude --plugin-dir . plugin details
session-hygiene` lists four skills at about 392 always-on tokens; two eval cases are written
under `evals/` in the runner's layout; `evals/run-manual.sh` is the tested stand-in runner.
`claude plugin eval` itself is early access, enabled per organization, and is gated off for
this account: it prints "currently in early access" and exits 1. Do not try to enable it and
do not guess at enablement variables; the manual runner is the path. Two grader shapes
(`target: { source: file, path: ... }` and `scaffold_script` as a path) follow the embedded
reference but are unverified against the real runner; the README must say so.

Left to do, in this order, Sam doing the doing where it teaches and Claude doing the
mechanical parts when asked: (1) `.claude-plugin/marketplace.json` with a single entry and
`"source": "./"`; a README (what it is, the four skills one line each, the install lines, how
to run the evals with the manual runner and why, the honest "personal skills generalized"
origin); `LICENSE` (MIT, Sam Hillier); a short public-safe `CLAUDE.md` (run validate and the
grep gate before every push; never commit `evals/results/`). (2) The grep gate from the plan's
Verification section, zero results outside plugin.json, marketplace.json and LICENSE, then
`claude plugin validate --strict .` again. (3) Commit with a single-quoted message, then
`gh repo create hilliersmmain/session-hygiene --public --source . --push`. (4) In a session:
`/plugin marketplace add hilliersmmain/session-hygiene`, `/plugin install
session-hygiene@session-hygiene`, verify with `claude plugin list`, and in a fresh session
confirm the four appear as `session-hygiene:<skill>`. (5) Run the original `session-wrap`,
then retire the four originals to `~/.claude/backups/skills-personal-<date>/` per the plan's
step 9. (6) Name the cost first (about $2 to $4, 5 to 10 minutes), then
`evals/run-manual.sh take-stock-zero-milestone` and `evals/run-manual.sh prompt-capture-gate`,
grade the two replies per case against `graders/`, and record the result in the README.
Update `portfolio/roadmap.md` step 1 in `~/Projects/claude-portfolio-and-job-hunt` with the
repo URL when it is public. End with `session-wrap` and the restart block.
