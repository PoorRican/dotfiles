---
name: "manage-accounts"
version: "0.1.0"
description: "Compute liquidity summary from account balances CSV"
metadata:
  nuro: {}
---
# Manage Accounts

Use this skill to compute current liquidity from account balance data.

## Purpose
- Parse `data/accounts.csv` and aggregate balances across all rows.
- Return deterministic account-count and total-liquidity values for downstream reasoning.

## Script
- Script path: `scripts/manage_accounts.py`
- Execution model: invoked by the tool runtime (not manually by the model).
- Timeout: `3000ms`

## Expected Input
The runtime passes JSON on `stdin` with:
- `local_root`: runtime data root (under `XDG_DATA_HOME/neuromancer`)
- `data_sources.csv`: includes `data/accounts.csv`
- `arguments`: optional tool-call arguments

## Expected Output
The script emits JSON with:
- `account_count`
- `total_balance`

## Agent Usage Rules
- Use `script_result` values as the source of truth for liquidity numbers.
- Keep account summaries numeric and concise (count + total first).
- If parsing fails or data is missing, report the exact file/error details.
