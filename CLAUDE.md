# session-hygiene — working rules for this repo

This repo is a Claude Code plugin and it is public. The skills under `skills/` are the
product; everything else exists to keep them honest and installable.

## Before every push

```bash
./scripts/preflight.sh      # all four checks; exit 0 or it is not ready
```

It runs, in order: the scrub gate, the plugin manifest (strict), the marketplace manifest
(strict), and the components (strict). Run it after any change, not just before a push — it
takes about two seconds.

## What the checks actually guard — and what they don't

Measured 2026-09-13 with claude 2.1.268, by breaking each property and confirming it went red.
Written down because a check you trust for more than it does is worse than no check.

| Check | Goes red for | Does **not** catch |
|---|---|---|
| `scripts/scrub-gate.sh` | any scrub pattern in a tracked file, `Prompts/` included | untracked files (by design — gate what ships) |
| plugin manifest, strict | unknown/unrecognized fields, manifest errors | `marketplace.json` — a separate manifest, hence check 3 |
| marketplace manifest, strict | missing `owner`, missing description, bad `plugins[]` | — |
| components, strict | missing frontmatter, missing `description` | **invalid skill `name`** (spaces, capitals), **`name` not matching its directory**, **malformed `allowed-tools`** — all three passed validation |

That last row is why a human or a review agent still reads the skills before release; the
component validator confirms a skill has metadata, not that the metadata is correct.

### Never point a manifest check at a directory

`claude plugin validate <dir>` resolves to **one** manifest, and which one depends on what
happens to exist. With only `plugin.json` present it picks `plugin.json`; the moment
`marketplace.json` is added it silently switches to that and reports `contents: []`. So a
directory-target check changes meaning under you: it guarded the plugin manifest when it was
written, and the marketplace manifest one commit later, leaving `plugin.json` guarded by
nothing — while still printing a reassuring green. This repo hit exactly that on 2026-09-13.
Checks 2 and 3 name their files explicitly, and must keep doing so.

It is also why break-testing a check once is not enough: check 2 was verified to go red for an
unknown field, and then *stopped* guarding that file without any edit to the check itself.

### Why the manifest check is `--json` plus `jq`, not `validate --strict .`

`--strict` on the repo root also walks this `CLAUDE.md` and warns that it "is not loaded as
project context", then fails, because `--strict` treats warnings as errors. The warning is
about people who *install* the plugin — they do not receive this file, and that is correct.
It is irrelevant to its purpose, which is the people working in this repo, where it does load.
There is no suppression flag (`validate --help` offers only `--json` and `--strict`), so
`preflight.sh` asserts on `manifest.errors` and `manifest.warnings` directly: full strictness
on the manifest, and only that one known note tolerated.

## The scrub gate

These skills were generalized from a personal skills directory. `scripts/scrub-gate.sh` fails
if any machine-specific path, hostname, hardware detail, security-posture note or personal
reference reappears in a tracked file. **A hit is fixed, never excluded** — widening the
exclude list defeats the only check standing between a private note and a public repo. The
script states the reason for each existing exclusion inline.

## Other rules

- **Never commit `evals/results/`.** It holds full run transcripts, which quote scaffold paths
  and whatever the eval session touched. It is gitignored; keep it that way.
- **Any change to a skill re-runs `preflight.sh`**, even a one-word description edit — a
  description is the skill's trigger surface, and the check is cheap.
- **Skill descriptions stay third-person and machine-neutral.** They are read by the model to
  decide whether to fire; a first-person or setup-specific description misfires for everyone
  who is not the author.
- **`claude plugin eval` is early access and enabled per organization.** If it is gated off,
  use `evals/run-manual.sh <case>` and say so — do not try to work around the gating.
- Frontmatter fields are load-bearing here, not decoration: `allowed-tools`, `argument-hint`,
  `disable-model-invocation` and `context: fork` each appear on exactly one skill. Changing one
  changes how that skill is invoked; say what you expect to change before editing it.
