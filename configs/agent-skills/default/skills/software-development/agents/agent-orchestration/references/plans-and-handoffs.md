# Plans and Handoffs

Scope: task boundaries, context transfer, and sequencing for implementations that use multiple agents.

## Preparation and dependency scope

Before expanding preparation, identify the next user-relevant outcome and what genuinely prevents the
next authorized step. A discovered problem is not automatically a prerequisite for every path.
Preserve safety and correctness gates, but keep blockers attached to the work they affect. When a
repair creates more changes or verification obligations, reconsider whether its broader scope is
necessary. Once the scoped claim is adequately evidenced, return to the main objective.

**Tell:** Preparation keeps producing additional tasks, but not a new result relevant to the user's
goal.

## Plans as usable handoffs

- An independently executable task has a clear file boundary, an interface with neighboring work, and an observable way to assess the result; enough domain context keeps a fresh implementer from having to infer hidden constraints. (src: writing-plans; src: sdd-worktree-orchestration, portable lesson)
- Fresh implementer and reviewer contexts can reduce self-justification and context contamination. A review brief rooted in original requirements, rather than the implementer's account, helps reviewers assess what is present rather than what was intended. (src: subagent-driven-development; src: stacked-issues)
- For dependent issues, later work is based on the prior issue's implementation; comparing each change with the preceding tip makes it clearer which issue introduced it than a common-base comparison. (src: stacked-issues)
- A local branch handoff does not by itself authorize pushing or opening a pull request; implementation permission does not imply permission to publish. (src: stacked-issues)
- Relative paths can resolve against a session's working directory rather than the shell's current directory; explicit workspace-qualified paths prevent a handoff from editing a different checkout. (src: sdd-worktree-orchestration, portable lesson; source 2026-07-18)
- Concurrent workers that share one Git index can race over staging and commits. When that shared-index risk applies, serialized commits scoped to owned paths avoid the race. (src: sdd-worktree-orchestration, portable lesson; source 2026-07-18)
- Could generated briefs or reports overwrite durable history because their “scratch” directory is tracked, and does a task-local check omit a stricter project-wide gate? (src: sdd-worktree-orchestration, portable lesson; source 2026-07-18)

## From approved design to a working increment

- Recover the approved semantics and acceptance boundary from existing design and implementation surfaces. Separate mechanics needed for the authorized increment from optional capabilities; do not reopen settled decisions or make the whole roadmap its gate. (src: iterative-software-delivery)
- Once authorization resolves execution choices, decide routine bounded mechanics rather than presenting serial menus. Ask when an unresolved choice affects meaning, information availability, public compatibility, irreversible state, or risk. A deferred capability or reversible provisional default is not approval of permanent policy. (src: iterative-software-delivery)
- Trace a real input through the smallest complete user-relevant path to an inspectable output; a builder, schema diagram, or wrapper alone does not demonstrate the running path. For a data system, inspect the produced data. (src: iterative-software-delivery)
- Name unsupported contracts and provisional defaults; fail explicitly rather than silently accepting declarations the implementation ignores. Preserve agreed domain semantics and source-of-truth policies when simplifying infrastructure. (src: iterative-software-delivery)
- Record only execution details needed in the existing workflow, including payload shapes and verification commands; do not duplicate the architecture as another specification. Keep integration and verification in coordinating scope. (src: iterative-software-delivery)
- When authorized, build and run relevant tests, drive the selected real input through the artifact, and inspect it through its consumer path. Distinguish unit, source-fixture, and integrated execution evidence; none substitutes for another. (src: iterative-software-delivery)
- Report what actually runs, its entry command and artifact location, and capabilities not yet qualified. Do not present one slice as the completed acceptance sequence or pending integration as finished. (src: iterative-software-delivery)

## Coordination questions

- Which dependencies require a later wave, and which files can genuinely be owned independently? Where are signatures, error vocabulary, and invariants frozen so downstream tasks do not guess?
- Does a purportedly verified configuration value reach a runtime consumer, and are the implementation, test, and documentation boundaries consistent?
- Is a task useful on its own, with a verification result that a fresh reviewer can assess against the original acceptance criteria?

