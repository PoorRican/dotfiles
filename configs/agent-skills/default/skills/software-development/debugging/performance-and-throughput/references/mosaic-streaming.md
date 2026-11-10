# Mosaic Streaming caches and merged indexes

Scope: Mosaic StreamingDataset cache behavior and MDS merged-index path semantics, without workload-specific measurements.

## Shuffle and cache interactions

- In the Mosaic behavior described on 2026-09-05, a split smaller than the default shuffle block can be shuffled as a global permutation. With an LRU cache, the working set then approaches the whole split, so repeated shard fetch and decompression can dominate an otherwise fast warm/local loader. (src: mosaic-streaming-cache-thrash-audit)
- On 2026-09-05, `cache_limit` applied to each `StreamingDataset`, not collectively across splits. Train and validation caches can coexist after validation begins, alongside checkpoint or log staging; checking only one split’s cache can therefore understate local-storage demand. (src: mosaic-streaming-cache-thrash-audit)
- A shuffle/LRU replay estimates likely fetches but does not prove behavior on a remote artifact path. Actual shard fetches, decompressed bytes, and step time can expose remote-path effects; a faster loader can also reveal a separate resident-step or collation bottleneck. (src: mosaic-streaming-cache-thrash-audit)
- A cache or shuffle improvement can expose a separate loader-side collation cost, such as constructing many small graph objects. Loader work and resident-batch optimization cost are therefore separate attribution targets, not one effect of the cache settings. (src: mosaic-streaming-cache-thrash-audit)


- Changing shuffle block size changes sample ordering and batch composition. Timing differences across such settings are not automatically a matched comparison of the same training sequence. (src: mosaic-streaming-cache-thrash-audit)

## Merged MDS index paths

- The Mosaic explicit-list index merge described on 2026-09-02 prefixes shard paths with only the immediate parent basename of each supplied `index.json`; nesting part roots more deeply can leave merged indexes with incomplete relative paths. (src: mosaic-mds-parallel-merge-layout)
- A local merged-reader check described on 2026-09-02, opening a real merged index and reading a record from every part, proves local index-path reachability and ordering. It does not prove deployed object-store credentials or cache behavior. (src: mosaic-mds-parallel-merge-layout)

## Resume semantics and cache namespaces

- Exact continuation of a Lightning plus Mosaic StreamingDataset run needs more than optimizer and sampler state. Lightning may build the loader while estimating stepping batches and then reload it, so Mosaic's `next_epoch` can advance twice (its `_resume_incr_epoch` sets `next_epoch = epoch + 1`): bind `next_epoch` to `trainer.current_epoch` per loader. `EarlyStopping.state_dict` omits `should_stop`, so persist it yourself. Source-checked against Lightning 2.6.5 and the streaming source; the double advance itself was not re-run. (src: lightning-mosaic-resume, 2026-10)
- A loader factory that keys its local cache only by a dataset version string can serve stale data: mosaicml-streaming 0.13.0 reuses an existing local index without checking the new remote root (`stream.py:440-443`), so a second remote root returned the first root's data. Make the cache namespace the immutable artifact identity (content digest or full remote path), not a version label. (src: mosaic-cache-namespace, 2026-09-04)
