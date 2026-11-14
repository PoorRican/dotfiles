---
name: using-superpowers
description: Use when starting a task to find and apply available skills, before responding or acting. Covers skill selection, loading, and adapting workflows to the active runtime.
---

# Using Skills

Skills provide task-specific guidance on demand. At the start of a task, check the available skill names and descriptions for a match, including before asking clarifying questions or exploring. Load explicitly requested or relevant skills using the active runtime's supported mechanism; read their current content rather than relying on memory. If a loaded skill does not fit, do not force it onto the task.

In OMP, read `skill://<name>` with the `read` tool. In Hermes, use `skills_list` to discover skills and `skill_view` with `name` to load one; use `file_path` to load a linked file. If these tools are unavailable, use the runtime's documented mechanism rather than inventing a tool.

When more than one skill applies, use process guidance first (for example, brainstorming for an open design or debugging for a bug), then task-specific implementation guidance. Read any referenced instructions needed for the work; follow the applicable procedure and track its checklist where appropriate. Some workflows prescribe steps tightly, while others are patterns to adapt to the task.

Skills do not override the host's instruction hierarchy or the user's applicable constraints. If guidance conflicts, follow the higher-priority instructions. If a skill assumes unavailable tooling, use a supported equivalent where appropriate; do not fabricate tool calls.
