# Fan-out design

## Contracts and ownership

Freeze shared signatures, types, and invariants before dispatch when downstream work depends on them. Give each worker the objective, exact workspace, owned files, neighboring interfaces, constraints, and observable acceptance criteria. Partition by independent behavior as well as files: separate files in one interlocking subsystem can still conflict. Later instructions from the coordinator supersede an earlier brief; a worker should ask rather than revert another worker's correction.

Shared templates amplify unnecessary ceremony across every worker. Specify outcomes and constraints instead. A worker's report is not verification: integrate changes and check them against the original requirements, including frozen constants and test coverage.

## Shared resources and integration

File ownership does not isolate builds: another worker's unfinished changes can break a shared dependency graph. Coordinate verification after edits settle. When concurrent suites or heavy scripts could exhaust a host, route execution through a coordinator with bounded resource use and serialized lanes as appropriate. Avoid starving critical work in a single queue; track pending requests and priorities so waiting agents do not deadlock or silently lose requests. Return the actual exit status, relevant failure output and log location. An out-of-memory exit warrants investigation; adjust a cap only when justified by the workload and host capacity.

Use one request per line with requester, timeout, and command; reply with exit status, elapsed time, peak memory, relevant failure output and log path. Set workload-appropriate timeout bounds and allow the caller longer than the lane timeout. Track queued requests explicitly: requests arriving during a run can be skipped, and parked agents deadlock if no lane holds their requests.

On systems with user systemd scopes, a lane can use `systemd-run --user --scope --collect` with `MemoryMax`, `MemorySwapMax` and `CPUQuota` and appropriate thread limits. Put `nice` inside the command: `Nice=` is rejected for scopes. Read peak memory and OOM events from the scope's own cgroup, since short-lived scopes can be missed by the journal. Before relying on a lane, run a small test and check the reported peak, then exceed a small cap and confirm an OOM event and nonzero exit. Treat an OOM as a finding, not automatically as flaky. Distinguish infrastructure failures from workload failure and timeout; retry a transient infrastructure failure once. Exit codes such as 90–92 have that meaning only if the lane helper assigns them; 124 denotes timeout when the timeout wrapper uses that convention.

For uncommitted streams, agree on shared-file ownership and hunks before work begins, and confirm writers have stopped before integrating. Preserve each stream's changes without disturbing its index. Integrate providers before consumers, resolve shared additions without duplicating generalized paths, and reconcile fixtures against the intended contract rather than assuming either the fixture or the new rule is correct. Stage only owned integration changes, and report staged and verified state separately.

To export a stream without changing its real index, set `GIT_INDEX_FILE` to a new scratch index, initialize it with `git read-tree HEAD`, stage the stream in that temporary index, and write `git diff --cached --binary HEAD` to a patch. Re-export and compare patches to detect late changes, accounting for object-ID header differences. Apply provider patches first, trying `git apply --index` and resolving or using `--3way` when appropriate. Do not pipe `git apply` through `grep -v` under `set -e`: the pipeline can hide an apply failure; inspect the command's status or `PIPESTATUS`.
