# Training-loop throughput

## Input and step capacity

- Low GPU activity alongside a saturated CPU core can indicate serial host work. Compare GPU activity and CPU use over the same interval; repeated decoding, object construction, and tiny tensor calls can impose a representation overhead distinct from required arithmetic.
- Asynchronous CUDA work can finish during the next loader wait, inflating apparent data-wait time. Measure synchronized loader fetch, collation and transfer separately from a synchronized optimization step on a resident batch.
- More workers cannot eliminate serial work within each batch and may oversubscribe the host. Many small tensors can make object, IPC, and transfer overhead depend on tensor count as well as bytes.
- Packed graph representations can avoid per-object construction, but establish edge and node-identity equivalence across graph kinds before replacing persisted structures. An absent relation in one sample does not establish that it is globally unused.
- A selected checkpoint's step count may precede the end of the fit. Keep configured, completed, and selected counts separate when projecting duration; account for queue waits and checkpoint frequency.

## CUDA and container traps

- CUDA faults are asynchronous, so the reported traceback may identify where an earlier failure surfaced. Blocking launches can help localize faults but can also mask cross-stream and allocator races.
- A side-stream copy followed only by a current-stream wait can leave tensor storage eligible for reuse while another stream still consumes it. Use `record_stream()` on the tensor or explicitly synchronize its lifetime back to the allocation stream; default-stream copies avoid this particular cross-stream hazard.
- Data-loader shared-memory exhaustion can resemble ordinary container memory exhaustion. Check `/dev/shm` capacity inside the container: some runtimes default to 64 MiB, but the actual mount can differ.
- A driver compatibility version alone does not prove a workload initializes: feature and PTX requirements also matter. Test the actual workload on the target device.

## Streaming datasets

- A shuffle whose working set exceeds an LRU cache can repeatedly fetch and decompress shards. Measure actual remote fetches and step time; a shuffle replay alone does not establish remote behavior. Changing shuffle settings can also change sample order, making timings an unmatched training comparison.
- Mosaic Streaming's `cache_limit` is per dataset, not a shared split limit, so train and validation caches can coexist. A local cache keyed only by a version string can reuse an old index for a different remote root; namespace it by immutable artifact identity.
- Mosaic's explicit-list index merge can prefix shards with only each input index's immediate parent basename, losing deeper path components; open the merged index and read a record from every part, noting that local reachability does not establish remote credentials.
- In Lightning plus Mosaic Streaming, loader construction and reloading can advance `next_epoch` twice; verify epoch continuity on resume and bind it to the trainer epoch when the installed versions exhibit this behavior.
- Lightning `EarlyStopping.state_dict` may omit `should_stop`; inspect the installed version and persist this flag separately when exact continuation requires it.
- Filtering an iterable independently in each worker can produce more worker-local partial batches than a global length calculation predicts, silently dropping samples when the trainer stops at that length. Verify actual merged batch counts, or filter and pack globally.
