---
name: "logs"
version: "1.0.0"
description: "Read and write activity logs in the wiki vault."
metadata:
  nuro: {}
  openclaw:
    requires:
      bins: ["rg"]
---
# Logs Skill

Use this skill for workflows around activity logs and daily notes.

## Primary Tasks

1. Summarize past activity by scanning `logs/` markdown files.
2. Create new daily logs in `logs/YYYY-MM-DD.md`.
3. Keep entries concise and append-only unless asked to rewrite.

## Suggested Command Patterns

- List log files:
  `find <vault>/logs -maxdepth 1 -type f -name '*.md' | sort`
- Read all logs:
  `cat <vault>/logs/*.md`
- Create a new daily log:
  `cat > <vault>/logs/YYYY-MM-DD.md <<'EOF' ... EOF`

## Output Format

- For summaries: include key decisions, completed work, and open follow-ups.
- For new logs: include a title, date, and short bullet points.
