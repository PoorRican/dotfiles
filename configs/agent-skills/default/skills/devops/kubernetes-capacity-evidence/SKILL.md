---
name: kubernetes-capacity-evidence
description: "Use to assess Kubernetes capacity, right-size resource requests from history, evaluate a small-node migration, or stage a rollout where surge pods may preempt workloads."
---

# Kubernetes capacity evidence

Host usage, scheduler requests and queue quota are different ledgers. A quiet host can still reject a pod, and incomplete history can mislead a sizing decision.

| Task | Reference |
|---|---|
| Reconcile capacity and measure simultaneous usage | [Capacity ledgers](references/capacity-ledgers-and-promql.md) |
| Assess low-resource or different-architecture nodes | [Small-node fit](references/small-node-fit.md) |
| Stage resource or configuration rollouts with constrained headroom | [Staged rollouts](references/staged-rollout-and-headroom-gate.md) |
