# Test execution lanes

Scope: letting many agents edit in parallel while test, type-check, and heavy-script execution stays serialized and memory-capped on one host. Many agents running test suites at once can crash a shared machine.

## Topology

- Keep high parallelism for reading and editing, let no worker run tests, and route all execution through one small coordinator that owns strictly serialized, memory-capped lanes. A worker's job ends at "edits done, here is the command"; the coordinator runs it and returns the evidence. (src: test-lane-coordination; 2026-10)
- Give each agent group its own lane. In one dated 2026-10 wave a single shared lane starved the critical path for about 1.5 h. (src: test-lane-coordination; 2026-10)
- Every waiting agent needs a request that some lane holds, or all park deadlocked; a wait primitive does not see parked agents. Periodically ask each lane for its pending queue (`requester | arrival | command`) and use priority tiers, because coordinators can silently skip requests that arrive mid-run. (src: test-lane-coordination; 2026-10)

## Request and reply grammar

- One request per line: requester, timeout, command. Reply with a result line (`lane#N`, exit status, wall time, peak memory), the last 60 log lines, the first traceback (at most 40 lines, grepped from the log, never a rerun), and the log path. (src: test-lane-coordination; 2026-10)
- Clamp timeouts to 60-3,300 s and set the caller's own tool timeout 120-300 s above the run's. A `-k` expression applies to the whole request, not to one file. (src: test-lane-coordination; 2026-10)

## Caps and exit codes

- Cap each run with `systemd-run --user --scope --collect` (`MemoryMax`, `MemorySwapMax=0`, `CPUQuota`) plus thread-count environment variables. `Nice=` is rejected for scopes, so put `nice` inside the command. Read `memory.peak` from the scope's own cgroup; the journal can miss short scopes. (src: test-lane-coordination; 2026-10)
- An OOM kill at the cap is a finding, not flakiness: rerun the file with `-v -x`, read the last node id, and fix the cause. Raising the cap is never the answer; here the kills exposed a dense grid and an `index_add` retention defect. (src: test-lane-coordination; 2026-10)
- Treat infrastructure exit codes (copy, ssh, sync failures) as retry-once and 124 as a timeout. Split receipts near the timeout instead of raising it. (src: test-lane-coordination; 2026-10)
