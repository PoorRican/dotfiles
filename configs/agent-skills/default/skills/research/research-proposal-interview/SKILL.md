---
name: research-proposal-interview
description: Conduct a structured research proposal interview when a collaborator needs help eliciting a question, assumptions, experiments and decision branches. For direct drafting from known content, use research-proposal-structure.
version: 1.0.2
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [research, proposal, interview, planning]
    related_skills: [research-proposal-structure, experiment-log-structure]
---

# Research Proposal Interview

Turn an incomplete research idea into a decision-useful proposal through focused questions, challenge, and incremental writing. Use `research-proposal-structure` for the artifact; use this skill for elicitation. For an existing plan, read it first and start at the largest gaps. Do not use the interview for a casual brainstorm, a literature review without an original research plan, or direct drafting when the content is already known.

## Workflow

1. Ask: “What's the end question this research needs to answer, and what's your current best guess at the answer?” Load `research-proposal-structure` and copy its `references/template.md` to the requested working file (default `proposal.md`). Fill the title and rough root question, and tell the user where the file is. If the user only wants discussion, do not create a file.
2. Interview section by section using the [interview guide](references/interview-guide.md), and the companion skill for section contents. Ask one focused question at a time. When an important assumption needs challenge, identify it, ask for evidence, and offer one falsifier or alternative; accept the answer rather than re-litigating. Synthesize substantive answers into the document as they emerge, show a short excerpt, then continue. If an answer remains vague after a push for specificity, mark it `[TODO: needs sharpening]` and move on.
3. When useful, run the [exploration prompts](references/exploration.md): prior art after drafting lines of attack, methodological critique after drafting the immediate experiment, and a pre-mortem after drafting risks. Use scoped passes if sub-agents are unavailable. Add condensed findings to the relevant critique notes and bring the most important one back as a question.
4. Once an immediate experiment is specified, consider the confirmatory test, a falsification test, and a test distinguishing an alternative explanation. Push to retain a falsifier alongside the confirmatory test.
5. When sections have content, check that the immediate experiment informs the root question, branches are explicit, kill criteria are real, and confidence tags are honest. Surface inconsistencies, apply fixes, and present the file path.

| Reference | Use |
|---|---|
| [Interview guide](references/interview-guide.md) | Section questions, follow-ups and challenge prompts. |
| [Exploration prompts](references/exploration.md) | Prior-art, methodological and pre-mortem passes. |
