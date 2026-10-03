---
name: agent-orchestration
description: "Use when planning or coordinating multi-agent work: contract-first fan-outs, parallel correctness audits and diff reviews, implementation plans and handoffs, dependent issue chains, transcript-based recovery after crashes or file loss, and mining past sessions for unresolved threads."
---

# Agent Orchestration

The common failure is dispatching agents with overlapping ownership or relying on shared conversation context, leaving incompatible work or reports that cannot be evaluated. These references collect portable design facts for parallel implementation, independent review, task handoffs, recovery, and retrospective session mining. They do not prescribe a fixed agent count, review battery, or tool runtime.

| When you are… | Open |
|---|---|
| Freezing interfaces or dividing implementation and audit work | [references/fanout-design.md](references/fanout-design.md) |
| Briefing independent diff reviewers or validating committed behavior | [references/review-dispatch.md](references/review-dispatch.md) |
| Turning a plan into bounded handoffs or sequencing dependent issues | [references/plans-and-handoffs.md](references/plans-and-handoffs.md) |
| Recovering work after orchestration failure or accidental file loss | [references/recovery.md](references/recovery.md) |
| Mining old sessions and reconciling unresolved threads | [references/session-mining.md](references/session-mining.md) |

