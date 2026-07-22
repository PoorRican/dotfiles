---
name: experiment-log-interview
description: Conducts a structured Socratic interview to produce or update a single experiment log entry — the durable record of what was run, what it showed, and what it means. Use this skill whenever the user wants to log an experiment, write up results, record a backtest, capture a finding, pre-register a run, document a study, or update an existing entry with new results or a revised interpretation. Trigger on phrases like "log this experiment," "write up the results of...", "I ran X, help me document it," "pre-register this," "update the entry for...", or when the user shares results and asks for help interpreting and recording them. The skill enforces the four-way separation between what happened, what it means, what it implies, and what comes next; challenges the user's interpretations with evidence requests and alternative explanations; and writes incrementally to keep context clean and the entry always grounded.
version: 1.0.2
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [research, experiment-log, interview, documentation]
    related_skills: [experiment-log-structure, research-proposal-structure]
---

# Experiment Log Interview

## What this skill does

Runs the **human-facing interview layer** for building or updating a single experiment entry.

Use `experiment-log-structure` as the canonical definition of the artifact itself. This interview skill is intentionally thinner: it focuses on mode detection, questioning, challenge, and incremental writing discipline rather than re-specifying the full experiment-entry schema.

The output still becomes the standard experiment log artifact, but this skill's job is to get accurate, calibrated content into that artifact through a structured Socratic process.

## When to use

Trigger on requests like: "log this experiment," "write up the results of X," "help me document a backtest," "pre-register this run," "I have results, help me interpret them," "update the entry for...", or whenever the user shares experimental results in a context where they are likely to want a durable record.

Do NOT use for:
- informal scratchpad notes,
- cross-experiment retrospectives,
- direct artifact generation when the needed content is already known — use `experiment-log-structure`.

## Three modes — identify before interviewing

Always determine the lifecycle mode before deep questioning:
- **Mode A — Pre-registration**
- **Mode B — Post-run write-up**
- **Mode C — Revision of an existing entry**

If the mode is unclear, ask: *"Is this a new experiment you haven't run yet, results you're writing up, or a revision to an existing entry?"*

Use `experiment-log-structure` as the source of truth for what each mode implies for the document contract.

## Core workflow

### Step 1 — Mode + scaffold

After identifying the mode:
1. Load the structural contract from `experiment-log-structure`.
2. For Modes A/B, copy `references/template.md` to a working file (default: `experiments/<short-slug>.md` unless the user specifies another path).
3. For Mode C, read the existing file in full before asking further questions.
4. Tell the user the file path and the mode you are operating in.

Everything after this point edits the entry itself.

### Step 2 — Interview, gated by mode

Read `references/interview-guide.md` once. It contains the per-section question bank and challenge protocol.

Interview discipline:
- Ask **one focused question at a time**.
- After each substantive answer, apply the balanced challenge protocol.
- Update the markdown immediately after each meaningful exchange.
- Quote back a short excerpt of what you wrote.
- Push once for specificity on missing numbers or comparisons; if unavailable, record a TODO tied to the source of truth.

Mode handling:
- **Mode A:** fill only the pre-results sections, then stop.
- **Mode B:** fill the post-run sections while preserving any frozen pre-registration content.
- **Mode C:** append a dated addendum instead of silently rewriting substantive earlier claims.

### Step 3 — Exploration at key moments

Read `references/exploration.md` for exact prompts.

Three moments are worth the latency:
- after **raw evidence** is assembled: skeptical-reader pass,
- before **interpretation** is finalized: alternative-explanation pass,
- before **decision & next step** is finalized: calibration check.

Condense sub-agent output into short bullets before it enters the document. Bring the most important finding back to the user as a **question**.

### Step 4 — Coherence and freeze

Before finishing:
- verify that interpretation is supported by evidence,
- verify that confidence is proportionate,
- verify that implications and next steps connect back to the broader proposal/question,
- verify that any frozen pre-registration content stayed frozen,
- verify that revisions preserve the audit trail.

Then present the completed file path and current lifecycle state.

## Operating principles

**Pre-registration remains sacred.** The structure skill defines the freeze boundary; this interview skill must respect it.

**Evidence is shown, not claimed.** Push for the comparison behind every claim.

**One question at a time.** The interview is Socratic, not a survey.

**Negative and null results are first-class.** Document them with the same rigor.

**Sub-agents return summaries, not transcripts.** Keep the main thread centered on the user.

**The structure lives in the companion skill.** If you find yourself re-deriving the experiment-entry schema, reload `experiment-log-structure` and conform to it.

## Reference files

- `references/template.md` — experiment-entry scaffold copied at the start.
- `references/interview-guide.md` — interview questions and challenge prompts.
- `references/exploration.md` — sub-agent / scoped-pass prompts.
