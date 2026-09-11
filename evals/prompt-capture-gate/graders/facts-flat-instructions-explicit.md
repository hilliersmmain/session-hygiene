---
type: llm
target: { source: file, path: prompts/*.md }
---
PASS only if all hold for the prompt file:
1. It opens as a prompt addressed to a fresh session (where it runs, what the job is and why), not as a note about a prompt.
2. Every claim about the machine or the repo is either stated flat because it was verified (for example "foo-cli is not installed") or turned into an explicit instruction (for example "re-verify X before acting").
3. The privileged steps (adding an apt repo, enabling a unit) are marked as the user's to run, in one batched block, because sudo cannot authenticate from Claude Code's Bash tool.
4. No launch command, status table or commentary outside the prompt text itself.
FAIL otherwise.
