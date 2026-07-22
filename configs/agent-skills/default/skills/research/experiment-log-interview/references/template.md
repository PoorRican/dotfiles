# [Experiment short name] — [one-line claim or question]

> **Entry ID:** `exp-YYYYMMDD-<slug>` · **Status:** `[pre-registered | running | complete | superseded]` · **Type:** `[confirmatory | exploratory]`
>
> **Created:** [date] · **Pre-registered:** [date or "N/A — post-hoc"] · **Results in:** [date] · **Last updated:** [date]
>
> **Owner:** [you] · **Parent proposal / line of attack:** [link or section ref]

---

## 1. Header

- **Question this entry addresses:** [one sentence]
- **Decision gate it informs (in the parent proposal):** [section ref]
- **Tags:** [domain, method, dataset]

---

## 2. Pre-registration  *(frozen once results are observed)*

> ⚠ This section is read-only after results arrive. To change it, add an addendum at the end of the entry.

- **Hypothesis:** [stated as a claim that could be wrong, not a topic]
- **Prior / current best guess:** [your honest expectation before running, with a rough credence]
- **Method (planned):**
  - [Setup, data, parameters, sample size / horizon — enough that someone could execute it]
- **Primary metric & threshold:**
  - Metric: [exact definition, including the slice — e.g., out-of-sample Sharpe on the 2024 holdout]
  - Threshold for "yes": [...]
  - Threshold for "no": [...]
- **Pre-stated outcome interpretations:**
  - If primary metric > τ_high: [...]
  - If τ_low < primary metric < τ_high: [...]
  - If primary metric < τ_low: [...]
  - If null / inconclusive: [...]
- **Stop conditions:** [when we'd halt early — e.g., obvious bug, runaway compute, ethical issue]

---

## 3. What was actually done  *(the delta from plan)*

- **Method (as-run):** [the actual setup, including any deviation from section 2]
- **Deviations from pre-registration:** [each one explicit, with reason]
  - [Deviation] — [why] — [whether it affects the validity of section 2's interpretations]
- **Provenance:**
  - Code: `commit <sha>` / `branch <name>`
  - Data snapshot: [path or hash]
  - Config: [path]
  - Run ID(s): [...]
  - Compute / wall-clock: [...]

---

## 4. Raw evidence  *(what the experiment produced)*

> Captions for plots and tables must be self-sufficient — readable without the surrounding text.

- **Primary metric result:** [value, confidence interval if applicable, comparison]
- **Secondary metrics:** [...]
- **Diagnostics:** [sanity checks a skeptic would ask for — sample sizes per slice, distribution of residuals, training curves, etc.]

### Plots / tables

- *Figure 1 — [self-sufficient caption]*: [link or embed]
- *Table 1 — [self-sufficient caption]*: [link or embed]

---

## 5. Interpretation  *(what it means, calibrated)*

**Headline finding:** [one sentence, no hedges in this sentence]

**Confidence:** `[high | medium | low | speculative]` — because [the calibration reasoning: evidence strength, surviving threats, sample size, prior plausibility]

**Threats to validity that survived:**
- ...
- ...

**Alternative explanations not ruled out:**
- ...
- ...

**Critique notes** *(from skeptical-reader pass and alt-explanation generator)*
- ...

---

## 6. Implications  *(for the broader question)*

- **For the root question:** [does this move the needle on the parent proposal's section 1? in which direction?]
- **For the theory of the problem:** [does this support, refine, or undermine the parent proposal's section 4?]
- **For the lines of attack:** [which line gets reinforced, which gets weakened, which conditional branch becomes active?]

---

## 7. Decision & next step

- **Decision gate resolved:** `[yes | no | partially | not yet]` — [which gate, which branch is now active]
- **Action taken in the parent proposal:** [what was updated, with a link to the proposal commit / version]
- **Next experiment:** [name + one-line description + why this one, not another]
- **Confidence the next experiment is the right one:** `[high | medium | low]`

**Critique notes** *(from calibration check)*
- ...

---

## 8. Loose ends  *(honest residue)*

- Things noticed but not investigated:
  - ...
- Things I'd do differently next time:
  - ...
- Open questions for collaborators:
  - ...

---

## 9. Audit trail

- Pre-reg commit: [sha / link]
- Results commit: [sha / link]
- Dashboard / experiment tracker URL: [...]
- Notebook(s): [...]
- Related entries: [...]

---

## Addenda  *(append-only — never edit prior sections)*

<!-- Each revision is a dated block. Note what changed, why, and which sections of the original entry are now superseded. -->

### [date] — [short title of revision]

- **What changed:** ...
- **Why:** [new evidence / bug / reinterpretation]
- **Sections superseded:** [e.g., "Section 5 headline; Section 7 next experiment"]
- **Updated finding:** ...
- **Updated confidence:** `[high | medium | low | speculative]`
