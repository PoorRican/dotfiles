# Exit rules and detector claims

A bid-drop detector can help time an exit, but it does not by itself answer whether selling beats holding. Compare executable proceeds net of costs with the held position's value or settlement, and compare timing with a random rule matched on the evaluations where the rule could act. An every-evaluation exit and a random exit are distinct controls; random recall equals its exit share only under appropriate independence and denominator assumptions.

## Coverage and execution

- The share of adverse moves on flagged rows is detector coverage, not exposure avoided. Repeated rows can describe one position or move, and an exit may not fill. Evaluate actual entry times and sizes, the first executable exit, fill quantity, costs and subsequent outcomes per position.
- Count triggers that fail to place or fill an order. A one-attempt policy can burn its opportunity on an unpriceable book; filled-only analysis excludes those positions.
- A stricter screen applied only to an existing rule's first trigger is not a replay of the stricter rule when it might trigger later. Measure the affected share and replay it before claiming its economics.
- A flat end-of-window mid does not establish bid recovery: the spread may have widened. Examine paired bid changes and avoid inferring the cause from settlement alone.
- Conditioning warning time on a subsequent drop selects on the outcome and can bias the apparent remaining warning. Separate the move before the decision, during execution and after exit.
- For subgroup differences use paired uncertainty clustered on the unit sharing shocks; dependent rows and point AUCs alone do not establish a difference. Join predictions on the full decision key and check uniqueness and row preservation.

## Settlement and cost decomposition

For a filled binary contract let `m` be the held-side decision mid, `S` its settlement, and `G` exit-minus-hold gain per filled contract. Define `I = S - m` and `C = -(G + I)`, the exit cost relative to mid including spread, execution movement and fees. Then `G = -C - I`; exiting beats holding in expectation on flagged positions when `E[I | flag] < -E[C | flag]`. Compare flagged and other rows on information, execution cost and subsequent mid and bid moves. Use a paired cluster-level uncertainty estimate.

For value-gated adds and exits, compare each with a matched-rate random timing twin on settlement minus touch as well as net outcomes. The baseline can differ across sides and positions; do not assume held contracts are underpriced. Examine how realized value and model error vary with signal strength without requiring a particular monotonic pattern.

Reconcile replay results to the position and order ledger before interpreting them. When entry sets match the hold twin, exit-minus-hold per position is `(exit price - settlement) * exit quantity - exit fee`. Apply the actual fee rules per order and preserve partial fills; aggregate orders consistently. A mid-based decomposition requires recorded information sufficient to recover the mid.

## Detector readouts

- To ask whether flagged bid falls recover, use the paired end-of-window bid-drop label; a mean mid change cannot show whether individual dips recovered.
- For subgroup differences, use a paired cluster bootstrap: draw one weight per cluster and share it across both groups, recompute the weighted AUC difference, and report its interval and the number of time blocks in which the gap has the same sign.
