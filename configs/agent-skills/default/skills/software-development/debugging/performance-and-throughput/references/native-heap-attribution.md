# Native heap attribution

Scope: deciding whether a long-running native (Rust/C) service's memory is live heap growth, allocator retention, or something outside the heap, and reading jemalloc profiles.

## Triage from gauges before any special build

- Allocated bytes rising monotonically means live-heap growth, so profile it. Allocated flat with resident well above it is allocator slack from churn. RSS well above jemalloc's resident figure is anonymous memory outside the jemalloc heap. These readings are inferences from the gauges until a profile confirms them. (src: native-heap-attribution; 2026-10-04)
- Under glibc, RSS can be allocator retention rather than a leak: a service's live heap stayed flat and far below its RSS, and making jemalloc the global allocator cut RSS several-fold. Compare the allocator's own gauges (allocated and resident) with RSS before treating RSS growth as a leak. (src: native-heap-attribution; 2026-10-04)
- Do not quote RSS from a `sum by (container)` query within minutes of a rollout: the metrics collector still holds the old pod's series. Filter by current pod names or read `/proc/1/status`. (src: native-heap-attribution; 2026-10-04)

## Profiling safely

- `tikv-jemalloc-sys` prefixes symbols, so the sampling variable is `_RJEM_MALLOC_CONF`; plain `MALLOC_CONF` is ignored. A working recipe: `_RJEM_MALLOC_CONF=prof:true,lg_prof_sample:19,lg_prof_interval:27`. Confirm `.heap` dump files appear. (src: native-heap-attribution; 2026-10-04)
- Never set `prof_gdump:true`: it dumps a profile on every new heap high-water mark and can flood the disk with files (and starve the process of time to serve its own metrics). (src: native-heap-attribution; 2026-10-04)

## Reading profiles

- Use `jeprof --text --inuse_space`. The flat view is dominated by `_rjem_je_prof_backtrace`, so use `--cum`, and use `--base=<early.heap>` to separate the startup high-water mark from growth. Cumulative frames overlap, so never sum them; quote process-level numbers from the gauges and RSS. (src: native-heap-attribution; 2026-10-04)
