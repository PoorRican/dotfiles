# Payoff Containment Tests

When testing bounds computed from marginal survivals:

- Construct a small joint distribution first and derive all marginal survivals from the same represented event; arbitrary marginal arrays may be mutually incompatible. Include support-boundary and unrepresented-mass cases without renormalizing.
- Enumerate continuation choices independently for each eligible state. For every resulting policy, calculate expected numeric settlement payoff, including fractional payouts where permitted, and assert that it lies inside the reported bounds.
- Separate numerical containment from qualification and delivery tests: an interval may contain every tested payoff even if its source was not eligible.
