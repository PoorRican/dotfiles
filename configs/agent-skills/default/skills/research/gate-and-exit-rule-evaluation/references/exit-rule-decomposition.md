# Exit, catch and stop rule decomposition

Scope: judging whether an exit, catch, stop or value-gated add rule for held positions in binary-outcome contracts (settling at 0 or 100) beats holding or random timing, from out-of-fold rows or replayed cells. Use before claiming that a rule "reduces risk", "avoids X% of falls", "loses to settlement", or that a value gate beats random timing. Quantities are in cents per contract.

## Claim discipline

- **Coverage is not protection.** The share of adverse moves on flagged rows is row-level detector coverage: every trigger row counts as if a position were held there, and a flagged row's move counts in full whatever the exit filled. Report it as "falls on flagged rows". Exposure actually avoided needs a position-level test: real entry times and sizes, one exit at the first flag, the fall and settlement avoided measured per position net of exit cost, dependence clustered by game.
- **A bid-drop forecast is a timing signal, not a hold-or-sell signal.** A head predicting that the held side's bid falls by c within h seconds says when to sell if you are selling anyway. Against holding, the alternative is settlement, so the decision must compare bid minus fee with the held side's value from a forecast or settlement model. Use the liquidity signal only to time an exit the value rule already wants.
- **Settlement variance versus expected loss.** Selling always ends settlement variance on the sold contracts. It lowers expected loss only where positions settle below the held mid by more than the exit cost.
- **A negative settlement gain is the exit's price.** On its own it says nothing about whether moves were temporary or informative; measure that with the decomposition below.
- **Always compare with the every-row reference** (exit at every row, a random exit rule): its recall equals its exit share and its per-exit cost is the baseline.
- **Screens are not rules.** A first-trigger screen keeps the registered rule's first exit only if it also passes a stricter test. It is exact only for positions whose first trigger already passes the stricter test; report the share that does not (group B) and replay the true stricter rule before claiming its economics.

## Decomposition per filled contract

Held side `s`; `outcome_s` is 1 if the held side settles at 100, else 0.

- `m`: the held side's mid at decision time `t`.
- `fill`: the share of the exit size filled; require `fill > 0`. Check the share of fills below 1 at each exit size before claiming anything about fill weighting.
- `settle_pf`: settlement gain per filled contract (hold minus exit result, divided by `fill`).
- `I = 100 * outcome_s - m`: what the price at `t` missed about settlement.
- `C = -(settle_pf + I)`: the exit cost against the mid at `t` (spread, depth walk, fee and the move to the exit time).
- `M`: the held side's mid at the end of the window minus `m`.
- Identity: `settle_pf = -C - I`. Exiting beats holding in expectation only if `E[I | flag] < -E[C | flag]`.

Compare flagged against other rows on `I`, `C` and `M`.

- Mean SE clustered by game: `sqrt(sum_g (S_g - m * N_g)^2) / N`.
- Difference SE through influence terms: `psi_i = (x_i - m1) / n1` on flagged rows, `psi_i = -(x_i - m0) / n0` on the others, `SE = sqrt(sum_g (sum_{i in g} psi_i)^2)`.
- **Transience**: a window-end mid near the trigger mid does not show the bid recovered, because a widened spread lowers the bid at a flat mid. Report the window-minimum bid drop and `M` separately and claim no cause. A transience reading that was published must be withdrawn explicitly if a decomposition contradicts it.

## Value-gated adds and exits against matched-rate random twins

Use when a cell re-evaluates held contracts and the question is whether the value rule's timing beats random timing or beats holding.

| | Adds (held side bought at ask `a`) | Exits (held side sold, bid `b`, fill `x`) |
|---|---|---|
| Perceived edge `d` | `v - a` | `b - v` |
| Realized `r` | `S - a - fee` | `x - fee - S` (exit versus hold) |
| Model error | `S - v` | `S - v` |
| Market error at the touch | `S - a` | `S - b` |

`S` is the held side's settlement (0 or 100) and `v` is 100 times the model's probability for the held side at the decision.

- **Gate versus twin.** Compare each gate with its random twin on `S - touch` before fees, which separates what value timing bought from the side's baseline. Pair over shared games with the influence-term SE and pool the twin's seeds by contract weight.
- **The baseline differs by side.** An add starts near break-even at the ask. An exit starts from the held contract's underpricing after entry (random-time sales can settle several cents above the bid). Equal timing information can therefore make adds profitable while exits still lose to holding; a bearish model on a held contract is cheapest to act on by not adding.
- **Trigger strength.** Bin by tertiles of `d` and require realized `r` to rise monotonically with `d`, not one tail bin on a few positions. If model error grows with disagreement, a higher bar only trades fewer contracts.
- **Placebo rates.** Count rule fires per rule evaluation after every pre-draw check; never per eligible instant.
- **Interaction of an add rule and an exit rule.** Separate cells share their entries when the base is identical; classify each add by whether the exit cell had already sold that contract and each exit by whether the add cell had already added to it.
- **Fail closed.** Pooled `r` must equal the lot ledger to within a hundredth of a cent.

## Burned attempts and fill selection

- Count exit rows whose single attempt ended without an order (no bid, unpriceable book). A rule that spends its one attempt on a one-sided book before testing its trigger decides which positions can be sold at all.
- Positions whose exit fired but could not fill are often the real losers. Any analysis conditioned on filled exits excludes them; say so.
- Fee fields can differ by order path (a whole-cent ceiling on initial entries versus the exact order fee on later orders). Recompute exact fees from fills, one ceiling per order, and merge lots of one exit order by client order id before computing the fee.
- Reproduce replayed-cell identities before trusting a decomposition: when entries equal the hold twin's, each position's exit-minus-hold equals `(exit_avg - settle_side) * exit_qty - exit_fee`, and the per-game sum must reconcile with the cell fold minus the twin fold.
- The mid is recoverable only for exits that record half-spread plus fee; exits that record only the touch split against the touch and are not comparable.
