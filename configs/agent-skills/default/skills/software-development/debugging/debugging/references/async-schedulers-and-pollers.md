# Async schedulers and pollers

Scope: failure modes of an asyncio recorder or poller that schedules many periodic and discovered requests under a rate limit.

## Scheduler loop

- A scheduler loop must yield on every normal iteration. Otherwise it can enqueue its initial tasks and then busy-spin, starving every coroutine while logging misleading "already in flight" skips. The log line looks like contention; CPU saturation of the loop thread is the tell. (src: async-poller-lessons; 2026-09-24)

## Admission and cadence

- Bound each periodic target to one outstanding request, and reserve admission capacity for core polls ahead of discovery probes, so a burst of discovered follow-ups cannot crowd out the polls that define the recording. (src: async-poller-lessons; 2026-09-24)
- When the cadence changes (slow before an event, fast during it), re-arm targets that already exist; do not only schedule targets absent from the due table. Otherwise stale slow-cadence deadlines persist across the phase boundary (a five-minute-old deadline was found this way). (src: async-poller-lessons; 2026-09-24)

## Verification

- Test with a realistic many-follow-up local HTTP server, and inspect the actual rolling request windows and per-target gaps, not just that requests were sent. A rehearsal against a real completed event exposed starvation and bursts that unit tests with a handful of targets did not. (src: async-poller-lessons; 2026-09-24)
