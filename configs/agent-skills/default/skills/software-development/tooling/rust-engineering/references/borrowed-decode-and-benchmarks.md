# Borrowed decode and benchmarks

Scope: Serde borrowing, validity parity, state-safe decoding, and performance claims for message pipelines.

## Borrowing and decoder contracts

- `#[serde(borrow)]` on a direct `Cow<'a, str>` does not ensure borrowing when the field is nested in containers; such values can become `Cow::Owned`. Where the wire value cannot contain escapes, `&'a str` avoids that hidden allocation. (src: serde-borrow-and-json-bench-traps, 2026-08-03; zero-copy-decode-refactor-verification, 2026-08-03)
- A functional equality test cannot show whether a field borrowed. A pointer-range check against the exact production payload buffer distinguishes a borrowed field from a fresh allocation; test helpers using `String`/`from_str` do not exercise a byte-buffer/`from_slice` production path. (src: serde-borrow-and-json-bench-traps, 2026-08-03; zero-copy-decode-refactor-verification, 2026-08-03)
- A narrower decoder that gates state changes must preserve the original decoder's rejection set, including required fields it does not otherwise use. If a control decoder forwards unrelated frames, the forwarding direction is also part of validity: otherwise valid market frames can be silently dropped. (src: serde-borrow-and-json-bench-traps, 2026-08-03; zero-copy-decode-refactor-verification, 2026-08-03)

## State transitions and recovery

- A header-only sequence peek can advance sequence state before full decode; a malformed delta may then be dropped without the next valid frame triggering gap recovery. Sequence/version state belongs to the successful-apply commit, not inspection. (src: zero-copy-decode-refactor-verification, 2026-08-03)
- Applying a frame through fallible conversions can leave partial mutation behind on failure. Temporary validation followed by a successful swap avoids exposing that partial state; enqueueing recovery before marking state stale avoids a failed enqueue leaving stale state without recovery in flight. (src: zero-copy-decode-refactor-verification, 2026-08-03)

## Benchmark evidence and fast paths

- Fewer owned strings is an allocation claim, not a latency claim. In a source-reported measurement, a borrowed single parse improved while an extra parse led to a 38–76% end-to-end regression; this is evidence that pipeline shape matters, not a default effect size. (src: zero-copy-decode-refactor-verification, 2026-08-03)
- Does each compared pipeline shape include send, receive, and drop when ownership/deallocation is part of the proposed savings? Decoder-only timing omits costs that can decide a channel refactor. (src: decode-refactor-benchmarking, 2026-08-04; serde-borrow-and-json-bench-traps, 2026-08-03)
- Pretty-printed fixtures do not represent compact wire input, and serde_json::Value round-trips sort object keys by default (its map is a `BTreeMap` unless `preserve_order` is enabled). Key-order-sensitive fast paths can therefore stop engaging; captured wire bytes and a positive fast-path assertion make benchmark inputs interpretable. (src: decode-refactor-benchmarking, 2026-08-04; serde-borrow-and-json-bench-traps, 2026-08-03)
- A one-sided prefix classifier that positively recognizes the hot layout and sends unknown layouts through full decoding can trade speed on unfamiliar frames without changing their correctness. A mistaken negative or misclassification can instead drop valid traffic. (src: zero-copy-decode-refactor-verification, 2026-08-03; decode-refactor-benchmarking, 2026-08-04)
- Criterion quick-mode point estimates are direction-setting, not strong performance evidence; full estimates and confidence intervals are more informative. (src: decode-refactor-benchmarking, 2026-08-04; serde-borrow-and-json-bench-traps, 2026-08-03)
