---
name: writing-plans
description: Use when turning a spec or requirements for multi-step work into an actionable implementation plan, before implementation.
---

# Writing Plans

Write for a skilled developer who has little context about the codebase or problem domain. Document the files, interfaces, behavior, and checks needed to execute the work without guessing.

## Scope and decomposition

1. If the spec covers multiple independent subsystems, suggest separate plans, each producing working, testable software.
2. Before defining tasks, map files to create or modify and their responsibilities. Design clear boundaries and interfaces; follow established codebase patterns rather than restructuring unrelated code. Files that change together should live together; split by responsibility.
3. A task is the smallest unit that carries its own test cycle and is worth a fresh reviewer's gate. Fold setup, configuration, scaffolding, and documentation into the task whose deliverable needs them. Split where a reviewer could meaningfully reject one task while approving its neighbor. Each task ends with an independently testable deliverable.
4. Order dependent tasks and specify the interfaces each consumes and produces. A task's implementer may see only their own task, so include exact names, parameter and return types, and relevant constraints from neighboring tasks.

## Plan document

Use a header with the feature name, goal, architecture, and tech stack. Include global constraints from the spec (such as version floors, dependency limits, naming, copy and platform requirements) with exact values; they apply to every task. Save the plan where the user or project expects it; `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md` is a default, not a requirement.

For each task, use a shape like:

```markdown
### Task N: [Component Name]

**Files:** Create, modify, and test paths, with relevant line ranges where useful.
**Interfaces:** Consumes [signatures from earlier tasks]; produces [names, parameter and return types for later tasks].

- [ ] Step 1: [specific test and expected behavior]
- [ ] Step 2: [command and expected failure, where applicable]
- [ ] Step 3: [implementation and necessary code or precise instructions]
- [ ] Step 4: [verification command and expected result]
```

Give enough concrete detail for each step: exact paths and commands where known, expected outcomes, and code or precise behavior where essential decisions would otherwise be left to the implementer. Avoid TBDs, vague error handling, unexplained edge cases, references to undefined types, and “similar to Task N” in place of details an independently assigned worker needs. Match detail to the work rather than requiring complete code for every step.

## Review and handoff

After writing the complete plan, review it against the spec: map each requirement to a task, fix omissions and scope creep, scan for placeholders, and check that later names, types and signatures match their definitions. Fix issues inline. When an independent review is appropriate, fill and use the [plan document reviewer prompt](plan-document-reviewer-prompt.md).

After saving, offer the applicable execution approach: task-by-task delegation with review between tasks, or inline execution in batches with checkpoints. Follow the user's requested execution mode and any host constraints; do not assume delegation or a commit is required.
