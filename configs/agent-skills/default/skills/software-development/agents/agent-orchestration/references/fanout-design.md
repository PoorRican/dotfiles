# Fan-out Design

Scope: interface and ownership facts for parallel implementation, committed-system audits, and shared review context.

## Shared contracts and dependency boundaries

- Freezing shared signatures, types, and invariants before dispatch reduces interface drift; later waves can build on verified interfaces and runtime behavior rather than assumptions from a skim. (src: contract-first-parallel-implementation)
- Distinct work boundaries matter more than worker count: concurrent writers are safer when file ownership does not overlap, and useful handoffs name scope, neighboring interfaces, and an observable result. (src: writing-plans; src: subagent-driven-development)
- Generated enum member identifiers need not equal their wire values. In Pydantic, `use_enum_values=True` can leave a field read back as `str`, making identity checks against enum members fail; these details matter to runtime/type contracts rather than naming assumptions. (src: contract-first-parallel-implementation; source 2026-09-01)
- A `StrEnum` member whose name shadows a method inherited from `str` (for example, `partition`) can fail type checking; generated member names need checking against language and type-checker behavior. (src: contract-first-parallel-implementation; source 2026-09-01)
- Importing a generated submodule still initializes its package: module-scope imports from that package's `__init__` back into a core module can create a transient import cycle. (src: contract-first-parallel-implementation; source 2026-09-01)
- A test that compares a hard-coded value to itself is tautological; it does not establish the intended behavior. Production-shaped captured input parsed through the production model is stronger evidence that both the input and behavior match reality. (src: parallel-correctness-audit-with-proving-tests; source 2026-08-06)
- A plausible default or configuration field may be inert if no executed path consumes it. Which runtime anchor reads it, and does that path act on the result? (src: parallel-correctness-audit-with-proving-tests; source 2026-08-06)

## Audit evidence

- For an already-committed correctness question, evidence varies in directness: live API behavior, sibling reference implementation, captured fixture, documentation, then inference. Reports distinguish which claims were executed or traced from those inferred. (src: parallel-correctness-audit-with-proving-tests; source 2026-08-06)
- Correctness audits of existing behavior and reviews of a branch diff answer different questions. A refuted suspicion is useful audit evidence too; a report containing only confirmations can reflect confirmation bias. (src: parallel-correctness-audit-with-proving-tests; source 2026-08-06)
