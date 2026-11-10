# Scoring rollout laws: histogram bias and exact composition

Scope: a simulator or rollout (a possession or process model, a world-model rollout) whose sampled endpoints are turned into a histogram and scored by joint log loss. Use before trusting a score, an epoch choice or a head comparison that involves such a law, and before deciding whether an exact recursion is worth building.

## Why the histogram score is biased

- The log of a histogram frequency is biased low. Score a perfect simulator as `q_N = (1 - f) * hist_N + f * floor` and `E[KL(p || q_N)]` is still above zero. It falls like 1/N once the occupied support is well sampled and grows with the law's entropy.
- Unmeasured, the bias penalizes sampled heads against analytic heads and pushes selection made on a Monte Carlo score toward narrow laws.

## Build proxy laws as sharp as the bar

- A marginal law (endpoint by time bin) demonstrates the mechanism only; it is not evidence about a fitted model's bias, a contrast's outcome or a minimum detectable effect.
- Quote bias only from conditional proxy laws as sharp as the incumbent bar. Nest cell, parent and base levels, shrink each toward the next (weights chosen by grouped cross-validation, with full backoff in every grid so no optimum sits on a grid edge), and smooth the base toward the product of side marginals.
- Compare proxy held-out NLL with the bar only as a sharpness check; populations and splits differ, so the numbers are not comparable as a contrast.

Keep a compact `excess_curve` (a perfect simulator with an optimistic floor equal to the truth):

```python
import numpy as np

def excess_curve(p, Ns, R, rng, floor=0.02):
    """Mean KL(p || (1 - floor) * hist_N + floor * p) for a perfect simulator."""
    p = p / p.sum()
    nz = p > 0
    pn = p[nz]
    out = {}
    for N in Ns:
        counts = rng.multinomial(N, p, size=R)[:, nz]
        q = (1 - floor) * counts / N + floor * pn
        out[N] = float(((np.log(pn) - np.log(q)) * pn).sum(1).mean())
    return out
```

## Read the curve

- Report the origin-weighted excess with its SE at both the selection N and the scoring N.
- Print `N * excess`. Flat means the 1/N regime; still rising means any two-point extrapolation understates the bias.
- Regress the excess on law entropy. A positive slope means Monte Carlo selection rewards narrower laws.
- `(K - 1) / (2N)` understates the excess whenever rare, floor-dominated cells matter.
- A perfect simulator's excess is a reference scale only; a fitted model's bias depends on how much mass it puts on rare cells, so measure it on the model.

## Retained halves estimate the bias; they do not prove it is gone

- Keeping the NLL of each N/2 half of the same rollouts under the same floor mixture gives a Richardson estimate, `bias(N) ~ mean(NLL_half) - NLL_full`. It is exact only in the 1/N regime and recovers part of the excess elsewhere.
- The decisive check re-scores a fitted model on a fixed grouped subsample across N (for example 1k to 32k) and compares the residual at the scoring N with the contrast's clustered SE.

## Remedies, cheapest first

1. Integrate draws that only add to the score (Rao-Blackwellization), accumulating the conditional distribution instead of sampling it.
2. Accumulate conditional distributions for the last one or two steps.
3. Select epochs on a Rao-Blackwellized or large-N score over a fixed validation subsample, never on raw small-N Monte Carlo.
4. Exact recursion when the state is small and discrete (below).
5. Distil the rollout into an analytic head for serving, and keep that head out of the rollout-versus-analytic comparison.

## When Rao-Blackwellization stays exact

- Convolving a draw analytically is exact only for terminal draws that no later emission reads.
- Under state feedback (a running score or count that later emissions condition on), branch on the draw and reweight, feed back a nominal value so the draw stays terminal, or integrate only the draws no later emission sees.
- With a shared clock the two sides are coupled, so the recursion must carry the joint tally; per-side generating functions do not factorize.
- Importance-weighted endpoint bounds built from prior samples rarely hit an exact joint cell for laws with several nats of entropy. They need Rao-Blackwellized final steps, or reduce to teacher forcing when the observed path is the proposal.

## Exact composition instead of a histogram

Use it only when:

- everything that changes inside the rollout is a small discrete state;
- everything else is fixed per origin (encoder context, line, frozen inputs);
- durations sit on the state grid;
- score increments are non-negative.

Continuous state, un-banded score feedback or negative increments break exactness or blow up the cost; re-derive before reuse.

Three exact quantities:

- **Pointwise NLL of the realized cell**: run the recursion only on the box `[0..a*] x [0..h*]`. Mass that leaves the box never returns, so there is no grid cap and no truncation error.
- **Full-support moments**: propagate `(mass, sum a, sum h, sum a^2, sum h^2, sum ah)` per state; a points shift is linear in these, so no grid is needed.
- **Live pricing on a fixed grid**: in-grid cells are exact and overflow mass is exactly `1 - grid mass`.

State extensions (score bands, timeouts, mixture classes) multiply the recursion cost, and evaluating the emission network on every reachable state can dominate it. Split the first linear layer into per-origin and per-state terms, evaluate only reachable states, and measure rather than extrapolate.

## Validate before relying on it

1. Brute force on float64 random tables over a short window with millions of paths: z-scores on the top cells, in-box mass equal to 1.
2. A small box against the large grid on several cells.
3. Exact moments against Monte Carlo moments.
4. The fitted model's exact law against its own Monte Carlo law across N. The MC-minus-exact gap at the production N is what Monte Carlo scoring would have cost.
5. Keep the Monte Carlo rollout as a property-test oracle for the exact code.

## Traps

- Quoting a marginal-law simulation as a specific model's bias or as a contrast verdict.
- Treating retained halves as proof that the bias is gone.
- Calling a convolution exact after the running state has started feeding later emissions.
- Comparing proxy NLL with the bar as if the populations matched.
- Copying bias figures from another law: re-measure on the law and splits at hand (dated figures from one design review do not transfer).
