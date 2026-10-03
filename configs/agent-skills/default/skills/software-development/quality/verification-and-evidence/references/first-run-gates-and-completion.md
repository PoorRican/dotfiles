# First-run gates and completion

Scope: interpret empty or never-passing gates without mistaking a predicate/plumbing defect for absent data or completed work.

## Empty and vacuous gates

- An empty fail-closed result cannot distinguish absent data from data excluded by the predicate. In SQL, `NULL = 'x'` is not true, and universal checks over an empty set can pass vacuously; literal conjuncts and discriminating values, including `NULL`, determine whether an upstream explanation is supported. (src: failclosed-gate-empty-result-diagnosis, 2026-08-25)
- Apparently comparable gate values can describe different populations: a filtered count and unfiltered count can make a gate impossible by construction. Diagnosis depends on comparing both definitions and values. When an insert-only field needs correction, reproducing rows may be required instead of an in-place update; previewing the next downstream check distinguishes a repair from moving the failure. Non-monotonic partition patterns can indicate partial migration or reprocessing rather than global absence. (src: failclosed-gate-empty-result-diagnosis, 2026-08-25; first-run-path-gate-chain, 2026-08-27)
- Does an exact extreme such as zero coverage mean genuine population loss, a denominator/construction defect, or universal undecidability? A gate that has never passed leaves every downstream stage unexercised; independent serial defects may surface one after another. A first local green is not end-to-end completion. (src: unexercised-gate-defect-sweep, 2026-08-13; first-run-path-gate-chain, 2026-08-27)
- In a worker-backed pipeline, “no output” may hide Pending/configuration failure, a terminated worker, or a launcher that ran inline instead of creating a worker. A phase-only Running filter and absent resource requests can conceal failure reasons; producer/consumer receipt contracts may expose incomparable populations behind a fail-closed gate. (src: first-run-path-gate-chain, 2026-08-27)
- Could a zero coverage/extreme value be a construction defect rather than a real population count? All-`None` optional columns may infer a `Null` schema and fail when values later appear; explicit schemas prevent the inference artifact. Matching regenerated content digests can show that a repair changed provenance/plumbing without changing the population. (src: unexercised-gate-defect-sweep, 2026-08-13)

## Completion evidence

- Implementation, exercise, and blockage are distinct completion states. Implementation without a named test, acceptance case, or receipt is not evidence that the behavior was exercised; a blocked claim needs a live blocking fact. (src: plan-item-completion-audit, 2026-09-13)
- Reproducible verification requires more than an ephemeral `/tmp` script: preserving the instrument and rerunning the committed copy closes the provenance gap. A dependency-isolation probe is informative only if a positive control shows that its blocker can fire. (src: plan-item-completion-audit, 2026-09-13)
- Zero consumers in the current repository does not prove an exported symbol is unused if another repository consumes the shared interface. (src: plan-item-completion-audit, 2026-09-13)
