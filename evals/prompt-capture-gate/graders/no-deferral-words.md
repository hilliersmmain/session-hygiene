---
type: regex
target: { source: file, path: prompts/*.md }
pattern: '\b(investigate|figure out|look into|TBD|research whether|determine if)\b'
flags: i
match: not_contains
---
The written prompt hands the future session facts and instructions, never questions this session was better placed to answer.
