---
name: kueue-troubleshooting
description: "Use when a Kueue-managed Kubernetes Job stays suspended or Pending (admitted but unschedulable, PodsReadyTimeout eviction loops) or Job submission fails because the Kueue webhook has no endpoints: separates the quota ledger from node fit, taints and real usage, and recovers a crash-looping controller backed up by finished Jobs."
---

# Kueue troubleshooting

Kueue adds an admission layer in front of kube-scheduler, and the two disagree in ways that look like one problem: a workload can be admitted yet unschedulable, a quota can look free while nothing runs, and a controller outage can block every Job on the cluster. Diagnose which gate or component is failing before changing quota, priority or anyone else's workload; report options and act only with approval when the objects belong to someone else.

| When you are… | Open |
|---|---|
| Looking at an admitted Job whose pod stays Pending, loops through PodsReadyTimeout evictions, or waits "for quota" while the node looks idle | [references/admission-vs-node-fit.md](references/admission-vs-node-fit.md) |
| Seeing `failed calling webhook ... no endpoints` on submission, a CrashLoopBackOff controller, a finished-Job backlog, or a GPU step Pending while the GPU is idle | [references/controller-crashloop-and-job-backlog.md](references/controller-crashloop-and-job-backlog.md) |
