---
name: prompt-capture-gate
tags: [prompt-capture]
plugins: ["../.."]
runs: 1
max_turns: 25
allowed_tools: ["Read", "Glob", "Grep", "Write", "Bash(ls:*)", "Bash(cat:*)", "Bash(git log:*)", "Bash(git status:*)", "Bash(type:*)", "Bash(dpkg-query:*)", "Bash(systemctl:*)"]
---
Before we go on: this project needs the vendor apt repo for `foo-cli` added and a systemd user unit that runs `foo-cli sync` hourly. Don't do it now. Park it as a prompt file in this repo's prompts/ directory so I can run it in a fresh session later, then we'll get back to the parser.
