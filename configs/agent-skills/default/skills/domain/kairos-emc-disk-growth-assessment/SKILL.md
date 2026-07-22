---
name: kairos-emc-disk-growth-assessment
description: Diagnose rapid emc-local disk growth without destructive scans or changes
---

# Kairos emc-local disk growth assessment

Use this procedure for broad, read-only storage diagnosis on the single-node host.

1. Establish physical truth first: capture `df` bytes and inodes for `/`, `/mnt/data`, and `/mnt/btrfs_sdc`; identify filesystem type and backing device.
2. Query Prometheus node-exporter history for used-byte and used-inode deltas over several weeks, rolling 24-hour peaks, and the latest 1h slope. Compute runway from current free bytes and inodes. Prefer these physical slopes over workload counters.
3. Map current Kubernetes hostPath/PVC mounts from rendered manifests and live pod specs. Separate `/mnt/data` consumers from lakehouse services on `/mnt/btrfs_sdc`.
4. Avoid an unbounded recursive `du` on `/mnt/data`: rotational XFS may contain hundreds of millions of tiny files. Use bounded depth scans, exact directory counts at known partition levels, representative date partitions, and sampled file logical/allocated sizes.
5. For collector growth, inspect `_landing`, `_state`, continuous liveness, and market-data trees separately. Correlate stream/dataset cardinality with flush cadence to estimate potential physical file creation. A batch-commit metric may fan out into many Parquet files and is not a file-count metric.
6. Compare source pod start times against the filesystem growth timeline before blaming newly added sources. Treat reset-prone per-pod write counters as directional; filesystem deltas are authoritative.
7. Enumerate legacy/static roots only after confirming they are absent from current manifests. Before archival, verify owner/source truth, replay/audit requirements, DuckLake/MinIO ingestion, row/file counts, readability, and checksums.
8. Classify targets: active state/landing/current-day/PVC/Prometheus paths are protected; closed verified partitions and unreferenced immutable roots are candidates. Prefer moving verified archives to the spacious Btrfs root over blind deletion.
9. Check host systemd services, journals, container storage, and root-filesystem pressure independently. Disable stale writers before moving their roots.
10. Leave no inspection workload behind. Remove temporary pods, stop only assessment-owned scans, confirm absence, and report any pre-existing processes without killing them.
