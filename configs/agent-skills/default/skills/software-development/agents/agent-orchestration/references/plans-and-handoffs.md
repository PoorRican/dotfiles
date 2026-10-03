# Plans and Handoffs

Scope: task boundaries, context transfer, and sequencing for implementations that use multiple agents.

## Plans as usable handoffs

- An independently executable task has a clear file boundary, an interface with neighboring work, and an observable way to assess the result; enough domain context keeps a fresh implementer from having to infer hidden constraints. (src: writing-plans; src: sdd-worktree-orchestration, portable lesson)
- Fresh implementer and reviewer contexts can reduce self-justification and context contamination. A review brief rooted in original requirements, rather than the implementer's account, helps reviewers assess what is present rather than what was intended. (src: subagent-driven-development; src: stacked-issues)
- For dependent issues, later work is based on the prior issue's implementation; comparing each change with the preceding tip makes it clearer which issue introduced it than a common-base comparison. (src: stacked-issues)
- A local branch handoff does not by itself authorize pushing or opening a pull request; implementation permission does not imply permission to publish. (src: stacked-issues)
- Relative paths can resolve against a session's working directory rather than the shell's current directory; explicit workspace-qualified paths prevent a handoff from editing a different checkout. (src: sdd-worktree-orchestration, portable lesson; source 2026-07-18)
- Concurrent workers that share one Git index can race over staging and commits. When that shared-index risk applies, serialized commits scoped to owned paths avoid the race. (src: sdd-worktree-orchestration, portable lesson; source 2026-07-18)
- Could generated briefs or reports overwrite durable history because their “scratch” directory is tracked, and does a task-local check omit a stricter project-wide gate? (src: sdd-worktree-orchestration, portable lesson; source 2026-07-18)

## Coordination questions

- Which dependencies require a later wave, and which files can genuinely be owned independently? Where are signatures, error vocabulary, and invariants frozen so downstream tasks do not guess?
- Does a purportedly verified configuration value reach a runtime consumer, and are the implementation, test, and documentation boundaries consistent?
- Is a task useful on its own, with a verification result that a fresh reviewer can assess against the original acceptance criteria?

