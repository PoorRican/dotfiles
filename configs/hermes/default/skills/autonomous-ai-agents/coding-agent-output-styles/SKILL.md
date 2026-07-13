---
name: coding-agent-output-styles
description: "Find, extract, and port coding-agent output style prompts across Claude Code, Pi, and OMP."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos]
metadata:
  hermes:
    tags: [Coding-Agent, Claude, Pi, OMP, Prompting, Output-Style]
    related_skills: [claude-code, codex, opencode]
---

# Coding Agent Output Styles

Use this skill when asked to locate built-in or plugin-provided output style prompts, compare them, or port an output style from one coding agent to another.

## Workflow

1. Identify the source agent and installed version before searching.
   - Claude Code: `command -v claude && claude --version`
   - Pi: `command -v pi && pi --help`
   - OMP: `command -v omp && omp --help`
2. Search readable config/plugin caches before reverse-engineering binaries.
   - Claude Code official plugin cache is often the best source for old/deprecated output styles.
   - Binary strings can confirm native remnants but should not be treated as the primary readable source when official plugin files exist.
3. Extract exact prompt text from the source file and report the path alongside the text.
4. When porting, prefer additive prompt injection over replacing the base system prompt.
5. Avoid stacking styles that already include each other; this duplicates behavioral markers and makes the agent noisy.

## Claude Code Internals Inspection

When you need to locate Claude Code's internal output style prompts, plugin recreations, or built-in strings:

### Plugin recreations (preferred readable source)

Claude Code migrated/deprecated some output styles into official plugins implemented as SessionStart hooks. Check the plugin marketplace cache first:

```bash
~/.claude/plugins/marketplaces/claude-plugins-official/plugins/*output-style/
```

Known locations:
- Explanatory: `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/explanatory-output-style/hooks-handlers/session-start.sh`
- Learning: `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/learning-output-style/hooks-handlers/session-start.sh`

The prompt is usually in `hooks-handlers/session-start.sh`, emitted as JSON under:
```json
hookSpecificOutput.additionalContext
```
Parse the heredoc JSON and report the `additionalContext`, not the shell wrapper.

### Native built-in strings (fallback)

For built-in/native output style strings, inspect the installed binary:

```bash
strings -n 5 /path/to/claude | grep -i -C 20 'Explanatory\|Learning\|outputStyle'
```

If exact extraction matters, do not rely only on `strings`: Claude Code native binaries may contain mixed UTF-8 and UTF-16LE string chunks. Read bytes around the match and decode both encodings. Look for style metadata near names such as `Explanatory`, `Learning`, `Proactive`, descriptions, and headings like `# Explanatory Style Active` or `# Learning Style Active`.

### Report provenance

Always distinguish:
- "official plugin recreation / SessionStart hook" for plugin prompts
- "native built-in prompt strings from installed Claude Code version X" for binary-extracted strings

## Agent-specific injection targets

### Claude Code

- One run: `claude --append-system-prompt <text>` or `claude --append-system-prompt-file <path>`.
- Persistent/project context: use Claude's normal `CLAUDE.md`, `.claude/settings*.json`, plugin, or custom command mechanisms depending on the scope.

### Pi (`pi`, `~/.pi/agent`)

- Persistent additive behavior: `~/.pi/agent/APPEND_SYSTEM.md`.
- Project additive behavior: `.pi/APPEND_SYSTEM.md`.
- One run: `pi --append-system-prompt <file-or-text>`.
- Toggleable behavior: use a local extension under `~/.pi/agent/extensions/` that registers `/output-style` and appends the selected prompt in `before_agent_start`. Use `templates/pi-omp-output-style-extension.ts` as the starter and change the import to `@earendil-works/pi-coding-agent` plus `AGENT_DIR` to `.pi/agent`.
- Avoid `SYSTEM.md` unless the task explicitly requires replacing/customizing the base prompt.

### Oh My Pi (`omp`, `~/.omp/agent`)

- One run: `omp --append-system-prompt <file-or-text>`.
- Persistent always-on behavior: prefer `~/.omp/agent/RULES.md`; OMP treats top-level `RULES.md` as an always-apply rule reinjected near current turns.
- Toggleable behavior: use a local extension under `~/.omp/agent/extensions/` that registers `/output-style` and appends the selected prompt in `before_agent_start`. Use `templates/pi-omp-output-style-extension.ts` as the starter.
- `~/.omp/agent/SYSTEM.md` exists, but is stronger and should be reserved for intentional core prompt customization.

## Dotfiles/Home Manager pattern

For this user's dotfiles repo, prefer keeping Pi/OMP output-style artifacts in `~/dotfiles/configs/{pi,omp}/agent/` and exposing them through Home Manager `home.file` out-of-store symlinks. The useful shape is:

- `configs/pi/agent/extensions/claude-output-styles.ts`
- `configs/pi/agent/output-styles/{explanatory,learning}.md`
- `configs/pi/agent/output-style.json`
- `configs/omp/agent/extensions/claude-output-styles.ts`
- `configs/omp/agent/output-styles/{explanatory,learning}.md`
- `configs/omp/agent/output-style.json`

Wire these with a small Home Manager module (for example `programs.coding-agent-output-styles`) that uses `config.lib.file.mkOutOfStoreSymlink` and `force = true`; import it from `nix/profiles/dev-extra.nix` with `lib.mkDefault true`. If the user wants the change live immediately, replace the existing files with symlinks to the dotfiles copies before waiting for `home-manager switch`.

## Pitfalls

- Do not add Claude's Explanatory and Learning prompts simultaneously. Learning already includes Explanatory behavior, so stacking both duplicates the `★ Insight` instruction.
- Do not claim a style is unavailable just because it is not in the CLI help. Search plugin caches, settings/config directories, and install roots.
- Do not rely on binary extraction as the authoritative prompt if an official plugin or documented file provides readable prompt text.
- Do not claim the plugin prompt is identical to the native built-in prompt unless you verified both. The Learning plugin may explicitly say it combines the unshipped Learning style with Explanatory functionality.
- Do not copy README summaries when the user asked for prompts; extract the actual injected context from the hook or binary.
- If a search returns too much noise, narrow to `~/.claude/plugins/marketplaces/claude-plugins-official/plugins` and then to `*output-style*`.
- Pi/OMP extension hook APIs may have changed since examples mentioning `systemPromptAppend`: Pi `0.80.3` expects `before_agent_start` handlers to return a full `systemPrompt` string (`event.systemPrompt + extra`), while OMP `16.3.x` expects a `systemPrompt` block array (`[...event.systemPrompt, extra]`). Preserve additive semantics even when the literal return field is no longer `systemPromptAppend`.

## References

- See `references/claude-output-style-prompts.md` for extracted Claude Code Explanatory/Learning prompt text and observed local paths.
