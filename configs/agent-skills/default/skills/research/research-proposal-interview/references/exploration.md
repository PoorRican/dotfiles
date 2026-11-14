# Exploration prompts

Use these focused passes when useful. Pass the relevant proposal sections, not the entire conversation. Summarize findings in at most six bullets, add them to the relevant critique notes, and bring the most important finding back as one question.

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

