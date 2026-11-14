---
name: brainstorming
description: Develop a scoped design collaboratively from an idea, comparing approaches and clarifying requirements. Use when the design needs exploration; a visual companion can help with diagrams and mockups.
---

# Brainstorming

Brainstorming turns an idea into a design suited to its scope. Without checking context and constraints, a plausible design can solve the wrong problem or combine independent work into an unmanageable specification.

1. Inspect relevant project files and existing patterns. Before detailed questions, assess scope: if the request spans independent subsystems, identify their relationships and sequence, then focus on a tractable part.
2. Ask clarifying questions to understand purpose, constraints, and success criteria. Ask one at a time when exploring an open-ended choice; multiple choice can make answering easier. Don't ask for information already available.
3. Where meaningful alternatives exist, propose two or three approaches, with trade-offs and a recommendation with reasons. Keep unrelated refactoring out of scope.
4. Present the design in sections scaled to their complexity. Cover relevant architecture, components, interfaces, data flow, error handling, and testing. Ask whether each section looks right; return to clarification and revise as needed.
5. When a written specification is appropriate, write the validated design at the location agreed with the user. Check for placeholders, contradictions, ambiguous requirements, and scope too large for one plan; fix issues inline. Ask the user to review it, incorporate requested changes, and repeat the review before proceeding.
6. Once the design is agreed, hand off to implementation planning if the task needs a plan. Don't begin implementation when the user asked only for design.

| Reference | Use when |
|---|---|
| [Visual companion](visual-companion.md) | A mockup, diagram, or visual comparison would clarify a question. |
