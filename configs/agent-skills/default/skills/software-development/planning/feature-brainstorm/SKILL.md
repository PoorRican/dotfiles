---
name: feature-brainstorm
description: Multi-phase brainstorming for complex feature implementations using parallel sub-tasks. Use when the user asks to brainstorm, design, or plan a complex feature, wants to explore implementation approaches, or needs architectural analysis before coding. Triggers on phrases like "brainstorm feature", "design implementation", "explore approaches", "plan architecture", or "how should we implement".
---

# Feature Brainstorm

A structured three-phase approach to brainstorming complex feature implementations using parallel Sonnet sub-tasks for exploration, validation, and feasibility assessment.

## Overview

```
Phase 1: EXPLORE    → Launch parallel sub-tasks to analyze codebase
Phase 2: VALIDATE   → Launch parallel sub-tasks to research and validate ideas
Phase 3: ASSESS     → Launch parallel sub-tasks to evaluate feasibility and create proposals
```

## Before Starting

1. Confirm the feature scope with the user
2. Identify the codebase location (ask if not provided)
3. Create a working directory: `mkdir -p /home/claude/brainstorm-sessions`

## Phase 1: Exploration

Launch 3-5 parallel sub-tasks using Sonnet to explore the codebase from different angles.

**Sub-task prompt template:**
```
You are exploring a codebase to understand how to implement: [FEATURE]

Your specific focus: [EXPLORATION_ANGLE]

Codebase location: [PATH]

Instructions:
1. Explore relevant files using view and bash tools
2. Document key findings in /home/claude/brainstorm-sessions/explore-[ANGLE].md
3. Note: existing patterns, relevant abstractions, potential integration points, dependencies

Keep findings concise and actionable.
```

**Exploration angles to assign:**
- **Architecture**: Overall structure, module boundaries, data flow patterns
- **Similar features**: Existing features with comparable patterns
- **Data layer**: Models, schemas, database interactions, state management
- **API surface**: Endpoints, interfaces, contracts that would be affected
- **Testing patterns**: How similar features are tested, test infrastructure

**Example sub-task launch:**
```bash
claude --model claude-sonnet-4-20250514 --print \
  "You are exploring a codebase to understand how to implement: user authentication with OAuth.
   Your specific focus: Architecture - overall structure and module boundaries.
   Codebase location: /path/to/repo

   Explore relevant files and document findings in /home/claude/brainstorm-sessions/explore-architecture.md"
```

After all exploration sub-tasks complete, synthesize findings:
```bash
cat /home/claude/brainstorm-sessions/explore-*.md > /home/claude/brainstorm-sessions/exploration-summary.md
```

## Phase 2: Validation

Based on exploration findings, launch 3-4 parallel sub-tasks to validate ideas and perform research.

**Sub-task prompt template:**
```
You are validating an implementation approach for: [FEATURE]

Exploration context:
[PASTE KEY FINDINGS FROM PHASE 1]

Your validation focus: [VALIDATION_ANGLE]

Instructions:
1. Research best practices using web search if needed
2. Validate against codebase patterns in [PATH]
3. Document findings in /home/claude/brainstorm-sessions/validate-[ANGLE].md
4. Flag any concerns, risks, or open questions

Be critical - identify potential problems early.
```

**Validation angles to assign:**
- **Pattern alignment**: Does the approach fit existing codebase patterns?
- **Technical research**: Best practices, library options, security considerations
- **Edge cases**: Error handling, failure modes, boundary conditions
- **Performance**: Scalability concerns, potential bottlenecks
- **Dependencies**: Impact on existing code, breaking changes

**After validation sub-tasks complete:**
```bash
cat /home/claude/brainstorm-sessions/validate-*.md > /home/claude/brainstorm-sessions/validation-summary.md
```

## Phase 3: Assessment

Launch 2-3 parallel sub-tasks to assess feasibility and create concrete proposals.

**Sub-task prompt template:**
```
You are creating an implementation proposal for: [FEATURE]

Context:
- Exploration findings: [SUMMARY]
- Validation results: [SUMMARY]

Your assessment focus: [ASSESSMENT_ANGLE]

Instructions:
1. Create a concrete implementation proposal
2. Estimate effort and complexity
3. Identify prerequisites and blockers
4. Document in /home/claude/brainstorm-sessions/assess-[ANGLE].md

Output format:
## Approach Summary
## Implementation Steps
## Effort Estimate (T-shirt size + reasoning)
## Risks and Mitigations
## Prerequisites
```

**Assessment angles to assign:**
- **MVP approach**: Minimum viable implementation, fastest path
- **Robust approach**: Production-ready, handles edge cases
- **Alternative approach**: Different architecture or pattern (if applicable)

**After assessment sub-tasks complete:**
```bash
cat /home/claude/brainstorm-sessions/assess-*.md > /home/claude/brainstorm-sessions/assessment-summary.md
```

## Synthesis

After all phases, create a final brainstorm report:

1. Read all summary files
2. Create `/home/claude/brainstorm-sessions/[FEATURE]-brainstorm-report.md` with:
   - Executive summary
   - Recommended approach with justification
   - Alternative approaches considered
   - Key risks and mitigations
   - Suggested next steps
   - Open questions for user

Present the report to the user and discuss.

## Sub-task Management

**Launching sub-tasks:**
```bash
# Run in background, capture output
claude --model claude-sonnet-4-20250514 --print "[PROMPT]" > output.md 2>&1 &
```

**Waiting for completion:**
```bash
wait  # Wait for all background jobs
```

**Checking results:**
```bash
ls -la /home/claude/brainstorm-sessions/
```

## Customization

Adjust the number and focus of sub-tasks based on:
- **Small feature**: 2-3 sub-tasks per phase
- **Medium feature**: 3-4 sub-tasks per phase
- **Large/complex feature**: 4-5 sub-tasks per phase

Skip phases if appropriate:
- Skip Phase 2 if the implementation is straightforward
- Combine Phase 2 and 3 for well-understood patterns
