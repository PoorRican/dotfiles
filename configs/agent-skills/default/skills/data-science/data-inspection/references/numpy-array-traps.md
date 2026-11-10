# NumPy array traps

Scope: dtype behaviors that silently change values, keys, or comparisons in NumPy-based pipelines and gates.

## Fixed-width string dtypes

- `np.full(n, "776135", dtype="U")` allocates `U1` and silently truncates every value to its first character. When all identifiers share a leading digit, every row gets the same key. One run only noticed when a key index raised "duplicate keys" after a 30-minute full pass, and a generic exception handler then recorded the run as blocked. Use `dtype=f"U{len(s)}"` or plain `np.full(n, s)`. (src: numpy-dtype-traps; 2026-09-23)
- A one-identity smoke path that never builds the key index cannot catch this. Add a regression test in which two different identities produce distinct keys, and make every smoke path exercise the same key and pairing code as the full run. (src: numpy-dtype-traps; 2026-09-23)
- Structured arrays with `S` (bytes) fields return `bytes`, so `row["kind"] == "event"` is never true; compare with `b"event"` or decode first. (src: numpy-dtype-traps; 2026-10)

## Boolean arrays

- `np.allclose` and subtraction on boolean arrays raise `TypeError` (NumPy has no boolean subtract). A parity gate that wrapped the comparison in a generic handler recorded those columns as "differs" with a null maximum difference, even though a direct comparison found no mismatches. Cast to an integer type or compare with `==`/`np.array_equal`, and treat "comparison failed" as an instrument defect, not a data verdict (see the verification skill's instrument-trust reference). (src: numpy-dtype-traps; 2026-10)
