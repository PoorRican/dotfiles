# Fan-out and File Recovery

Scope: surviving evidence and scope-control facts when an agent process, fan-out, or file edit is lost.

## Recovering agent work

- Loss of the orchestration process or job identifiers does not establish loss of work: partial reports, scripts, outputs, and persisted transcripts may remain. A disconnected local client also does not prove remote work stopped; could work still be running and duplicate expensive or unsafe activity if relaunched? (src: crashed-fanout-recovery; source 2026-08-27)
- Persisted transcript tool-call records can preserve full `write` or `edit` arguments even when rendered execution displays truncate them. A transcript route is useful only if an agent read or wrote the target file in that session. (src: agent-transcript-file-recovery; source 2026-08-06)
- A human's concurrent edits do not appear in an agent transcript. A read snapshot taken after those edits landed may be the only verbatim record of that content. Version-control dangling objects and editor backups are independent recovery sources. (src: agent-transcript-file-recovery; source 2026-08-06)
- Recovered partial results need to be explicitly passed to relaunches. Compare resumed work with the original acceptance criteria: relaunches can silently narrow scope while appearing to continue the same task. (src: crashed-fanout-recovery; source 2026-08-27)
- A steering message may not interrupt an agent already inside a long-running call. If continuing that call could be unsafe, cancellation is the relevant control rather than assuming the message has taken effect. (src: crashed-fanout-recovery; source 2026-08-27)

## File-loss boundary

- `git checkout` or `git restore` of a path returns it to the committed version and can erase every uncommitted edit in that file. For data-loss prevention, preserve a known pre-edit copy or reverse only the intended change rather than treating the repository version as a backup. (src: agent-transcript-file-recovery; source 2026-08-06)
- What surviving callers, tests, or adjacent files constrain the missing content, and which source provides the verbatim version rather than a reconstruction? (src: agent-transcript-file-recovery)
