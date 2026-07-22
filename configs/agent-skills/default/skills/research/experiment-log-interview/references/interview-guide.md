# Interview Guide

Question bank and challenge protocol for the experiment-log-interview skill. Organized by section, with notes on which mode applies.

## The balanced challenge protocol

Apply this after every substantive answer. Same shape as the proposal skill, but the *focus* shifts depending on which section you're in.

| Section | What to challenge |
|---|---|
| 2 (pre-reg) | The **plan** — is the metric the right metric? is the threshold defensible *before* seeing data? |
| 3 (as-run) | The **honesty of the delta** — what deviations might the user be downplaying? |
| 4 (raw evidence) | The **completeness** — what diagnostic would a skeptic demand that's missing? |
| 5 (interpretation) | The **claim** — does the headline outrun the evidence? what alternative explanations remain? |
| 6 (implications) | The **logical chain** — does this finding actually move the parent proposal, or is the connection asserted? |
| 7 (decision) | The **next step** — is this the experiment that maximally reduces uncertainty about the root question, or just the next obvious one? |

The four-step protocol itself is unchanged: name the implicit assumption → ask for the basis → propose one alternative or falsifier → accept the response and update the doc.

## Mode-aware traversal

- **Mode A (pre-reg):** sections 1, 2 only. Stop after section 2. Confirm to the user that the entry is now pre-registered and waiting for results.
- **Mode B1 (post-run, was pre-registered):** sections 3, 4, 5, 6, 7, 8, 9. Confirm section 2 once with the user but never edit it.
- **Mode B2 (post-run, post-hoc):** sections 1, 2 (reconstructed and tagged `[exploratory]`), then 3–9. Be explicit about the post-hoc reconstruction and its evidentiary cost.
- **Mode C (revision):** add an addendum block. Ask only what's needed for the addendum: what changed, why, which sections are superseded, what the updated finding and confidence are. Do not re-interview prior sections.

## Section-by-section questions

### Section 1 — Header

**Primary question:**
- "In one sentence, what specific question is this experiment trying to answer? Phrase it as a question, not a topic."

**Follow-ups:**
- "Which decision gate in your proposal does this inform? If none, is this experiment actually worth running right now?"

**Challenge prompt:**
- If the question is broader than the experiment can answer: "Your question is bigger than your experiment. What's the narrower question this run can actually resolve?"

### Section 2 — Pre-registration  *(Mode A and B2)*

**Primary questions, in order:**
- "What's the hypothesis, stated as a claim that could be wrong?"
- "What's your prior — your honest expectation before running? Give a rough credence."
- "What's the exact primary metric, including the slice it's measured on?"
- "What threshold counts as 'yes'? What threshold counts as 'no'? What's the inconclusive band?"
- "Before you run, commit to what you'll do in each plausible outcome regime. What does each outcome imply?"

**Challenge prompts:**
- "Could you defend that threshold to a skeptic *before* seeing data? If not, what's a more defensible one?"
- "If you got exactly the result you expect, would you have learned anything? If the experiment can only confirm, not surprise you, why are you running it?"
- For Mode B2 specifically: "You've already seen results. Be honest — would you have picked this metric and threshold *before* running? If not, mark this entry exploratory and tag the confidence accordingly."

### Section 3 — What was actually done  *(Modes B1, B2)*

**Primary question:**
- "What did you actually run, and where does it differ from what you planned in section 2?"

**Follow-ups:**
- "For each deviation, why did it happen and does it affect the validity of the pre-stated interpretations?"
- "Where's the code commit, the data snapshot, and the run ID? The entry needs to be reproducible."

**Challenge prompts:**
- "Anything you tweaked mid-run that you haven't mentioned? Even a parameter sweep narrowed late, a slice excluded, a seed swapped — log it."
- "Does any of these deviations mean the pre-registered thresholds in section 2 no longer apply cleanly? If so, say so explicitly in the entry."

### Section 4 — Raw evidence  *(Modes B1, B2)*

**Primary question:**
- "What's the primary metric value, with whatever interval applies and the explicit comparison?"

