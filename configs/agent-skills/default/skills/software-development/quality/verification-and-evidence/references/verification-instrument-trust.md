# Verification instrument trust

Scope: recognize green results that come from an unrun, mis-scoped, corrupted, or non-reproducible verification instrument.

## Did the check run and observe the claim?

- A filtered test can exit successfully with zero tests; runner status alone is insufficient without a non-zero executed count. Pipelines can mask or manufacture aggregate status, and `grep -c` may return 1 for no matches under `set -e`; individual gate exit statuses are more informative than a final token. (src: false-green-verification-traps, 2026-08-12; mutation-proved-gate-evidence, 2026-09-05)
- A narrow search or empty query is weak evidence for absence: whitespace-specific searches and predicates can miss present variants. Absence claims are stronger when based on positively enumerated matches, values, or populations. (src: false-green-verification-traps, 2026-08-12; failclosed-gate-empty-result-diagnosis, 2026-08-25)
- A Docker interpreter reading a heredoc from stdin can execute nothing and exit zero if Docker did not attach stdin; the `-i` option belongs before the image name. Tests of copied inner code also miss shell expansion in the actual generated payload. (src: docker-heredoc-test-execution, 2026-08-21)
- A CLI stub directory left on persistent `PATH` can shadow the real executable; an unhandled command that exits zero with empty output creates plausible false results. Stub resolution is part of the test boundary. (src: cli-stub-branch-verification, 2026-08-19)
- For a fail-closed control loop, absent/empty state, CLI/API errors, missing configuration, and valid-but-stale state can be confused with health. A stale last-known-good file can leave a dead prober looking healthy; repeated unchanged inputs should not cause repeated writes, and freshness timestamps need to advance as the real writer would. (src: cli-stub-branch-verification, 2026-08-19)

## Mutation evidence and safe restoration

- Did the mutation anchor match exactly once, and did the named behavioral test fail for its intended assertion rather than because the program stopped compiling? A no-op mutation tests pristine code; a compile error tests the build, not the invariant. Mutation evidence supports only the property touched by that mutation. (src: false-green-verification-traps, 2026-08-12; mutation-proved-gate-evidence, 2026-09-05; mutation-verified-guarantees, 2026-08-12)
- A pre-mutation working state is a safety precondition: `git checkout -- <file>` restores `HEAD`, not the file's previous dirty contents. It is appropriate only when a clean-tree or checkpoint baseline protects the work; otherwise exact pre-mutation bytes need to be preserved and verified. Restoration and a green rerun are part of the evidence. (src: safe-shell-mutation-testing, 2026-08-23; false-green-verification-traps, 2026-08-12; mutation-verified-guarantees, 2026-08-12)
- A mutation that produces many unrelated failures may have broken the harness or targeted the wrong code, not proved broad coverage. (src: safe-shell-mutation-testing, 2026-08-23)

## Coverage and provenance after change

- A green suite cannot reveal deleted tests or checks. Comparing collected tests by behavior name and checking collection-error counts on both sides makes a test-surface comparison interpretable; a shared editable install can otherwise point the old tree at new source and hide lost coverage. A behavior that changed from raising to warning is not equivalent coverage merely because a replacement check exists. (src: green-suite-blind-spot-audit, 2026-09-04; committed-tree-gate-verification, 2026-09-02)
- A gate may pass only because untracked files exist locally or because a comparison checkout shares an editable install. A clean checkout of the target commit is the relevant reproducibility surface. (src: committed-tree-gate-verification, 2026-09-02)
- For an already-executed script, the executed-copy hash and later committed-copy hash describe different artifacts. Formatting or lint edits do not retroactively change what produced the result; a correction to report text should be distinguished from unchanged computed values. (src: executed-script-lint-provenance, 2026-09-29)
- AST comparison can support a semantics-preserving edit claim only when allowed edit kinds are classified, import side effects are considered, and string-literal values are checked. A post-run correction to report text is distinct from a change in computed values. (src: executed-script-lint-provenance, 2026-09-29)
