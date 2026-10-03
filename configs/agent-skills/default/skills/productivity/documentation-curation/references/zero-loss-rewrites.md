# Zero-Loss Rewrites

Scope: Choose conservation evidence that matches whether a rewrite is an isomorphic restyle or an additive expansion.

## Conservation contracts

- For an isomorphic restyle, numeric-token and domain-identifier multisets should be conserved; for an additive expansion, original numeric tokens must remain, while newly added numbers are expected. These are different proof contracts. (src: data-preserving-doc-rewrite; 2026-07-13; spec-to-textbook-expansion; 2026-07-25)
- Numeric normalization can hide a changed value or create false count differences. Critical values benefit from positive checks as well as token-count comparisons, and normalized-key counts need accumulation when multiple spellings collide. (src: data-preserving-doc-rewrite; 2026-07-13; spec-to-textbook-expansion; 2026-07-25)
- For a restyle, byte-identical headings preserve anchors and cross-references; an expansion may renumber headings, but then references to original sections need an explicit mapping. (src: data-preserving-doc-rewrite; 2026-07-13; spec-to-textbook-expansion; 2026-07-25)
- Rewriting does not silently resolve contested options or turn the source into a newer decision. When a document overwrites its own source, self-citations need to identify the original source version rather than rely on line numbers in the rewritten file. (src: spec-to-textbook-expansion; 2026-07-25)

## Markdown structure

- GitHub Flavored Markdown requires a blank line before a table for reliable table rendering; literal escaped pipes in cells must not be mistaken for structural separators. (src: data-preserving-doc-rewrite; 2026-07-13)
