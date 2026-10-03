# Append-only Record Consolidation

Scope: Preserve the meaning, chronology, and evidence network when records move into a canonical append-only log.

## Meaning and chronology

- Preserve deliberate non-claims and adjudication boundaries as well as positive findings; dropping them can make the log imply certainty or erase a refutation. (src: scattered-records-to-append-only-log)
- In an append-only log, a heading date identifies event onset; a correction is a new dated entry linked to the superseded entry, not a rewrite of the closed entry. (src: scattered-records-to-append-only-log; 2026-09-19)
- Records with different levels of detail can be combined only when their evidence boundaries remain intact; distinct mechanisms or consumer guidance may warrant distinct entries. (src: scattered-records-to-append-only-log)

## Evidence and cutover

- Retain large raw-evidence sidecars and link them from the log rather than obscuring the record with embedded bulk. (src: scattered-records-to-append-only-log)
- A consolidation is incomplete while indexes, citations, or cross-references still point to absorbed copies. Preserve historical citations and retire only copies actually absorbed into the log; a log cutover is a reference-network change, not simply a content merge. (src: scattered-records-to-append-only-log)
- An external wiki can retain its narrative while pointing readers to the canonical log with a concise pointer. (src: scattered-records-to-append-only-log)
