# Exact-model analysis in omp

Scope: an evidence-bound, read-only analysis when the user explicitly names a model role. Do not silently substitute a familiar model or a helper's `slow` alias for the named role.

## Resolve the requested role

1. Resolve the current configured binding and effort for the named role. Read configuration only because the user asked for that role; never change or persist their settings.
2. Check which model arguments the executor accepts. Some completion helpers accept only `default`, `smol` and `slow`, not arbitrary role names, and those aliases are not proof the requested role will run. Prefer an executor that supports the exact resolved binding.
3. If no helper can execute the role, a standalone omp CLI call can run the resolved model for read-only text analysis. Use a call-local config that disables fallback so a successful process cannot conceal substitution.

## Standalone read-only runner

Use the resolved model id and effort, not the role name:

```text
omp --print --mode json \
  --model <resolved-model-id> --thinking <resolved-effort> \
  --no-session --no-tools --no-lsp --no-extensions --no-skills --no-rules \
  --no-title --no-prewalk \
  --config <call-local-config.json> \
  --system-prompt '<evidence-bound analysis instructions>' \
  @<focused-prompt.txt>
```

The stripped context fits only this isolated text-analysis runner: supply the needed contracts in the evidence packet and forbid repository edits and compute submissions. It is not a pattern for stripping guidance from a coding or operations agent.

A call-local config that disables fallback and auto-memory:

```json
{
  "advisor": {"enabled": false},
  "autolearn": {"enabled": false},
  "hindsight": {"autoRecall": false, "autoRetain": false},
  "retry": {"modelFallback": false}
}
```

Check current CLI and config support rather than assuming these keys remain valid. Run independent slices concurrently, in an execution mode that accommodates the requested effort; distinguish an executor timeout from model completion.

## Prepare complete, focused evidence

- Design independent slices before launching them; separate claims that genuinely have different evidence contracts (representation or readout, intervention or control, source or architecture).
- Give each slice compact derived metrics with units, sign conventions, valid populations, control availability and exact source pointers, not raw arrays or checkpoints loaded just to fill a prompt.
- Ask each slice to resolve specific questions and alternatives rather than recatalogue a whole numeric grid. Narrowing the question must not silently drop any requested analysis domain.
- A broad packet can spend its output on reasoning and never produce a complete visible answer. A partial visible answer or a thinking-only turn is not a completed slice.

## Verify what actually completed

Count an analysis only with a receipt derived from the response events, retained with the executed prompt, exit status and visible final answer. Check that:

- provider and model match the resolved binding;
- the recorded request effort matches the requested effort;
- the process exited successfully;
- final answer text exists, normal completion and the agent-end event were recorded;
- no model fallback occurred.

Do not infer identity from the command line. Response metadata verifies the recorded runtime identity and requested controls, not model weights or reasoning quality; if identity cannot be observed, say so. Never quote or publish hidden reasoning: extract only visible answer text and necessary runtime metadata. Label incomplete attempts and do not count them.

## Integrate without laundering model claims

- Preserve executed prompts and completed model answers as immutable evidence, hash both, and correct unsupported claims in a separate adjudication record, never by rewriting what the model returned.
- Independently check consequential numbers, signs, units, populations, control applicability and source-contract assertions. Audit recommendations need adjudication too: a reviewer can correctly spot an ambiguity while proposing an unsupported remedy.
- Label inference separately from measurement, and say whether checks used compact artifacts or reproduced raw arrays.
- Record the completed scope, the work not performed and any unrelated failure explicitly. Remove unexecuted scratch prompts; never delete authentic executed inputs or failure evidence as cleanup.
- A completed interim analysis is not a final study audit, a verdict, an owner interpretation or authorization for new compute.
