# Capturing a completed reviewer's JSON verbatim

Scope: a completed read-only review needs durable evidence, typically after a requested report file was never created or JSON parsing fails near the display line-length limit.

## Procedure

1. A requested output path is intent, not evidence of a saved file. omp's read-only reviewer roles may have no write tool. Ask for a strict JSON completion and let the parent persist it.
2. Read the completed agent output with the `:raw` selector. A normal read adds line prefixes and can truncate long lines, so its display payload is not a safe JSON transport (one observed failure was an invalid control character near column 770).

   ```python
   result = await tool.read({
       "i": "Reading verbatim completed review",
       "path": f"agent://{reviewer_name}:raw",
   })
   raw = result["text"]
   review = json.loads(raw)
   assert isinstance(review["findings"], list)
   assert isinstance(review["verified"], list)
   ```

3. Write `raw` exactly, with the parent's `write` tool, to an explicit shared artifact path. Do not hand-transcribe findings or round numbers, and do not assume a child saved a `local://` report. Record reviewer identity, the reviewed draft's SHA-256 and the saved output's SHA-256 separately.
4. When recovering after a failed batch, earlier iterations may already have written files: reuse an existing destination only after exact byte equality, otherwise stop or choose a separately named attempt. Never overwrite a conflicting immutable receipt.
5. Recover the already-completed output instead of repeating the audit or model run. If the underlying draft actually changed, request a bounded delta review.

## Boundaries

- Use `result["text"]` from the raw read; `details.displayContent` is a structured display object and may hold a truncated representation.
- Capturing a report is not accepting its findings or a numerical PASS. Preserve failed gates and adjudicate against primary receipts.
- If the verbatim output is itself malformed JSON, request a formatting-only follow-up from the idle reviewer; never repair substantive content by guesswork.
