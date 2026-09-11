#!/usr/bin/env bash
# The scenario: a small project mid-work, with an empty prompts/ directory waiting.
set -euo pipefail
git init -q .
mkdir -p src/notesync prompts
: > prompts/.gitkeep
cat > README.md <<'FILE'
# notesync

Pulls notes from a vendor service with `foo-cli` and normalises them into Markdown.
`src/notesync/parse.py` is the current work: the front-matter parser.
FILE
cat > src/notesync/parse.py <<'FILE'
def parse_front_matter(text: str) -> dict:
    """Parse the --- block at the top of a note. Work in progress."""
    raise NotImplementedError
FILE
git add -A && git -c user.name=eval -c user.email=eval@example.com commit -q -m 'notesync: parser skeleton, empty prompts dir'
