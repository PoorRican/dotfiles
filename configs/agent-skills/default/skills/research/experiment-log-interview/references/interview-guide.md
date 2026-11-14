# Interview Guide

Choose questions that fill consequential gaps; adapt them to the record and the information already available.

## Question and plan

- What specific question can this experiment actually answer, and what decision would it inform?
- What hypothesis could be wrong? What is your expectation before running?
- What method, data, metric and comparison would distinguish the outcomes? What would each outcome imply?
- If thresholds are useful, why are they defensible before seeing results, and how do boundary cases count? When would you stop early?
- If results are already known, would you actually have chosen this metric and threshold beforehand? Identify any reconstruction as post hoc.

## Execution and evidence

- What actually ran, and how did it differ from the plan? Why did each meaningful deviation occur, and does it change how the result can be interpreted?
- Which code, data snapshot and configuration produced the result? What information is missing to locate or reproduce it?
- Anything tweaked mid-run that has not been mentioned, such as a parameter sweep narrowed late, a slice excluded, or a seed swapped?
- Do deviations mean the pre-stated thresholds no longer apply cleanly?
- What was the result relative to the baseline, on which slice, and with what uncertainty where applicable? What do secondary metrics show?
- What diagnostic would a skeptical reader ask for, such as slice sample sizes, residuals or an ablation? If it is unavailable, what remains unresolved?

## Interpretation and implications

- What finding does the evidence support, with appropriate qualification? What claim might a reader infer that it does not support?
- What alternative mechanism could produce the same observation, and what test would distinguish it? Which threats remain, and how do they affect confidence?
- How does the result change the broader question or decision, including options it weakens? If a next step is proposed, why this one rather than an alternative?
- What observations were not investigated, and what should a collaborator know before relying on the finding?

## Revision

- What changed, why, and which earlier claims are affected? Is it new evidence, a bug, or a reinterpretation?
- What is the updated finding and confidence? If the interpretation changed without new evidence, what reasoning justifies the change?

## Optional focused review passes

When a result warrants a deeper review, use the relevant pass rather than running all three mechanically. Bring the most important finding back as a question and record any material unresolved issue.

**Skeptical reader:** Give the reviewer the question, plan, as-run method and raw evidence, but not the preferred interpretation. Ask what headline the evidence supports; what it does not support but a careless reader might infer; what diagnostic is missing; which deviation most threatens the pre-stated thresholds; and whether the most and least generous readings are warranted.

**Alternative explanations:** Give the reviewer the question through the proposed interpretation. Ask for plausible mechanisms other than the preferred one that would produce the observation, each paired with a specific test or observation that distinguishes it.

**Calibration:** Give the reviewer the complete entry. Ask whether confidence is proportionate to evidence and surviving threats, the headline is appropriately scoped, implications are warranted, the proposed next experiment is justified against alternatives, and any section is conspicuously empty or superficial. Ask for specific edits.
