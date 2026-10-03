# Session Mining

Scope: discovering durable session-side evidence and deciding whether historical threads remain relevant.

## Transcript and artifact evidence

- Main conversation summaries can omit useful subagent reports and artifacts kept beside a session transcript. Session reconstruction is more complete when it includes user prompts, agent reports, plans, and artifacts, not just session titles. (src: past-session-thread-consolidation; source 2026-09-28)
- Historical recommendations are candidates, not current evidence. Open threads need re-adjudication against current source or live state; a remembered conclusion or plausible-looking endpoint name does not establish that it remains true. (src: past-session-thread-consolidation; source 2026-09-28)
- Repeated searches, retries, or tool friction can indicate missing durable context. Which missing fact would have prevented the detour, and does it recur enough to belong in maintained context? (src: agent-transcript-audit; source 2026-07-24)

## Conflict scope

- The audit's recovery conflict is resolved here in favor of preserving uncommitted work: restoring a tracked file to its committed state is not a safe undo when uncommitted edits may exist. (src: agent-transcript-file-recovery; source 2026-08-06)
- The reported disagreement between separate brainstorming conventions is outside this skill's remit; their workflow prescriptions are not imported or reconciled here. (src: past-session-thread-consolidation)
