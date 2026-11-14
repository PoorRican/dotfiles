---
name: kanban-worker
description: "Handle Hermes Kanban worker workspaces, retries and task handoffs."
version: 2.0.0
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [kanban, multi-agent, collaboration, workflow, pitfalls]
    related_skills: [kanban-orchestrator]
---

# Kanban worker

Hermes Kanban workers operate on dispatched tasks and leave handoffs for dependent workers. Task state may change between dispatch and startup, and persistent workspaces may contain artifacts from earlier runs.

- Inspect the task and comments at startup; stop if it has been blocked or archived. For retries, inspect prior run outcomes and errors before repeating work.
- Respect the assigned workspace: scratch is temporary, while directory and worktree workspaces may be shared or retain previous artifacts. Do not assume a missing worktree or branch has already been created.
- If `HERMES_TENANT` is set, namespace persistent memory entries by tenant to avoid cross-tenant leakage.
- Put downstream-relevant results and artifacts in the completion handoff. If blocked, use a specific reason and put longer context in a task comment.
- Include in `created_cards` only IDs returned by successful creates made by your profile. Invalid claims block completion; unresolved card IDs in summary prose can also generate warnings. Prefer `kanban_*` tools in workers: the CLI may be unavailable inside containerized backends.

## Workspace and retry

Work within `$HERMES_KANBAN_WORKSPACE` unless the task says otherwise. `scratch` is task-private and garbage-collected on archive; `dir:<path>` is shared persistent state; `worktree` is a Git worktree. If a worktree is missing, create it from the main repository: `git worktree add <path> <existing-branch>` for an existing branch, or `git worktree add -b <new-branch> <path>` for a new branch.

Call `kanban_show` and read comments before working: a task can be blocked or archived after dispatch. Closed `runs` identify retries; inspect `outcome`, `summary`, and `error`:

- `timed_out`: the previous run hit its runtime limit; chunk or shorten the work.
- `crashed`: investigate the error, such as an out-of-memory failure.
- `spawn_failed`: inspect the reported profile configuration, credentials, or PATH; block for help rather than retry blindly.
- `reclaimed` with an archive summary: check the current state; the operator may have archived it.
- `blocked`: read the unblock comment for the response.

## Handoff and blocking

Use `kanban_complete(summary=..., metadata=...)` to give downstream workers the results and structured details they need, such as changed files, checks, decisions, sources, or review findings. For created tasks, capture successful `kanban_create` return values and include their `task_id`s in `created_cards`:

```python
child = kanban_create(title="Address review finding", assignee="<profile>")
kanban_complete(
    summary="Review complete; created a remediation task.",
    metadata={"approved": False, "findings": ["Describe the finding"]},
    created_cards=[child["task_id"]],
)
```

If a create fails, omit its ID and report the failure. The completion gate rejects IDs that do not exist or were not created by your profile; unresolved `t_<hex>` IDs in summary prose produce advisory warnings.

For a blocker, put detailed context in `kanban_comment(task_id=os.environ["HERMES_KANBAN_TASK"], body=...)`, then call `kanban_block(reason=...)` with the specific decision or intervention needed. The reason is shown in the dashboard and notifier; the comment carries the longer context. When a task requires human review, the original `review-required: ` reason prefix surfaces that state; put structured handoff details in the comment because the block reason is plain text.

For long tasks, heartbeat with meaningful progress rather than empty or frequent messages; follow the deployment's lease requirements.

## Notifications and CLI

In `~/.hermes/config.yaml`, `notification_sources: ['*']` accepts cross-profile notifications from all profiles; a list of profile names or a comma-separated string restricts them. Omitting the key retains profile isolation.

Inside workers prefer `kanban_*` tools. For operators and scripts, equivalents include `hermes kanban show <id> --json`, `hermes kanban complete <id> --summary "..." --metadata '{...}'`, `hermes kanban block <id> "reason"`, and `hermes kanban create "title" --assignee <profile> --parent <id>`.
