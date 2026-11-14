# Model and output receipts

## Exact-model analysis

When a user names a model role, resolve its current configured binding and effort without changing their settings. Some completion helpers accept only `default`, `smol` and `slow`, not arbitrary role names; those aliases do not prove the requested role will run. Prefer an executor that supports the exact resolved binding.

If no helper can execute the role, a standalone OMP CLI call can run the resolved model for read-only text analysis. Check current CLI and config support; use a call-local config that disables fallback so a successful process cannot conceal substitution:

```text
omp --print --mode json \
  --model <resolved-model-id> --thinking <resolved-effort> \
  --no-session --no-tools --no-lsp --no-extensions --no-skills --no-rules \
  --no-title --no-prewalk \
  --config <call-local-config.json> \
  --system-prompt '<evidence-bound analysis instructions>' \
  @<focused-prompt.txt>
```

```json
{
  "advisor": {"enabled": false},
  "autolearn": {"enabled": false},
  "hindsight": {"autoRecall": false, "autoRetain": false},
  "retry": {"modelFallback": false}
}
```

The stripped context fits only this isolated text-analysis runner: supply the needed contracts in the evidence packet and forbid repository edits and compute submissions. It is not a pattern for stripping guidance from a coding or operations agent. Distinguish an executor timeout from model completion; a partial visible answer or a thinking-only turn is not a completed slice.

The command line alone does not prove which model ran. Retain the executed prompt, exit status and visible answer; check response events for provider and model, recorded request effort, final visible text, normal completion and the agent-end event, and absence of fallback. Metadata establishes reported runtime identity and requested controls, not model weights or reasoning quality; if identity cannot be observed, say so. Do not publish hidden reasoning. Independently check consequential claims against their sources.

## Capture completed reviewer JSON

1. A requested output path is intent, not evidence of a saved file. OMP's read-only reviewer roles may have no write tool. Ask for a strict JSON completion and let the parent persist it.
2. Read the completed agent output with the `:raw` selector. A normal read adds line prefixes and can truncate long lines, so its display payload is not a safe JSON transport. Use the actual raw text payload rather than a structured display representation; parse it as JSON and check the expected fields. Tool response object shapes are runtime-specific.
3. Write the raw text exactly with the parent's write tool to an explicit shared artifact path. Do not hand-transcribe findings or round numbers, and do not assume a child saved a `local://` report. For durable audit receipts, record reviewer identity and hashes of the reviewed draft and output separately.
4. When recovering after a failed batch, earlier iterations may already have written files: reuse an existing destination only after exact byte equality, otherwise stop or choose a separately named attempt. Never overwrite a conflicting immutable receipt.
5. Recover the already-completed output instead of repeating the audit or model run. If the underlying draft actually changed, request a bounded delta review. If the verbatim output is malformed JSON, request a formatting-only follow-up; never repair substantive content by guesswork.

Capturing a report is not accepting its findings or a numerical PASS. Preserve failed gates and adjudicate against primary receipts.
