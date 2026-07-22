---
name: claude-code-internals-inspection
description: Inspect installed Claude Code internals and official plugin recreations to locate prompts, output styles, built-in strings, and migration hooks.
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos]
metadata:
  hermes:
    tags: [Claude, Claude-Code, Output-Styles, Prompt-Inspection, Plugins]
    related_skills: [claude-code]
---

# Claude Code Internals Inspection

Use this when the user asks to find Claude Code's internal prompts, output style instructions, official plugin prompt recreations, or similar local Claude Code implementation details. Prefer updating the broader `claude-code` skill when it is writable; this skill exists for prompt/style inspection details.

## Workflow

1. Identify the installed Claude Code executable and version:
   ```bash
   command -v claude
   claude --version
   readlink -f "$(command -v claude)"
   ```
2. Check official plugin recreations first. Claude Code migrated/deprecated some output styles into official plugins implemented as SessionStart hooks:
   ```bash
   ~/.claude/plugins/marketplaces/claude-plugins-official/plugins/*output-style/
   ```
   The prompt is usually in `hooks-handlers/session-start.sh`, emitted as JSON under:
   ```json
   hookSpecificOutput.additionalContext
   ```
   Parse the heredoc JSON and report the `additionalContext`, not the shell wrapper.
3. For built-in/native output style strings, inspect the installed binary:
   ```bash
   strings -n 5 /path/to/claude | grep -i -C 20 'Explanatory\|Learning\|outputStyle'
   ```
4. If exact extraction matters, do not rely only on `strings`: Claude Code native binaries may contain mixed UTF-8 and UTF-16LE string chunks. Read bytes around the match and decode both encodings. Look for style metadata near names such as `Explanatory`, `Learning`, `Proactive`, descriptions, and headings like `# Explanatory Style Active` or `# Learning Style Active`.
5. Report provenance clearly:
   - "official plugin recreation / SessionStart hook" for plugin prompts
   - "native built-in prompt strings from installed Claude Code version X" for binary-extracted strings

## Known locations

- Explanatory plugin recreation:
  `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/explanatory-output-style/hooks-handlers/session-start.sh`
- Learning plugin recreation:
  `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/learning-output-style/hooks-handlers/session-start.sh`

## Pitfalls

- Do not claim the plugin prompt is identical to the native built-in prompt unless you verified both. The Learning plugin may explicitly say it combines the unshipped Learning style with Explanatory functionality.
- Do not copy README summaries when the user asked for prompts; extract the actual injected context from the hook or binary.
- If a search returns too much noise, narrow to `~/.claude/plugins/marketplaces/claude-plugins-official/plugins` and then to `*output-style*`.
