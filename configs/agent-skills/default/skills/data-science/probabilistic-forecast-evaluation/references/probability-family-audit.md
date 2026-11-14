# Auditing related probabilities

For forecasts over nested thresholds, horizons or event sides, join models on full row keys and verify matching labels and row counts. Score each head only where its outcome is defined. Check label nesting and definedness before treating predicted crossings as incoherence: the larger threshold or shorter horizon should imply the corresponding nested event where both labels exist.

Report crossing frequency and magnitude by pair and location. Project predictions onto the applicable coherent ordering and rescore to measure its practical cost; the score change must be interpreted against its uncertainty and decision scale, not a fixed threshold. For multidimensional orderings, ensure the projection actually satisfies all constraints.

Compare per-head log loss, Brier score and AUC using paired differences with uncertainty clustered on shared shocks. Examine observed/predicted ratios, calibration slope and binned reliability alongside discrimination. Underprediction and overconfidence are distinct defects. Pooled calibration can mask time variation; correlated observed/predicted ratios across models share the same numerator and do not establish the cause of drift.

In-sample recalibration illustrates possible fit but does not establish deployable improvement. Fit recalibrators on earlier data and score subsequent data, comparing on identical rows. When reporting head or subgroup contrasts, specify defined labels and population; overlapping rows need not be independent events.

Ranking quality at the top can differ from overall AUC: inspect hit rate and event coverage at relevant matched selection rates. Disagreement groups (both selected, each selected alone, neither) expose where models differ. A held-out combination can test complementarity; an in-sample gain is not evidence that combining models generalizes. Compare matched counts separately from absolute probability thresholds, where calibration matters directly.
