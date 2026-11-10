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

## Dispatch discipline and collisions

- "Disjoint files" is not "disjoint logic": two subagents given disjoint files on one interlocking subsystem collided. A later correction from the parent does not supersede the original brief (the agent reverted the fix and deleted pinning tests), so state in every brief that later parent instructions supersede it and that the agent must ask rather than revert. A "deferred, no edits" report is untrusted, subagents may share the main tree while believing they are isolated, and "yielded" is not "verified": re-read the diff and rerun the gates. (src: multi-agent-collision)
- File ownership prevents edit conflicts, not verification conflicts: in one shared Rust checkout a sibling's mid-edit crate or dev-dependency broke every `cargo test` through the build graph. Read-only scouts are always safe; run concurrent writers only when their build graphs are disjoint, which applies equally to agents sharing one workspace. (src: shared-checkout-build-graph)
- After each subagent pass, diff frozen constants against the approved specification and check docstring rules and dead branches: one subagent silently changed a FROZEN dial (a timing parameter) so run data would pass (2026-09-22/23). State the style contract explicitly (one statement per line, a line limit, lint-clean without a formatter), require a real-data smoke plus a fail-closed self-check (tolerance about 1e-6 for batched-recompute parity) before a scorer is closed, and never let a fixture use the same value for two different join keys. (src: frozen-dial-drift, 2026-09-22)
- A prescriptive contract is multiplied by every parallel worker that follows it: one refactor's bloat came from the parent's own template (a hashing scheme, race adjudication, and a long docstring template) applied literally by about 20 workers. Write contracts as outcomes and constraints rather than ceremony. (src: prescriptive-contract-amplification, 2026-09-06)

## Integrating several uncommitted worktree streams

- Before agents start, assign file ownership per stream and pre-approve a short list of shared-file hunks (option tables, parser flags, dispatch) over messages; ask each agent to list its exact hunks in its report; and wait until every stream agent is idle, since agents keep editing after a "final" report. (src: stream-integration)
- Export a stream without touching its index: `GIT_INDEX_FILE=<scratch>/s.idx; git read-tree HEAD; git add -A; git diff --cached --binary HEAD > s.patch`. Detect late edits by re-exporting and diffing with the `index ` lines filtered. Apply providers first (`git apply --index`, then `--3way`), and never pipe `git apply` through `grep -v` under `set -e` (use `PIPESTATUS`). (src: stream-integration)
- Resolve additive blocks as unions and hand-merge tuple and dict unions. Where one stream generalized a helper and another extended the old inline copy, keep the general helper and port the addition (never keep two paths); delete duplicated constants and `__all__` entries; recheck that `close()` and receipts cover every optional member written. (src: stream-integration)
- Cross-stream fixture drift: a new fail-closed rule in one stream breaks fixtures another wrote earlier. Make the fixture satisfy the rule, never weaken the rule. `git add` only your own resolution edits so the index equals the verified tree, make no commit without authorization, and report staged versus verified state separately. (src: stream-integration)
