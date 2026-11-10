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
- For bounded image-build investigations, retain build logs and metadata, and inspect actual builder worker resource limits and available storage rather than relying on requested driver options.
- Distinguish DNS and trust at the runner, builder and image-process layers. Avoid dumping full inspection records that may contain certificate material; never disable TLS verification to make a probe pass.

## Image publication and qualification evidence

- For an image-build investigation, distinguish candidate tags and input hashes from immutable registry digests. Resolve an image index and its platform children independently; verify the intended platform set and descriptor identities, distinguishing attestation descriptors from runnable images.
- When storage limits affect builds, consider serializing them. If publication is explicitly authorized, publish uniquely tagged candidates before final aliases and read candidates back by immutable digest. Keep incomplete and complete platform-qualification receipts separate.
- A manifest inspection, imported library or emulated execution alone does not establish native accelerator kernel execution.
- For explicitly authorized accelerator qualification, use bounded dataset-free probes, isolate client state, disable analytics and restrict network access. Check dependency closure, source exclusion, imports, non-root execution, native initialization and a small deterministic kernel separately. Record workload and pod identities, architecture, requested image, observed image ID, exit status and output; establish whether the runtime reports an index or child digest.
- If a qualification leg is deferred, cancel task-owned queued workloads promptly when authorized and verify workload and pod absence. Continue only permitted legs; treat final promotion and configuration activation as separate decisions. Record final state before removing task-owned resources; do not prune shared caches or delete a manifest merely to remove a tag, since other tags may reference the same digest.

## Pitfalls

- A negative queue time is a re-run artifact, not a fast job.
- Heavy local timing runs on a shared workstation measure the workstation.
- Listener metrics grouped by name split one scale set into many series; group by the scale-set label.
- A stall that only appears in listener logs will not show up in the pod-lifecycle join.
