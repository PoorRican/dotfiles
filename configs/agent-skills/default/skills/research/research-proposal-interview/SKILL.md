---
name: research-proposal-interview
description: Conducts a structured Socratic interview to produce a comprehensive markdown research proposal that handles cascading uncertainty (fixed end-question, branching experiments). Use this skill whenever the user wants to write a research proposal, research plan, study design, experiment plan, thesis proposal, RFC, or "spec out" a research direction — even if they don't explicitly say "interview me." Trigger when the user says things like "help me plan this research", "I want to design experiments for X", "draft a proposal for...", "think through a research direction", or shares a half-formed research idea and asks for help structuring it. The skill interviews the user, challenges their priors with evidence requests and falsifiers, optionally uses sub-agents to explore prior art, and builds the proposal markdown incrementally so context stays clean and the document is always grounded.
version: 1.0.2
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [research, proposal, interview, planning]
    related_skills: [research-proposal-structure, experiment-log-structure]
---

# Research Proposal Interview

## What this skill does

Runs the **human-facing interview layer** for building a research proposal.

Use `research-proposal-structure` as the canonical definition of the artifact itself. This interview skill is intentionally thinner: it focuses on elicitation, challenge, sequencing, and incremental writing discipline rather than re-specifying the full proposal schema.

The output still becomes the standard proposal artifact, but this skill's job is to get high-quality content into that artifact through a structured Socratic process.

## When to use

Trigger on any request resembling: "draft a research proposal," "help me design a study," "plan experiments for X," "spec out this research direction," "write a thesis proposal," or a user dropping a half-baked research idea and asking for structure. Also trigger when an existing rough plan needs to be sharpened into a proposal — start by reading what they have, then enter the interview loop from wherever the gaps are biggest.

Do NOT use for:
- literature reviews with no original research plan,
- engineering design docs with no empirical question,
- quick brainstorms the user explicitly wants to keep casual,
- direct artifact generation when the needed content is already known — use `research-proposal-structure`.

## Core workflow

### Step 1 — Establish scope, then scaffold immediately

Ask one opening question: *"What's the end question this research needs to answer, and what's your current best guess at the answer?"*

Get a one-paragraph reply. Do not begin the full interview yet.

Then immediately:
1. Load the structural contract from `research-proposal-structure`.
2. Copy `references/template.md` to a working file (default: `proposal.md` in the current working directory unless the user specifies another path).
3. Fill only the title and rough root-question slot from what you just learned.
4. Tell the user the file exists and where it lives.

This early scaffold is mandatory. The document becomes the source of truth; the chat becomes the workbench.

### Step 2 — Interview section by section

Read `references/interview-guide.md` once. It contains the canonical question set and challenge prompts.

Drive the conversation section-by-section, but rely on `research-proposal-structure` for what each section must contain.

Interview discipline:
- Ask **one focused question at a time**.
- After each substantive answer, apply the balanced challenge protocol: identify the assumption, ask for evidence, propose one falsifier or alternative explanation.
- After the user responds, update the markdown immediately with a targeted edit.
- Show the user a short excerpt of what you wrote, then continue.
- If the user stays vague after one push for specificity, write `[TODO: needs sharpening]` and move on.

### Step 3 — Explore via sub-agents or scoped passes

Read `references/exploration.md` for exact prompts.

Three exploration moments are worth the latency:
- after **lines of attack** are drafted: prior-art scout,
- after **immediate experiment(s)** are drafted: methodological critic,
- after **risks & kill criteria** are drafted: pre-mortem.

Condense sub-agent output into 3–6 bullets before it touches the document. Bring the most important finding back to the user as a **question**, not a lecture.

### Step 4 — Adversarial experiment pass

Once at least one immediate experiment is specified, make sure the proposal includes:
- the confirmatory experiment the user naturally wants,
- a falsification experiment,
- an alternative-explanation experiment.

Push to retain at least the falsifier alongside the confirmatory test.

### Step 5 — Coherence check and finalize

When all sections have content:
- check that the immediate experiment actually informs the root question,
- check that conditional branches are explicit,
- check that kill criteria are real,
- check that confidence tags are honest,
- check that the proposal reads like a decision procedure, not a prediction.

Surface inconsistencies briefly, apply fixes, and present the final file path.

## Operating principles

**Write the doc early and keep it current.** If the interview has gone several turns without updating the file, stop and write.

**One question at a time.** The interview is Socratic, not a survey.

**Challenge to strengthen, not to dominate.** Surface one assumption, ask for evidence, propose one alternative, then move on.

**Sub-agents return summaries, not transcripts.** Keep the main thread centered on the user.

**The structure lives in the companion skill.** If you find yourself re-deriving the proposal schema, reload `research-proposal-structure` and conform to it.

## Reference files

- `references/template.md` — proposal scaffold copied at the start.
- `references/interview-guide.md` — interview questions and challenge prompts.
- `references/exploration.md` — sub-agent / scoped-pass prompts.
