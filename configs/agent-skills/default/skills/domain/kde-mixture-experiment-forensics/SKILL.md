---
name: kde-mixture-experiment-forensics
description: "Forensic checklist for reviewing local/matchup-level KDE or kernel-mixture density experiments (SEAM-style, conditional spray/density heads) whose local model loses to a pooled marginal baseline or shows a null conditioning effect"
---

# KDE / kernel-mixture experiment forensics

Use when a matchup-level or locally-conditioned kernel density model (SEAM-style three-source mixture, conditional KDE head) underperforms a pooled marginal baseline on held-out NLL, or a conditioning variable shows a null effect, and you must decide whether the result is signal absence or estimator artifact.

## Symptom → suspect map

- **Bandwidth grid optimum pinned at the cap / monotone validation surface** → base bandwidth scale mismatch. Check what `n` feeds the Scott/Silverman rule vs. the size of the supports the bandwidth is *applied* to. `h = sigma * N_pooled^(-1/6)` applied to n-point local supports is undersmoothed by factor `(n/N)^(1/6)`; a multiplier grid capped at m can only recover supports with `n >= N * m^-6`. Compute the actual support-size census (median/p90/p99 per query key) before trusting any bandwidth conclusion.
- **Local model loses to pooled marginal** → check for missing shrinkage. If fallback to a pooled/canonical density fires only at exactly-zero ESS, thin-but-nonzero supports get spiky local mixtures with no backstop; sqrt(n)-style source weights give one-point kernels large mass. The fair fight requires an ESS-based blend `lambda(ESS) * f_local + (1-lambda) * f_pool`.
- **Conditioning variable shows null effect (model-with ≈ model-without)** → variance domination. If the conditioning kernel width is far below the covariate's dispersion AND supports are tiny, conditioning is nearest-neighbor reweighting = pure variance; validation selecting the weakest localization is what variance domination produces regardless of true signal. A null here is weak evidence about the covariate.
- **Donor/similarity weighting suspiciously flat** → check the distance transform. `(sum sq diffs)^(1/d)` with d = feature count compresses distances toward 1 → `exp(-d)` similarities near-constant. Also check: scaling fitted globally vs. within the comparison pools; unshrunk single-observation profile rows; ESS computed from raw similarities while the density uses renormalized ones.

## Review procedure

1. Read the design/prereg doc first; classify each finding as design-level (carried through faithfully) vs implementation bug. Implementation verdicts are not family verdicts.
2. Fan out parallel read-only scouts by subsystem: data build/SQL/splits; coordinate transform/target/Jacobian; profiles/similarity; kernel/mixture mechanics; bandwidth selection/baselines/evaluation. Give each the headline anomalies to explain and require line-cited findings ranked definite-bug / methodological-flaw / needs-verification.
3. Independently verify scout arithmetic against persisted artifacts (state.json bandwidths, manifests). Back-imply sigma from stored bandwidths (`sigma = h * N^(1/6)`) and compare to a direct IQR/1.349 computation on the frames — catches both wrong-scale bugs and "multiplier already baked into persisted state" misreads.
4. Run your own support-size census from the persisted frames (group-by the query key, quantiles of n). This one query usually settles whether the local model ever had data to work with, and whether any pre-registered per-matchup eligibility threshold (e.g. n>=10) was attainable in the test window.
5. Fairness table across arms: data pooled/conditioning key, bandwidth rule, who got validation-tuned. Asymmetric tuning in the losing model's favor makes the loss conservative-robust.
6. Name the missing diagnostic if loss cannot be localized (e.g. NLL binned by exact-support size) — often the cheapest decisive follow-up.

## Cheap fixes to propose before escalating model families

- Per-support bandwidth: `h = sigma_type * n_support^(-1/6)` (or CV within support-size bins).
- ESS-gated shrinkage of the local mixture toward the canonical/pooled density.
- Rerun on the same data with only these changes to test whether the local signal exists at all — far cheaper than a new model family.
