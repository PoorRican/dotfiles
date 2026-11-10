---
name: github-actions-throughput-analysis
description: "Use when CI feels slow or before resizing self-hosted runner capacity: separate queue time from runner start latency and execution time by joining the GitHub API's runs and jobs with runner-pod lifecycle metrics, replay slot counts, find duplicate spend and classify failures before calling them flakes."
---

# GitHub Actions throughput analysis

"CI is slow" can mean the queue (not enough runner slots), the runner system (scheduling, boot, registration), or the job itself (a slow layer, a straggler test shard). Measuring first keeps capacity changes and workflow edits aimed at the right layer. The analysis is read-only and authorizes no change; report what is merged, what is applied and what is observed at runtime as three separate states.

| When you are… | Open |
|---|---|
| Collecting runs and jobs, splitting each job's wait into scheduling, boot and registration phases, bucketing by pool saturation, or replaying slot counts | [references/queue-vs-runtime-analysis.md](references/queue-vs-runtime-analysis.md) |
| Reading step timings and slow layers, finding duplicate runs, or classifying a failure before calling it a flake | [references/job-level-and-failure-analysis.md](references/job-level-and-failure-analysis.md) |
