# Claim-rule calibration

Scope: calibrating a clustered-interval claim rule by simulating its null before the rule is frozen, so the stated significance level can be trusted.

## Calibrate the rule by simulating its null

- Before freezing a rule such as "one-sided 2.5% on a date- or unit-clustered interval", redraw every outcome at its traded probability (a Bernoulli draw with the entry price as probability) so each position has zero expected edge, recompute the per-cluster excess, and replicate the clustered interval with nearest-rank percentiles (index `ceil(R*p)-1`). The fraction of simulated cohorts whose interval excludes zero is the rule's true size; compare it with the nominal 2.5%. (src: claim-rule-size-calibration; 2026-11-03)
- Use at least 4,000 cohorts by 2,000 resamples, and repeat at the shape of the target cohort using only its per-date cluster counts, because the number and balance of clusters drive the result. (src: claim-rule-size-calibration; 2026-11-03)
- With few clusters an interval-excludes-zero rule is typically anti-conservative, and how much depends on which clustering and statistic are used (date only, unit and date, or a t statistic on a small-sample-corrected standard error). The simulation measures it for the configuration actually in use, rather than assuming the nominal level. (src: claim-rule-size-calibration; 2026-11-03)
