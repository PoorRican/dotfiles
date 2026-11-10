# Bounded API collection

Scope: inspect paginated responses without mistaking a sample for a complete population.

- Bound selected records, request timeouts and response bytes. Parallelize only independent reads and do not bypass an access refusal. (src: bounded-api-collection; method)
- Preserve actual responses and per-record machine-readable reports in scratch. Inspect pagination metadata, follow pages as needed, reconcile reported counts with collected items, and aggregate reports programmatically. Scratch is staging, not published evidence. (src: bounded-api-collection; method)
- Report sample success separately from qualified population coverage; a missing match in one listing alone does not prove that no historical record exists. (src: bounded-api-collection; method)
