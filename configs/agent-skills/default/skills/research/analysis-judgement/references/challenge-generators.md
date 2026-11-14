# Challenge Generators

## Frame and alternatives

- State the question the number actually answers. Check what the frame leaves unmeasured, including variables with no recorded column.
- For a forced choice, look for a shared premise and a viable third option. Consider the incentives of the people and processes generating the data.
- Describe the strongest plausible null that produces the same observation, and find a cheap observation that distinguishes it from the proposed explanation. Check whether a standard method's assumptions hold in this setting.
- What changes if the baseline becomes the hypothesis under test, the instrument the object of study, or the model's error the signal? An inversion that survives may reorganize the analysis.
- A measured null rules out only what was measured under those conditions; it need not exclude another plausible, reversible hypothesis. Scale the conclusion to the evidence and its consequences.
- Drop repeated challenges that cannot change the decision once answered or accepted as a risk; prefer challenges that distinguish live hypotheses.

## Choosing an experiment

- Read available code and documentation first when they can resolve the feasibility question. Run the experiment most likely to invalidate the larger proposal before lower-risk work.
- What is the boring alternative, compared on maintenance, reversibility, and blast radius? Ground claims about current behavior in code or other direct evidence.
- Define observable outcomes for success, partial success, and failure. Comparison experiments must test the same question under comparable conditions, including integration and data handoff.

## Fallbacks and invariants

- Before guessing an identifier or structure from a name, check the trigger and the authoritative index. A field supplied only at creation can be absent because it was already recorded, not because it is unknown; a fallback can contradict the record.
- Identify the invariant between the authoritative index and derived table, and what could break it, before deciding whether a fallback is needed.
