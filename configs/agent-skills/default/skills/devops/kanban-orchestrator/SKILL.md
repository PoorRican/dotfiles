---
name: kanban-orchestrator
description: "Orchestrate Hermes Kanban task graphs, profile routing, dependencies and worker recovery."
version: 3.0.0
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [kanban, multi-agent, orchestration, routing]
    related_skills: [kanban-worker]
---

# Kanban orchestrator

Hermes Kanban persists cross-agent work and dispatches it to configured profiles. Incorrect assignees or dependency links can leave work waiting or allow a child to run before its inputs exist.

- Discover available profiles with `hermes profile list`; an empty `kanban_list` result does not establish whether an assignee exists.
- Use cards where persistent handoffs, coordination or recovery justify them; small one-shot work may not need a board.
- Create parent cards first and pass their returned IDs as `parents` when creating a dependent child. Linking afterward leaves a window in which the child may be claimed prematurely. Leave genuinely independent work unlinked.
- If `HERMES_TENANT` is set, pass it as `tenant` to `kanban_create` so child tasks stay in the same namespace.
- For a stuck worker, inspect the task and its runs before reclaiming or reassigning it; reclamation aborts the running worker. Reassign only to a configured profile.

## Decompose and dispatch

1. Discover configured profiles before planning; an unknown assignee can leave a card in `ready` indefinitely. If no profile fits a lane, ask which existing profile to use or create.
2. Extract independent workstreams, map each to an available profile, and identify true data dependencies. Parallel lanes need no parent links; synthesis, integration, or review waits only on inputs it actually needs. If later work depends on intermediate findings, have a synthesis card plan it after reading the parent handoffs.
3. Create parents first, capture each successful return's `task_id`, then create children with `parents=[...]`. Children with unfinished parents stay in `todo` until all parents are `done`, then promote to `ready`.

```python
tenant = os.environ.get("HERMES_TENANT")
a = kanban_create(title="Research option A", assignee="<profile-A>", tenant=tenant)["task_id"]
b = kanban_create(title="Research option B", assignee="<profile-A>", tenant=tenant)["task_id"]
kanban_create(
    title="Synthesize findings",
    assignee="<profile-B>",
    parents=[a, b],
    tenant=tenant,
)
```

For an existing dependency, `kanban_link(parent_id=..., child_id=...)` takes the parent first; reversing the arguments gates the wrong task. If this orchestrator was itself dispatched as a task, finish with `kanban_complete(summary=..., metadata=...)`, including the graph and assignees in the handoff. Report the created tasks, their profiles, and dependencies to the user.

## Recovery

- `hermes kanban reclaim <task_id>` aborts the running worker and resets the task to `ready`.
- `hermes kanban reassign <task_id> <new-profile> --reclaim` changes the assignee and retries with a fresh worker. Use a configured profile.
- For a profile model problem, `hermes -p <profile> model` is the configuration entry point; change the model, then reclaim the task.
