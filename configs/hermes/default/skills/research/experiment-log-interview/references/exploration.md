# Exploration Guide

Three exploration moments are worth the latency. Each runs once, returns a condensed summary, and feeds the next interview question.

## When to spawn each

| Moment | Trigger | Sub-agent |
|---|---|---|
| After Section 4 (raw evidence) is filled, before user gives interpretation | Just before opening Section 5 | **Skeptical-reader pass** |
| Before Section 5 is finalized | After user has drafted the headline and confidence | **Alternative-explanation generator** |
| Before Section 7 is finalized | After user has stated next experiment | **Calibration check** |

## Output discipline

Every exploration returns at most **6 bullet points, each one sentence**. The raw transcript stays in the sub-agent; only the condensed bullets enter the entry (under the relevant section's "Critique notes") and the main chat.

After ingesting the bullets, **bring the most important finding back to the user as a question**, not a lecture.

## Claude Code: sub-agent prompts

Spawn each via the Task tool. Pass only the relevant entry sections — not the full conversation. Context isolation is the point.

### Skeptical-reader pass

```
You are a skeptical reader of an experiment log entry. Below are sections 1 through 4
of the entry — the question, pre-registration, what was actually done, and the raw
evidence. You do NOT have the user's interpretation.

Your job: produce in 6 bullets or fewer your own answers to:
- What's the headline finding the evidence actually supports?
- What's a finding the evidence does NOT support but a careless reader might infer?
- What diagnostic is conspicuously missing?
- What deviation in section 3 most threatens the validity of the pre-stated thresholds?
- What's the most generous reading of the result, and is it warranted?
- What's the least generous reading, and is it warranted?

Return ONLY the bullets, each one sentence. Do not editorialize beyond the bullets.

[paste sections 1, 2, 3, 4]
```

### Alternative-explanation generator

```
You are generating alternative explanations for the result of an experiment. Below
are sections 1 through 5 of the log entry, including the user's headline finding and
confidence rating.

Your job: list in 6 bullets or fewer the most plausible mechanisms OTHER than the
user's preferred one that would produce the observed result. For each, name (a) the
alternative mechanism and (b) one specific test or observation that would distinguish
it from the user's preferred explanation.

Be specific. "Confounding variable" is not a bullet; "confounding from the data being
collected during a known regime change in Q3 2024" is. Return ONLY the bullets.

[paste sections 1 through 5]
```

### Calibration check

```
You are running a calibration check on an experiment log entry. Below is the full
entry, including the headline finding, confidence rating, and proposed next experiment.

Your job: in 6 bullets or fewer, judge whether:
- The confidence rating is proportionate to the evidence and surviving threats.
- The headline finding is appropriately scoped (not overreaching, not underclaiming).
- The "implications" section is warranted by the finding, or is an inferential leap.
- The proposed next experiment is the one that maximally reduces uncertainty about
  the root question, or just the next obvious one.
- Any tag (`[high]`, `[exploratory]`, etc.) appears miscalibrated.
- Any section is conspicuously empty or superficial.

Return ONLY the bullets. Each should name the issue and recommend a specific edit.

[paste full entry]
```

## Claude.ai (no sub-agents): inline-pass equivalents

Without sub-agents, achieve context isolation by *bracketing*. Tell the user:

> "Pausing the interview to run a [skeptical-reader / alt-explanation / calibration] check. Back in a moment."

Then do the analysis as a single focused turn. Constraints:

- **Same 6-bullet ceiling.** Verbosity here pollutes the rest of the interview.
- **Write the bullets directly into the entry under "Critique notes" in the relevant section, then close the bracket.** Tell the user "back to the interview" before asking the next question.
- **For the skeptical-reader pass specifically:** mentally suppress what the user has said about interpretation. The whole value of the pass is reading the evidence on its own terms. If you can't do that honestly, skip the pass and tell the user.

## After every exploration

Do exactly two things:

1. **Update the relevant "Critique notes" subsection** with the bullets.
2. **Ask the user one question** raised by the most important finding. Examples:
   - Skeptical-reader pass: "The reader thinks the evidence supports a narrower claim than your draft headline. Want to look at the gap before you commit to the headline?"
   - Alt-explanation: "The strongest alternative is [X], and we don't have a test to rule it out. Add a follow-up experiment to section 7, or accept [X] as a surviving threat in section 5?"
   - Calibration check: "Your `[high]` confidence looks generous given the surviving threats. Want to talk through whether `[medium]` is more honest?"

This is what keeps exploration from becoming dead weight in the entry.
