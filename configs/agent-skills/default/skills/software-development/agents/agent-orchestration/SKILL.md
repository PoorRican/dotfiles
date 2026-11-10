---
name: agent-orchestration
description: "Use when planning or coordinating multi-agent work: contract-first fan-outs, parallel correctness audits and diff reviews, implementation plans and handoffs, dependent issue chains, transcript-based recovery after crashes or file loss, and mining past sessions for unresolved threads. Also covers serialized test-execution lanes, pinned-tree boundary audits, integrating parallel worktree streams, and paired numbers-and-claims reviewers."
---

# Agent Orchestration

The common failure is dispatching agents with overlapping ownership or relying on shared conversation context, leaving incompatible work or reports that cannot be evaluated. These references collect portable design facts for parallel implementation, independent review, task handoffs, recovery, and retrospective session mining. They do not prescribe a fixed agent count, review battery, or tool runtime.

| When you are… | Open |
|---|---|
| Freezing interfaces or dividing implementation and audit work | [references/fanout-design.md](references/fanout-design.md) |
| Briefing independent diff reviewers or validating committed behavior | [references/review-dispatch.md](references/review-dispatch.md) |
| Giving many editing agents one serialized, memory-capped place to run tests and heavy scripts | [references/test-execution-lanes.md](references/test-execution-lanes.md) |
| Auditing compatibility across several repositories with one scout per boundary on pinned worktrees | [references/pinned-tree-boundary-audits.md](references/pinned-tree-boundary-audits.md) |
| Turning a plan into bounded handoffs or sequencing dependent issues | [references/plans-and-handoffs.md](references/plans-and-handoffs.md) |
| Recovering work after orchestration failure or accidental file loss | [references/recovery.md](references/recovery.md) |
| Mining old sessions and reconciling unresolved threads | [references/session-mining.md](references/session-mining.md) |
| Preventing collisions between parallel workers, or integrating several uncommitted worktree streams | [references/fanout-design.md](references/fanout-design.md) |
| Running paired numbers-and-claims reviewers on a results draft | [references/review-dispatch.md](references/review-dispatch.md) |
| Protecting an uncommitted shared tree before parallel semantic refactors | [references/recovery.md](references/recovery.md) |

