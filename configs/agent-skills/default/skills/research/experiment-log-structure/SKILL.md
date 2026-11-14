---
name: experiment-log-structure
description: Shape or revise a durable experiment record from available information. Use when recording a plan, results, or a substantive correction without imposing a universal template.
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [research, experiment-log, structure, standardization, agents]
    related_skills: [experiment-log-interview, research-proposal-structure]
---

# Experiment Log Structure

An experiment record makes the question, execution, evidence and conclusions inspectable without relying on the conversation that produced it. Follow the project's existing record format and location; choose the detail appropriate to the experiment rather than imposing a fixed schema.

Use sections as the record needs them: question and plan; what ran and deviations; evidence; interpretation and implications; decision or next step; limitations and open questions; audit links; and substantive revisions. An existing project format may group these differently or omit inapplicable sections.

- Distinguish the planned method from what actually ran, including meaningful deviations, their reasons and their effect on interpretation. Include enough code, data and configuration provenance to locate the materials used.
- Separate observed evidence from interpretation, implications and decisions. Give the baseline and relevant slice for comparative claims, and qualify conclusions and confidence by the remaining threats and alternative explanations.
- If a plan was committed before results, preserve that original record; label any plan reconstructed after seeing results as post hoc, not pre-registered. If outcome thresholds are specified, define their boundary cases as well as the ranges.
- Preserve the history of substantive corrections or reinterpretations: record what changed, why, and which earlier claims are superseded. Capture unresolved diagnostics or limitations rather than presenting missing evidence as a result.

For a new plan, record only what is known before results and mark it as awaiting them. For a post-run write-up, preserve any genuine pre-registration; otherwise label any reconstructed plan post hoc. For a substantive revision, read the existing entry, identify whether the change is a correction, new evidence, bug or reinterpretation, and add a dated account of what changed and what it supersedes.

Before finishing, check that the evidence supports each interpretation, confidence is proportionate, and the record states what decision follows or why it remains unresolved. Link the code, data, configuration, results and related records needed to inspect the work.

| Reference | Use when |
|---|---|
| [Experiment template](references/template.md) | A project has no established record format, or a section-by-section scaffold would help. Adapt or omit inapplicable sections. |
