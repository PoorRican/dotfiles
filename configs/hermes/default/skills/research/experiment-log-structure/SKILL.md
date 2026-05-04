---
name: experiment-log-structure
description: Use when an agent needs to produce, update, validate, or normalize a standardized experiment-log entry without running an interview. Defines the canonical structure, pre-registration rules, evidence/interpretation split, calibration tags, and append-only revision model for durable experiment records.
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [research, experiment-log, structure, standardization, agents]
    related_skills: [experiment-log-interview, research-proposal-structure]
---

# Experiment Log Structure

## Overview

This skill defines the **artifact contract** for a standardized experiment entry: a durable markdown record of what was planned, what was run, what happened, what it means, and what follows.

Use this when the content already exists and an agent needs to write, clean up, standardize, update, or audit the entry itself. Unlike `experiment-log-interview`, this skill does **not** run a Socratic interview. It focuses on producing a defensible artifact.

The governing principle is: **what happened, what it means, what it implies, and what comes next are different things and must stay visibly separate**.

## When to Use

Use when:
- An agent must write or normalize an experiment entry from provided run context.
- A lab note, backtest note, or result summary needs to become a standardized experiment log.
- You want a machine-checkable structure for experiment records.
- You need to update an existing entry while preserving auditability.
- You want consistent experiment documentation across many agents or projects.

Do not use when:
- The main need is to elicit details from a human collaborator. Use `experiment-log-interview`.
- The artifact is a forward-looking research plan. Use `research-proposal-structure`.
- The output should be an informal scratchpad rather than a durable record.

## Canonical Output

Create or normalize a markdown entry using `references/template.md` as the authoritative skeleton.

Default location: `experiments/<short-slug>.md` in the working directory unless the caller specifies another path.

The resulting document should be sufficient for a skeptical reader who has **only the entry** and no chat transcript.

## Lifecycle Modes

Every entry should be interpreted as one of three modes:

### Mode A — Pre-registration
- The experiment has not yet run.
- Fill sections 1–2 only.
- Mark the entry as awaiting results.
- Section 2 becomes frozen once results are observed.

### Mode B — Post-run write-up
- The experiment has run.
- If there was a real pre-registration, treat section 2 as read-only.
- If there was no pre-registration, the entry may reconstruct section 2 post hoc, but must clearly mark itself exploratory/post-hoc.

### Mode C — Revision
- New evidence, bugs, or reinterpretation changed the earlier record.
- Add an append-only addendum.
- Do not silently rewrite prior meaning-bearing sections.

## Section Contract

### 1. Header
- State the question this entry addresses.
- Link the decision gate or parent proposal section it informs.
- Include tags and provenance basics.

### 2. Pre-registration *(frozen once results are observed)*
- Hypothesis must be a claim that could be wrong.
- Record the honest prior/current best guess.
- Planned method must be specific enough to execute.
- Define the primary metric and outcome thresholds.
- Pre-state how different outcomes would be interpreted.
- Include stop conditions.

### 3. What Was Actually Done
- Record the as-run method.
- Enumerate every meaningful deviation from section 2.
- Explain why each deviation happened and whether it affects validity.
- Include provenance: code, data snapshot, config, run IDs, compute.

### 4. Raw Evidence
- Report what the experiment produced, not your theory about it.
- Primary metric, secondary metrics, diagnostics, plots, and tables belong here.
- Captions must be self-sufficient.

### 5. Interpretation
- State a one-sentence headline finding.
- Calibrate confidence explicitly.
- List surviving threats to validity.
- List alternative explanations not ruled out.
- Keep critique notes as concise bullets.

### 6. Implications
- Connect the result to the broader root question.
- State whether the theory of the problem was supported, refined, or weakened.
- Explain which line of attack or branch now strengthens or weakens.

### 7. Decision & Next Step
- Resolve the decision gate if possible.
- Record the action taken in the parent proposal.
- Name the next experiment and why it is next.
- Calibrate confidence that the next step is the right one.

### 8. Loose Ends
- Preserve honest residue: anomalies, uninvestigated observations, and collaboration questions.

### 9. Audit Trail
- Keep links to commits, trackers, notebooks, dashboards, and related entries.

### Addenda *(append-only)*
- Each revision gets a dated block.
- State what changed, why, what sections are superseded, and the updated finding/confidence.

## Confidence Vocabulary

Use these tags exactly:
- `[high]`
- `[medium]`
- `[low]`
- `[speculative]`

These tags apply to findings and implications, not to raw evidence itself.

## Standardization Rules

1. **Pre-registration is sacred.** Once results are observed, section 2 is frozen.
2. **Evidence before meaning.** If a claim in section 5 is not grounded in section 4, weaken it or remove it.
3. **Comparisons are mandatory.** “Improved” is invalid without “improved from X to Y on slice Z.”
4. **Negative/null results are first-class.** They receive the same rigor as positive results.
5. **Interpretation is not implication.** Section 5 says what the result means locally; section 6 says what it changes globally.
6. **Revisions are append-only.** Preserve the audit trail.

## Update Procedure

When revising an existing entry:
1. Read the full document.
2. Identify whether the change is a factual correction, new result, bug discovery, or reinterpretation.
3. Preserve existing sections unless the change is purely clerical.
4. Add a dated addendum for any substantive revision.
5. If a reconstructed pre-reg exists, keep its exploratory/post-hoc labeling explicit.

## Validation Checklist

An entry is ready when:
- [ ] The lifecycle mode is clear.
- [ ] Section 2 is either properly frozen or explicitly marked reconstructed/post-hoc.
- [ ] Section 3 records real deviations rather than pretending the plan matched execution.
- [ ] Section 4 contains the evidence needed to support section 5.
- [ ] Confidence tags are proportionate.
- [ ] Section 6 links back to the parent question/proposal.
- [ ] Section 7 resolves a real decision or states why it cannot yet.
- [ ] Addenda preserve auditability.

## Common Pitfalls

1. **Collapsing evidence and interpretation.** Plots and metrics are narrated as conclusions instead of raw output.
2. **Retroactive pre-registration editing.** Section 2 gets rewritten after results are known.
3. **Missing comparisons.** Claims like “better” or “worse” are unsupported.
4. **No decision consequence.** The entry records results but not what changes next.
5. **Silent revisionism.** Old conclusions are edited away instead of superseded via addendum.

## Reference Files

- `references/template.md` — canonical experiment-entry skeleton.
