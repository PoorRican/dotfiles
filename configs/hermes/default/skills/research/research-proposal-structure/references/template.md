# [Working Title]

> **Status:** draft · **Last updated:** [date] · **Owner:** [you]
>
> Confidence tags used throughout: `[committed]` · `[planned]` · `[conditional]` · `[speculative]`

---

## 1. Question & Significance  *(fixed)*

**Root question:**
> [The single sentence the entire proposal is in service of answering.]

**Why it matters:**
[2–4 sentences. Who cares, what changes if we have an answer, what's the cost of not knowing.]

**Current best guess at the answer:**
[Your prior. Stated honestly, not strategically.]

---

## 2. Success Criteria  *(fixed)*

What would count as having answered the question? Be concrete enough that a reasonable third party could check.

- **Strong-yes evidence looks like:** [...]
- **Strong-no evidence looks like:** [...]
- **Inconclusive looks like:** [...] — and what we'd do about it.

---

## 3. Prior Work & Gap

[3–6 bullets. What's been tried, what's known, where the gap is. Cite or link if available.]

- ...
- ...

**Critique notes** *(from prior-art exploration)*
- ...

---

## 4. Theory of the Problem  *(semi-fixed)*

Your mental model of *why* this question is tractable now and what mechanism is at play. Not a literature summary — your own framing.

[1–3 paragraphs.]

**Implicit assumptions this theory rests on:**
1. ...
2. ...
3. ...

---

## 5. Lines of Attack  *(semi-fixed)*

Two to four distinct strategies that could plausibly answer the question. Ranked by your current credence.

### 5.1 [Line A — short name]  `[planned]`
- **What it is:** ...
- **Why it might work:** ...
- **What would have to be true:** ...
- **Cost / time estimate:** ...

### 5.2 [Line B — short name]  `[planned]`
- ...

### 5.3 [Line C — short name]  `[conditional]`
- Pursued only if: ...

**Critique notes** *(from prior-art exploration)*
- ...

---

## 6. Immediate Experiment(s)  *(fully specified)*

### 6.1 [Experiment name]  `[committed]`

- **Hypothesis:** ...
- **Method:** ... (enough detail that someone could execute it)
- **Primary metric:** ...
- **Decision gate:** before declaring this experiment done, we will have answered: [...]
- **What each outcome implies:**
  - If result > τ: ...
  - If result < τ but directional: ...
  - If null: ...

#### Adversarial trio for 6.1
- **Confirmatory test:** [the natural experiment above]
- **Falsification test:** [the test that, if it failed, would kill the hypothesis]
- **Alternative-explanation test:** [what else could produce the expected result, and how we'd distinguish]

**Critique notes** *(from methodological critic)*
- ...

---

## 7. Conditional Next Steps  *(branching)*

Sketched, not committed. These are the trees we'd climb depending on what 6.1 shows.

- **If 6.1 confirms (effect > τ):** → run E2a `[conditional]` — [one-line description]
- **If 6.1 is directional but weak:** → run E2b `[conditional]` — [one-line description]
- **If 6.1 is null:** → return to Section 4 and reassess; candidate pivot is [...]

**Kill criteria for the whole line of inquiry:**
- We abandon this direction if: [...]
- We abandon if after [N experiments / time budget] we have not [...]

---

## 8. Speculative Horizon  *(speculative)*

If everything works, what does the end state look like? What's the deliverable, the publication, the system, the decision the user can finally make?

[1–2 paragraphs. Labeled speculative on purpose — this is the destination, not the path.]

---

## 9. Risks & Assumptions  *(revisited)*

| # | Risk / assumption | Likelihood | Impact | Mitigation / contingency |
|---|---|---|---|---|
| 1 | ... | M | H | ... |
| 2 | ... | ... | ... | ... |

**Critique notes** *(from pre-mortem)*
- ...

---

## 10. Decision Log

This proposal is a contract about how decisions get made. Actual decisions and findings live in the research log.

- Research log location: [path or link]
- Material updates to this proposal will be noted here:
  - [date] — initial draft
  - ...
