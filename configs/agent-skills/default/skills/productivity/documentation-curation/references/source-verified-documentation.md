# Source-Verified Documentation

Scope: Make checkable documentation claims auditable and catch both fabricated claims and omissions in the claim accounting.

## Claim verification

- A claim ledger turns checkable prose into auditable claims but is not exhaustive evidence by itself; unlisted assertions may also be inaccurate. (src: verified-documentation-fanout; 2026-08-06)
- An adversarial finding is a hypothesis, not a correction until the person repairing the text independently verifies it against source; rejected findings need evidence too. (src: verified-documentation-fanout; 2026-08-06)
- Relative Markdown links resolve from the directory containing the document, not from an assumed repository root; plausible-looking parent-directory depth can still be wrong. (src: verified-documentation-fanout; 2026-08-06)
- Repeatedly introducing new errors during revisions can signal repair churn rather than convergence; a bounded repair effort followed by independent examination is safer than endless rounds. (src: verified-documentation-fanout; 2026-08-06)
- When drafting result tables from JSON receipts, round each cell once from the full-precision value: hand-rounding 7-decimal printouts to 6 decimals produced wrong cells (a printout of -0.0001655 re-rounds to -0.000166, while the full-precision value rounds to -0.000165). Claims review of the same draft also caught a proxy reported as a bound, gate-coverage overstatements, and receipt-binding overstatements. (src: receipt-table-rounding, 2026-10-04)

This reference is limited to source-grounded documentation claims and the links needed to verify them. (src: verified-documentation-fanout)
