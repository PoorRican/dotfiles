# Source Adjudication

Scope: Adjudicate document claims against their relevant source, then distinguish genuine loss from movement, paraphrase, or obsolete content.

## Which claim is true?

- Prose quality, detail, and recency do not establish correctness; either version may be stale, or both may be wrong. If neither states the mechanism supported by current evidence, the right result is new wording rather than a compromise. (src: doc-version-source-adjudication; 2026-08-23)
- Implementation state and deployed state are different claims: source shows what the code does, while deployment pins or manifests establish what has shipped. One cannot substitute for evidence of the other. (src: doc-version-source-adjudication; 2026-08-23)
- A failed search does not prove an item is absent. Absence claims need positive enumeration of the relevant source surface, such as the complete members or variants where the item would appear. (src: doc-version-source-adjudication; 2026-08-23)
- Omission is not contradiction: a document may leave a mechanism unstated when an authoritative source elsewhere owns that claim. Correction of false assertions need not manufacture disagreement from silence. (src: competing-doc-version-adjudication; 2026-08-23)
- A source citation without a verifiable supporting location leaves its claim unsettled; such a claim is explicitly unverifiable. (src: doc-version-source-adjudication; 2026-08-23)
- Cross-document contracts can be stale at both ends: producer and consumer documentation may each describe an old mechanism, so the current behavior may be named in neither. (src: doc-version-source-adjudication; 2026-08-23)

## Did a rewrite lose material?

- A repo-wide comparison can catch valid details moved between files during consolidation; per-file absence can mistake relocation for loss. (src: superseded-rewrite-loss-audit; 2026-08-23)
- Exact-string absence after paraphrase is not conceptual loss. Any possible restoration needs source verification because the superseded version can preserve a detail while making other false claims. (src: superseded-rewrite-loss-audit; 2026-08-23)
- Superseded work that may contain genuine losses remains recoverable until those losses are adjudicated; another person's unfinished rewrite is not disposable. (src: superseded-rewrite-loss-audit; 2026-08-23)
