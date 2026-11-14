---
name: marimo-pair
description: >-
  Pair on a live marimo notebook: discover and connect to a session, inspect
  its kernel, and make persistent reactive notebook edits.
allowed-tools: Bash(bash **/scripts/discover-servers.sh *), Bash(bash **/scripts/execute-code.sh *), Read
---

marimo notebooks run as a reactive graph. During a live session the kernel owns the current cell state; editing the saved Python file directly can miss the active session and be overwritten on save. Scratchpad assignments are transient, so persistent changes need the live notebook API.

| Reference | When to use |
|---|---|
| [Live pairing](reference/execution-context.md) | Connect, inspect or edit a running notebook; diagnose session and reactive graph issues. |
| [Rich representations](reference/rich-representations.md) | Choose and integrate custom interactive notebook output. |
