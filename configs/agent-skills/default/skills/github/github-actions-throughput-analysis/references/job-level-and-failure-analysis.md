# Job-level timing, duplicate spend and failure triage

Scope: once the queue-versus-runtime split points at the jobs themselves, or when a failure may be infrastructure rather than code.

## Step and layer timing

- Take step timings from the job's `.steps[]`. Derive finer timing from CI log timestamp gaps; never from heavy local timing runs.
- `gh api .../jobs/<id>/logs` often returns empty. Use `gh run view <run> -R <org>/<repo> --log --job <job_id>` instead. Log lines may begin with a byte-order mark before the timestamp, so strip it before parsing.
- For container builds, parse the BuildKit `#N DONE x.xs` lines to find slow layers and cache export.
- For test jobs, read the `N workers` line and the progress-percentage timeline to tell a straggler from low throughput.
- Compute step medians per job across runs to find the step that moves the total.

## Duplicate spend

- Group runs on `(repo, workflow, sha)` and flag groups that ran on both `push` and `pull_request` events; sum the runner hours they cost.
- Read the workflows from the remote default branch (`git show origin/<default>:.github/workflows/*.yml`) in each repository rather than from a local checkout that may be stale.

## Failures

- Before calling a failure a flake, check runner eviction (`kube_pod_status_reason`) and container terminations for the runner pod, and node IO pressure for timing-sensitive tests.
- Classify with `gh run view --log-failed`.
- Group failures by job and step, and by runner or node, before concluding anything about the test.

## Pitfalls

- A negative queue time is a re-run artifact, not a fast job.
- Heavy local timing runs on a shared workstation measure the workstation.
- Listener metrics grouped by name split one scale set into many series; group by the scale-set label.
- A stall that only appears in listener logs will not show up in the pod-lifecycle join.
