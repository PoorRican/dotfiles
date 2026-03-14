---
name: "manage-bills"
version: "0.1.0"
description: "Analyze bill obligations from markdown and return due-date + total summaries"
metadata:
  nuro: {}
---
# Manage Bills

Use this skill to compute upcoming bill obligations from markdown data.

## Purpose
- Parse `data/bills.md` and extract bill amounts and due dates.
- Return deterministic summaries for orchestration and user-facing answers.

## Script
- Script path: `scripts/manage_bills.py`
- Execution model: invoked by the tool runtime (not manually by the model).
- Timeout: `3000ms`

## Expected Input
The runtime passes JSON on `stdin` with:
- `local_root`: runtime data root (under `XDG_DATA_HOME/neuromancer`)
- `data_sources.markdown`: includes `data/bills.md`
- `arguments`: optional tool-call arguments

## Expected Output
The script emits JSON with:
- `bill_count`
- `total_due`
- `next_due_date`
- `next_due_amount`

## Agent Usage Rules
- Always use script output values directly; do not invent or estimate bill amounts.
- Sort messaging by `next_due_date` priority.
- If parsing fails or data is missing, report the exact file/error details.