**Follow-ups:**
- "What secondary metrics did you track, and what do they show?"
- "What diagnostics would a skeptic demand — sample sizes per slice, residual distributions, training curves, ablations?"
- "What plots tell the story? Each one needs a caption that stands alone."

**Challenge prompts:**
- "You said it 'improved.' Improved from what to what, on which slice, with what variance?"
- "What's a diagnostic you didn't run that a careful reviewer would ask for? Run it now or note it as a loose end."

*(After this section, trigger the skeptical-reader pass — see exploration.md.)*

### Section 5 — Interpretation  *(Modes B1, B2)*

**Primary question:**
- "In one sentence, with no hedges in that sentence, what's the headline finding?"

**Follow-ups:**
- "What's your confidence — high, medium, low, speculative — and why?"
- "Which threats to validity survived this experiment? Be specific, not generic."

**Challenge prompts (the heart of this skill):**
- "What's an alternative mechanism that would produce the same observed result? How would you distinguish it?"
- "Strip out the headline and read only sections 3 and 4. Would a careful reader arrive at the same claim, or have you connected dots that don't quite touch?"
- "Your confidence is `[high]` but you have three surviving threats. Are those threats really small enough to leave the rating unchanged?"

*(Before finalizing this section, trigger the alternative-explanation generator — see exploration.md.)*

### Section 6 — Implications  *(Modes B1, B2)*

**Primary question:**
- "How does this finding update the parent proposal — root question, theory, or a specific line of attack?"

**Follow-ups:**
- "Does any line of attack get killed or weakened by this? Don't only look for confirmations."
- "Does this open a conditional branch that wasn't active before?"

**Challenge prompt:**
- "If section 6 is empty or vague, you may have run an experiment that didn't actually inform anything. Is that the case, or is the connection real but unstated?"

### Section 7 — Decision & next step  *(Modes B1, B2)*

**Primary question:**
- "What's the next experiment, and why this one rather than another?"

**Follow-ups:**
- "Which decision gate did this resolve, and which branch is now active?"
- "What's your confidence that the next experiment is the right one to run?"

**Challenge prompts:**
- "Is the next experiment the one that maximally reduces uncertainty about the root question, or just the next obvious one in the sequence you'd already imagined?"
- "If you ran the next experiment and it produced its expected result, would *that* move the root question, or just inch it?"

*(Before finalizing this section, trigger the calibration check — see exploration.md.)*

### Section 8 — Loose ends  *(Modes B1, B2)*

**Primary question:**
- "What did you notice during this experiment that you didn't investigate?"

**Follow-ups:**
- "What would you do differently next time?"
- "Anything a collaborator should weigh in on?"

**Challenge prompt:**
- If section 8 is empty: "Empty loose ends usually means optimism, not absence. What's one thing that nagged at you that you didn't write down?"

### Section 9 — Audit trail  *(Modes B1, B2)*

**Primary question:**
- "Drop in the links: pre-reg commit, results commit, dashboard URL, notebook paths, related entries."

**Challenge prompt:**
- "If a reviewer six months from now opened this entry, could they reproduce the result from these links alone? If not, what's missing?"

### Addendum  *(Mode C only)*

**Primary questions:**
- "What changed since the original entry?"
- "Why — new evidence, a bug, reinterpretation?"
- "Which sections of the original entry are now superseded?"
- "What's the updated finding, and what's the updated confidence?"

**Challenge prompt:**
- "If the change is a reinterpretation rather than new evidence, what new information justifies the new view? Reinterpretation without new input is often motivated reasoning — be sure."

## Anti-patterns to avoid

- **Editing a frozen pre-registration silently.** Section 2 is read-only after results. Use Mode C (addendum) instead.
- **Multi-question turns.** One question, wait, respond, move on.
- **Stacking challenges.** One challenge per answer.
- **Letting `[high]` confidence stand without justification.** Push for the calibration reasoning.
- **Empty section 6.** An experiment whose implications can't be stated didn't earn its place in the log.
- **Skipping the doc update.** If you've gone three turns without editing the file, stop and write before asking the next question.
- **Treating null results as second-class.** Same rigor, same sections, same exploration passes.
