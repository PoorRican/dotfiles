---
name: kueue-troubleshooting
description: "Use when a Kueue-managed workload is suspended, Pending or repeatedly evicted, or when a controller or webhook outage blocks Job submission."
---

# Kueue troubleshooting

Kueue admission and Kubernetes node placement are separate gates. An admitted workload can still be unschedulable, while a failing webhook can prevent Job creation altogether.

| Task | Reference |
|---|---|
| Distinguish quota admission from node fit, taints and requeue | [Admission versus node fit](references/admission-vs-node-fit.md) |
| Diagnose webhook outages and controller crashes | [Controller and backlog](references/controller-crashloop-and-job-backlog.md) |
