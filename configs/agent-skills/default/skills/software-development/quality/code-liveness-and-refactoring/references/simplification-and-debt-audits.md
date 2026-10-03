# Simplification and debt audits

Scope: taxonomy drift, simplification overclaims, and gaps between operational components and their validation surfaces.

## Taxonomy and dispatch

- Are two literal enumerations truly equal? What do the two set differences show before either list is called redundant? (src: duplicated-taxonomy-enumeration-audit, 2026-08-23)
- Could class-driven dispatch turn an unknown value's silent admission drop into a hard failure? Is there a census of observed values through the classifier before changing that contract? For substring-based classifiers, branch order and stable entity IDs can change classification or make name variants appear to be mismatches. (src: duplicated-taxonomy-enumeration-audit, 2026-08-23)
- Do mutually exclusive dispatch counts sum to the admitted total on real data? A test fixture alone may miss uncovered categories or overlapping branches. (src: duplicated-taxonomy-enumeration-audit, 2026-08-23)

## Package simplification

- Is a second registry actually an independent enumeration, or is it derived from the first and then extended? The latter is split ownership; is the divergence quantified rather than treated as a blind merge? (src: readonly-package-simplification-audit, 2026-09-11)
- Does an intermediate representation have another consumer, such as a fitting or statistics pass? If so, it is not redundant merely because one round trip appears unnecessary. (src: readonly-package-simplification-audit, 2026-09-11)
- Does an exported symbol lack only an in-repository production caller, or is it truly unused? Repository search cannot rule out external consumers of a public API. (src: readonly-package-simplification-audit, 2026-09-11)
- Do similar vendor vocabularies derive from different source columns? Similar strings do not establish equivalent meaning; a typed kind at the parsing boundary may expose the distinction better than merged raw-string maps. (src: readonly-package-simplification-audit, 2026-09-11)
- When assessing whether a refactor is harmless, which lenses apply: reuse, redundant state, parameter sprawl, repeated logic, leaky boundaries, stringly-typed values, excess work, unbounded memory, or swallowed errors? Does history or blame explain why a candidate exists? Uncertain intent weakens a removal claim. (src: simplify-code)
- Is the change behavior-neutral, semantics-preserving, or a public-contract change? Public API, route, database, and config-key renames carry consumer risk; semantics-preserving refactors need verification, while behavior or contract changes warrant human review. (src: simplify-code)
- Does the complete diff reveal cross-file reuse or performance interactions that a fragment hides? A cleanup finding should identify a material improvement, not merely style or line-count reduction. (src: simplify-code)

## Infrastructure validation surface

- Does the actual CI, Make, or validation invocation graph run the tests that exist on disk? Inventory alone is not coverage evidence. (src: infra-repo-tech-debt-audit, 2026-08-23)
- Is every deployment-critical component represented in render, validate, diff, and CI surfaces? Otherwise it can escape all pre-apply gates. (src: infra-repo-tech-debt-audit, 2026-08-23)
- Are issue references in gate comments still current, and do scripts still point to existing manifest paths? These references can decay silently. (src: infra-repo-tech-debt-audit, 2026-08-23)
