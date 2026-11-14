# Curation and preservation

## Adjudicate claims

- Check competing versions against evidence for the specific claim; neither version may describe the current mechanism. Omission is not contradiction.
- Implementation and deployment are different claims: source code shows implemented behavior, while deployment pins or manifests establish what shipped.
- A failed search alone does not establish absence. Enumerate the relevant source surface where the item would appear. Mark claims with no verifiable supporting location as unsettled.
- A claim ledger can help organize checks, but it does not cover assertions omitted from the ledger. Verify review findings against the source before accepting or rejecting them.
- If neither version states the mechanism supported by current evidence, write new wording rather than compromise between stale claims. Keep superseded work recoverable until possible genuine losses are adjudicated.
- Repeatedly introducing new errors during revisions can signal repair churn rather than convergence; bound the repair effort and seek independent examination.

## Rewrite without changing meaning

- Compare against the original across the whole document set: a detail may have moved or been paraphrased rather than lost. Verify a proposed restoration against current evidence; the original can also be wrong.
- Numeric and identifier counts can flag omissions, but matching counts do not prove preservation: check critical values in context, including their row associations and nonnumeric claims. Normalization can hide changed values or produce misleading counts.
- Match checks to the task: an expansion can legitimately add values, while a restyle may consolidate repetition. Account for intended differences rather than treating exact token equality as proof.
- For a data-dense rewrite, snapshot the original before editing. If splitting work across sections, use disjoint section files, have each worker read its source rather than reconstruct cells from a plan, then reassemble and verify globally against the snapshot.
- Compare numeric-token and domain-identifier multisets in both directions for a restyle; investigate differences against the source and account for intentional deduplication or tokenization artifacts. For an additive expansion, expect new tokens but check that original values remain. Accumulate counts when normalized spellings collide, and positively check critical values: matching counts alone cannot establish correctness.
- When drafting result tables from receipts, round each cell once from the full-precision value rather than re-rounding a printed approximation.
- Preserve contested options and non-claims rather than silently turning them into decisions. If headings change, update affected anchors and cross-references; when overwriting a source, identify its original version rather than citing rewritten line numbers.
- For reliable GitHub Flavored Markdown table rendering, leave a blank line before a table. Check each table block for consistent structural pipe counts and a separator row.
- When converting tables, check that escaped literal pipes are not counted as column separators and inspect high-risk transpositions and splits against the original.

## Change contracts and consolidate records

- A contract change can leave stale assertions in tables, sibling prose, or citing documents. Search old vocabulary, then distinguish current assertions from accurate negations, historical accounts, and retirement notices.
- Records with different levels of detail can be combined only when their evidence boundaries remain intact; distinct mechanisms or consumer guidance may warrant distinct entries. Retain large raw-evidence sidecars as links rather than embedding bulk.
- Preserve chronology, evidence boundaries, deliberate non-claims, and links to raw evidence when combining records. For an append-only log, follow its correction convention rather than silently rewriting a closed entry.
- Compare entry identity and body, including superseded variants and causal order; counts or sorting alone cannot establish that conflicting records were preserved. Update indexes and cross-references when retiring absorbed copies, while preserving historical citations.
