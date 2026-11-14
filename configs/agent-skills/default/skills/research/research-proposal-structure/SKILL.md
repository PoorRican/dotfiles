---
name: research-proposal-structure
description: Structure, update or review a research proposal when the question and available context are known. Use for a decision-useful plan with executable immediate work and conditional future branches; use research-proposal-interview to elicit missing content.
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [research, proposal, structure, standardization, agents]
    related_skills: [research-proposal-interview, experiment-log-structure]
---

# Research Proposal Structure

Use the [proposal template](references/template.md) as a scaffold, adapting it to the task and any existing local format. The root question and success criteria stay fixed; immediate experiments are fully specified, while future work is represented as conditional branches instead of fake certainty. The default filename is `proposal.md`, unless the caller specifies another path.

## Section contract

1. **Question & significance:** State one root question, why the answer matters, and the current best guess as a prior, not a conclusion.
2. **Success criteria:** Define externally checkable strong-yes, strong-no, and inconclusive evidence, and what happens if inconclusive.
3. **Prior work & gap:** Summarize relevant baselines, results or attempts, and what remains unresolved; cite or link where available.
4. **Theory:** Describe the mechanism or framing and list its assumptions, separate from the literature summary.
5. **Lines of attack:** Describe distinct plausible strategies, rank by current credence, and state what each is, why it might work, prerequisites and rough cost/time.
6. **Immediate experiment:** Specify hypothesis, executable method, primary metric, decision gate and interpretation of outcomes. Consider confirmatory, falsification and alternative-explanation tests; distinguish a null result from an insufficiently sensitive test.
7. **Conditional next steps:** Connect outcomes to branches and specify criteria for abandoning the line of inquiry.
8. **Speculative horizon:** Describe the aspirational end state without presenting it as a commitment.
9. **Risks & assumptions:** Record likelihood, impact and mitigation or contingency, including technical and epistemic risks.
10. **Decision log:** Record dated material plan updates; actual findings belong in experiment entries or research logs.

Use confidence tags consistently: `[committed]` means fully specified, ready to execute and owned; `[planned]` means intended but not execution-ready; `[conditional]` depends on a decision-gate outcome; `[speculative]` is directional or aspirational. Downgrade tags when uncertain.

## Update and validation

Read an existing proposal first and preserve its root question unless the user wants a different one. Update the affected approaches, experiments, branches and risks as evidence changes the plan, keeping them aligned with the root question; log material changes. Check that success criteria are judgeable, immediate work is executable, at least one falsification path exists, branches follow explicit outcomes, kill criteria are meaningful, and tags match actual certainty.

| Reference | Use |
|---|---|
| [Proposal template](references/template.md) | Ten-section scaffold, decision gates, tags and critique-note locations. |
