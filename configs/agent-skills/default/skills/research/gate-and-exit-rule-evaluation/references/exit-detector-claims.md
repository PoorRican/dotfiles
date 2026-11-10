# Risk claims from out-of-fold detector predictions

Scope: answering analytic questions about what exit or catch models mean for risk (settlement versus price, whether flagged bid falls recover, differences by rung, family or week, one side versus the other, oscillation, warning time, cutoffs) from existing out-of-fold predictions without retraining. Each rule below records an overclaim a reviewer caught; check each before writing numbers. The cost and information decomposition and the clustered-SE formulas live in [exit-rule-decomposition.md](exit-rule-decomposition.md).

State the model's purpose in the owner's terms before reading anything: a model built to reduce risk is judged by what it flags and what each exit costs against the every-row random-exit reference, not by profit; a negative gain against the mid or settlement is the price of an exit.

## Joining and labels

- Join out-of-fold predictions to the curated rows on the full decision key (instance, instrument, decision timestamp) and to the raw trigger rows for columns curation drops (time to the next scheduled event, the exit bid). Assert no out-of-fold row is lost and keys are unique.
- For a two-sided contract the held NO bid is 100 minus the YES ask, so its change is the negative of the ask change.
- Use the paired end-of-window drop label ("did the bid still sit lower when the window ended") to answer "do flagged falls recover".

## Claims (each was a real overclaim)

- **Coverage is not risk removed.** "Share of falls on flagged rows" is row-level detector coverage; exposure avoided needs fill weighting and a hold-once policy. Check fill completeness at each exit size before saying fill weighting barely matters.
- **A flat mid is not a recovered bid.** Use the paired end-of-window drop label; means over rows cannot show that most single dips recover.
- **Point AUCs and row counts are not significance.** Rows are dependent: the same game appears across rungs and windows overlap. Report subgroup differences as descriptive unless a paired game-clustered Poisson(1) bootstrap was run (one weight per game shared by both groups, weighted AUC, 200 replicates, 2.5% and 97.5% quantiles), and add the count of weeks in which the gap has the same sign.
- **Do not condition warning time on the after-exit fall.** Conditioning on the drop guarantees a remainder and biases "still ahead" to about 0.95. Split each move into before the decision, decision to exit landing, and after the exit, and bin by time since and time to the next scheduled event.
- **A negative settlement gain proves little** about whether falls are temporary or liquidity-driven; settlement only shows where contracts ended up. Label mechanisms as inference.
- **State the limits.** Figures are per trigger row and one move spans several rows; scheduled-event times are recorded starts, not live arrival.

## Recipes

- **Does confidence predict losing at settlement?** Per decile of probability compare the loss rate with the price-implied loss (one minus held mid over 100). Compare the riskiest decile with the other nine, clustered by game.
- **Subgroup differences** (rungs, families): paired clustered bootstrap as above.
- **Are the two side models distinct?** Rank correlation of the two sides' probabilities and the AUC of their difference on windows where exactly one side fell.
- **Is oscillation predicted?** AUC of `min(p_yes, p_no)` on windows where both sides fell; oscillation and spread widening cannot be told apart.
- **Which cutoff?** Compare sizes and windows by rank (the share of events in the riskiest decile), not by a fixed probability; quote exit shares per side.
