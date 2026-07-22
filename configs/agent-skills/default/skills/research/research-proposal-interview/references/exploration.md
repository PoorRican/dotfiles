# Exploration Guide

Three exploration moments are worth the latency. Each runs once, returns a condensed summary, and feeds the next interview question.

## When to spawn each

| Moment | Trigger | Sub-agent |
|---|---|---|
| After Section 3 (Prior Work) is roughed in | "Lines of attack" interview is about to start | **Prior-art scout** |
| After Section 6.1 (Immediate Experiment) is drafted | Before moving to conditional branches | **Methodological critic** |
| After Section 9 (Risks) is drafted | Before final coherence pass | **Pre-mortem agent** |

## Output discipline

Every exploration returns at most **6 bullet points, each one sentence**. The raw transcript stays in the sub-agent; only the condensed bullets enter the proposal (under the relevant section's "Critique notes") and the main chat.

After ingesting the bullets, **bring the most important finding back to the user as a question**, not a lecture. The exploration is interview fuel, not a separate report.

## Claude Code: sub-agent prompts

Spawn each via the Task tool. Pass the relevant proposal sections as context (read the file, paste the section into the sub-agent prompt). Do NOT pass the entire conversation history — the point is context isolation.

### Prior-art scout

```
You are a prior-art scout for a research proposal. Below is the current draft of the
"Question," "Theory of the problem," and "Lines of attack" sections.

Your job: identify in 6 bullets or fewer:
- Existing work that closely resembles any of the proposed lines of attack (reinvention risk).
- Existing work that contradicts the user's theory of the problem.
- A recent result the user appears unaware of that would change the framing.
- Any methodology in adjacent fields the user could borrow.

Use web search if available. Do NOT propose new experiments. Do NOT give a literature review.
Return ONLY the bullets, each one sentence, each citing a source if you have one.

[paste sections 1, 4, 5 here]
```

### Methodological critic

```
You are a methodological critic for a research proposal. Below is the proposed immediate
experiment (Section 6.1) and the success criteria (Section 2).

Your job: identify in 6 bullets or fewer the strongest threats to validity, in this order:
1. The most likely confounder.
2. The most likely measurement validity issue.
3. The most likely power / sample-size problem.
4. The strongest alternative explanation for the expected result.
5. The most under-specified part of the method.
6. (Optional) One thing the design does well that should be preserved.

Be specific. "Selection bias" is not a bullet; "selection bias from recruiting only
already-engaged users" is. Return ONLY the bullets.

[paste sections 2 and 6.1 here]
```

### Pre-mortem agent

```
You are running a pre-mortem on a research proposal. Below is the full proposal draft.

Imagine it is one year from now and the project failed to produce a credible answer to the
root question. In 6 bullets or fewer, identify the most likely causes of failure, ordered by
likelihood. For each, name (a) the cause and (b) one early-warning signal that would have
appeared in the first quarter.

Do not be exhaustive. Do not list risks the proposal already addresses. Find the ones it
misses.

[paste full proposal here]
```

## Claude.ai (no sub-agents): inline-pass equivalents

Without sub-agents, achieve context isolation by *bracketing*. Tell the user explicitly:

> "Pausing the interview to run a [prior-art / methodological / pre-mortem] check. Back in a moment."

Then perform the analysis in a single focused turn, using web search if available. Constraints:

- **Same 6-bullet ceiling.** Discipline matters more here, not less — without true context isolation, verbosity will pollute the rest of the interview.
- **Write the bullets directly into the proposal under "Critique notes," then close the bracket.** Tell the user "back to the interview" before asking the next question.
- **Do not let the inline pass become a tangent.** If a finding deserves real follow-up, that's the next interview question — don't expand the pass itself.

## After every exploration

Do exactly two things:

1. **Update the proposal's "Critique notes" subsection** with the bullets.
2. **Ask the user one question** that the most important finding raises. Examples:
   - Prior-art: "The scout flagged that [Group X] published something close to your Line A last year. Want to look at it before we commit to that line?"
   - Methodological: "The critic thinks your primary metric might be confounded by [Y]. Worth adding a secondary metric, or are you confident the confound is small?"
   - Pre-mortem: "The most likely failure mode is [Z], which we don't have a mitigation for. Want to add one to Section 9 now?"

This is what keeps exploration from becoming dead weight in the document.
