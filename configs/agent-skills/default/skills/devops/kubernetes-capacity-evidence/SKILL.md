---
name: kubernetes-capacity-evidence
description: "Use when deciding whether Kubernetes capacity is actually short (host usage vs scheduler requests vs quota), right-sizing requests from Prometheus history, assessing whether an always-on workload fits a smaller node, or rolling out resource changes in stages on a node with priority-based preemption. Also covers tracking authorized long-running copies and interpreting incomplete size scans."
---

# Kubernetes capacity evidence

Scheduling capacity is usually lost to requests, not to usage, and the three ledgers (host actual, scheduler requests, quota) disagree. Sizing advice built on a quiet sample, a stale peak or a manifest request misleads. These references fix how the evidence is collected and how resource changes are applied once a number is chosen.

| When you are… | Open |
|---|---|
| Reconciling host usage, bound-pod requests and quota before touching a quota, or reading peaks and growth from Prometheus | [references/capacity-ledgers-and-promql.md](references/capacity-ledgers-and-promql.md) |
| Asked whether an always-on workload could move to a small, low-RAM or ARM node | [references/small-node-fit.md](references/small-node-fit.md) |
| Applying a resource or config change that restarts several Deployments on a node where surge pods can preempt other workloads | [references/staged-rollout-and-headroom-gate.md](references/staged-rollout-and-headroom-gate.md) |
| Tracking an authorized long-running copy or interpreting a timed-out size scan | [references/long-running-copy-processes.md](references/long-running-copy-processes.md) |

## Rules that hold across the references

- Measure from history, not manifest requests; check the oldest retained sample before trusting any peak.
- Pod peak is the maximum over time of the per-pod sum, never the sum of per-container maxima, and class peaks are the maximum over time of the per-timestep sum, never a sum of per-pod maxima.
- An allocator, runtime or binary change resets sizing evidence; re-measure on the new build.
- Partial history is evidence of over-reservation, not grounds for setting new requests.
- Report options and the arithmetic; change quota, priority or someone else's workload only with approval.
