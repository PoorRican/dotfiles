# Borrowed decode and benchmarks

## Borrowing and decoder contracts

- `#[serde(borrow)]` on a nested `Cow<str>` may still produce owned values. Where the wire format permits, borrowed `&str` can avoid that allocation, but escaped JSON strings cannot be borrowed directly.
- Equality does not prove borrowing. Check that a borrowed field points into the actual production payload buffer, and exercise the production byte-decoding path.
- A replacement decoder that gates state changes must preserve the original rejection set, including required fields it does not otherwise consume, and preserve forwarding of unrelated valid frames.
- Commit sequence state only after successful decoding and application. Validate fallible conversions before mutation so a failed frame cannot leave partial state; enqueue recovery before marking state stale so a failed enqueue does not leave stale state without recovery in flight.

## Benchmark evidence and fast paths

- Fewer allocations do not prove lower end-to-end latency. Compare complete pipeline shapes, including send, receive, and drop when ownership is part of the change.
- Use representative wire bytes: pretty printing or a JSON value round-trip can change key order and disable an order-sensitive fast path. Assert that the fast path actually engages.
- A prefix classifier can recognize the hot layout and fall back to full decoding for unknown layouts; it must not drop valid unfamiliar frames. Quick benchmark estimates are directional; use full estimates and confidence intervals for a performance claim.
- Code at the start of an `async fn` executes on first poll, not invocation. To measure residency from construction, capture the timestamp in a synchronous function returning a future and test the pre-poll interval.
