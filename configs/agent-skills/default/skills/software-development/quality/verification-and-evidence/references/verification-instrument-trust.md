# Verification instrument trust

## Execution and scope

- A filtered test can exit successfully with zero collected tests. Record the actual runner, executed count, and individual gate statuses; calling test functions directly can bypass fixture lifecycle.
- A shell pipeline can mask an upstream failure. A container interpreter reading a heredoc may execute empty stdin and exit successfully if stdin was not attached: Docker's `-i` must precede the image name. Check that the intended payload ran.
- A stub on `PATH` can shadow the real executable and return successful empty output. Check executable resolution and exercise the real generated payload, not a copied inner fragment.
- An empty query or narrow search is weak evidence of absence. For an empty gate, inspect predicate values and population: SQL NULL comparisons exclude rows, universal predicates over empty sets pass vacuously, and filtered and unfiltered counts can make a gate impossible.
- A gate that never passed has not exercised downstream stages. A local green is not end-to-end completion; distinguish implementation, exercised behavior, and an actual blocker.
- In a worker-backed pipeline, no output may mean a Pending or misconfigured worker, a terminated worker, or a launcher that ran inline instead of creating a worker. A Running-only filter can hide the failure reason.
- For a membership-scoped consumer, test members whose events cross the selection boundary, nonmembers, an explicitly empty selection, and selected members with missing source records.
- Launcher success is not worker completion or evidence quality. Reconcile every planned window, including missed and disabled ones, with completion records, actual files and block records; investigate discrepancies.
- A comparator exception is an instrument failure, not a data discrepancy. Check failure reasons, supported types and nulls before interpreting a parity verdict.

## Independent truth and controls

- Structural invariants and legacy parity do not establish semantic truth. Compare output assertions with independently source-derived, hand-checkable expectations; legacy parity may reproduce legacy defects.
- A matching diagnostic count proves detection, not correct handling. Inspect the emitted or stored result.
- To test a proposed corruption mechanism, derive its per-record signature and evaluate a representative retained population, not just examples. Even a perfect match may not exclude competing causes; a zero dangerous count requires a deliberately over-inclusive danger filter.
- A positive control must show a dependency blocker can actually fire. For mutation testing, confirm the mutation took effect and the intended assertion failed, rather than a compile error or unrelated harness failure. Restore exact pre-mutation bytes, especially in a dirty tree, then rerun the check.
- Compare test collection and behavior before and after a change: a green suite cannot reveal deleted tests. A shared editable install can silently make both checkouts import the same source; confirm loaded paths and use an isolated baseline.
- A clean checkout tests whether untracked local inputs were required. Record the identity of the script and inputs actually executed; a later edited or committed script is a different artifact.
- When comparing unchanged outputs against a source snapshot, check import resolution: Python's script directory can precede `PYTHONPATH`, causing both probes to load the working tree. Compare only outputs invariant under the intended change.
- For a Python source baseline, extract `HEAD` with `git archive HEAD <pkg> | tar -x -C <dir>` and run the same probe as a file from a directory that does not contain the package, with `PYTHONPATH=<dir>`. A script beside the working-tree package or `python -c` can put that working tree ahead of the baseline. Do not stash other people's work.
