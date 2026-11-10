# Async and storage runtime traps

Scope: runtime behaviors in async Rust services and object-store code that compile and pass local tests while failing silently elsewhere.

## Unobserved spawned tasks

- A panic inside a `tokio::spawn`ed task whose `JoinHandle` is never awaited kills that task silently: the panic unwinds, tokio drops the task, the process keeps running (restart count 0), and any connection or health flag the task does not own (for example a websocket's own `connected: AtomicBool`) stays true. One event class goes dark with no error signal downstream. (src: spawned-task-panic; 2026-08-08)
- Diagnostic signature: one event class stops arriving while a sibling class on a different transport keeps working (here order acknowledgements came from a synchronous HTTP path while fills came from the spawned stream task); the process is alive; the counterpart's own API shows the events happening. Grep the container log for `panicked at` even though the process never died. (src: spawned-task-panic; 2026-08-08)
- Structural fixes: guard every fallible identifier conversion at the transport boundary (an update carrying an empty identifier, from another session sharing the account, hit an unguarded `new_checked` conversion while sibling REST mappers in the same file already guarded it); never leave a long-lived spawned task's handle unobserved: await it or supervise it and surface its death as a health failure; and configure a periodic reconciliation safety net so a dead stream does not remain the only source of truth. (src: spawned-task-panic; 2026-08-08)

## object_store paths

- `object_store::path::Path::join("a/b")` appends one `PathPart` and percent-encodes the slash as `%2F`. A local-filesystem store decodes it and hides the defect, while S3 receives wrong keys. Build multi-segment paths with `Path::from_iter` over the `split('/')` parts, and verify real S3 keys plus local/S3 byte parity. (src: object-store-path-join; 2026-10)
