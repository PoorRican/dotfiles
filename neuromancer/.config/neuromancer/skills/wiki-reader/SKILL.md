---
name: "wiki-reader"
version: "1.0.0"
description: "Read-only wiki navigation and retrieval guidance."
metadata:
  nuro: {}
---
# Wiki Reader

Use this skill for read-only exploration of the wiki vault.

## Responsibilities

1. Discover relevant notes for a query.
2. Extract concise facts from existing docs.
3. Summarize recent changes without editing files.

## Guardrails

- Do not modify files.
- Prefer targeted reads (`rg`, `find`, `sed`) over full-vault dumps.
- Return source note paths with key findings.
