---
name: hermes-tui-development
description: "Inspect and extend Hermes Agent TUI capabilities, launch flags, hotkeys, composer input, and terminal behavior."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [hermes-agent, tui, typescript, ink, cli, keybindings]
    related_skills: [debugging-hermes-tui-commands, node-inspect-debugger, systematic-debugging]
---

# Hermes TUI Development

## Overview

Use this skill when a user asks what Hermes TUI mode enables/allows, how launch flags/config flow into the TUI, how hotkeys/input handling works, or how to add/modify TUI composer behavior such as Helix/Kakoune/Vim-style modal input.

Hermes TUI spans Python CLI launch code, a gateway/JSON-RPC bridge, and an Ink/TypeScript frontend. Prefer inspecting the live installed source or bundle over answering from memory, especially when Hermes is installed through Nix.

## When to Use

- User asks about `hermes --tui`, TUI capabilities, allowed flags, environment variables, or config fields.
- User wants to enable or add a TUI input mode/keybinding/editor behavior.
- TUI hotkeys, paste/copy, mouse, terminal modes, or composer cursor behavior need debugging.
- The working Hermes checkout is not available and you must inspect the installed package or Nix store build.
- A change touches `ui-tui/`, `tui_gateway/`, or Python launcher/parser code for TUI startup.

## Investigation Workflow

1. **Load the protected `hermes-agent` skill first** when the task is about configuring/extending Hermes Agent. Do not edit bundled/protected skills.
2. **Identify the running install.** Check `hermes config show`, `which hermes`, environment variables such as `HERMES_TUI_DIR`, and package paths reported by config output.
3. **Inspect parser and launcher truth.** Relevant Python files are usually:
   - `hermes_cli/_parser.py` for top-level/chat flags accepted by `--tui`.
   - `hermes_cli/main.py::_launch_tui()` for env vars forwarded to the Node TUI.
4. **Inspect the TUI frontend source/bundle.** In a checkout use `ui-tui/src/`. In a Nix install, derive source paths from the store if needed.
5. **Map frontend behavior to source files** before proposing changes:
   - `ui-tui/src/components/textInput.tsx` — composer editing, paste/copy, mouse selection, cursor movement, undo/redo, pass-through keys.
   - `ui-tui/src/app/useInputHandlers.ts` — global hotkeys, scrolling, interrupt/exit, yolo toggle, session switcher, voice toggle.
   - `ui-tui/src/lib/platform.ts` — action modifier, copy shortcut, voice key parsing, reserved chords.
   - `ui-tui/src/gatewayTypes.ts` — frontend-known config fields.
   - `ui-tui/src/content/hotkeys.ts` — user-facing hotkey table.
   - `ui-tui/src/lib/terminalModes.ts` and `src/entry.tsx` — terminal mode reset/lifecycle behavior.

## Nix-Packaged Hermes TUI Source Discovery

When `/home/.../hermes-agent/ui-tui` is absent but the active install is Nix-packaged:

```bash
# Find the hermes-agent output and its derivation
nix-store --query --deriver /nix/store/<hash>-hermes-agent-<version>

# Show the derivation; look for the hermes-tui derivation input and HERMES_REVISION
nix show-derivation /nix/store/<hash>-hermes-agent-<version>.drv

# Show the TUI derivation; its env usually has src=/nix/store/<hash>-ui-tui
nix show-derivation /nix/store/<hash>-hermes-tui-0.0.1.drv
```

Then inspect `/nix/store/<hash>-ui-tui/src/...` for TypeScript sources, or `$HERMES_TUI_DIR/dist/entry.js` for the exact bundled runtime.

## TUI Launch Capabilities to Audit

`hermes --tui` / `HERMES_TUI=1 hermes` can forward many options into the TUI. Verify exact support in `_parser.py` and `_launch_tui()`. Common capabilities include:

- `--model` / `--provider`
- `--toolsets`
- `--skills`
- `--resume` / `--continue`
- `--worktree`
- `--checkpoints`
- `--pass-session-id`
- `--max-turns`
- `--accept-hooks`
- `chat --query` and `chat --image`
- `--verbose` / `--quiet` tool progress mapping
- `--dev` TypeScript-source mode

Report these as observed from source, not as guaranteed stable API unless the docs also confirm them.

## Composer/Input Architecture

The TUI composer is a custom React/Ink `TextInput`, not Python `prompt_toolkit`. Current behavior is mostly readline/Emacs-like plus mouse support:

- printable insertion and bracketed/multiline paste
- grapheme-aware cursor movement
- left/right arrows and multiline up/down navigation
- word movement/delete, delete-to-start/end, kill-to-end
- Home/End, undo/redo, select-all
- text selection and clipboard copy/paste
- mouse click cursor placement, drag selection, right-click copy/paste
- pass-through for global keys like Ctrl+C, Ctrl+X, Tab, PageUp/PageDown, Esc, and voice toggles

Global handlers own transcript scrolling, interrupt/exit/redraw/editor open, session switcher, completions, queue/history, yolo toggle, and voice recording.

## Adding Helix/Kakoune/Vim-like Input Modes

Do not claim this is a config toggle unless the current source proves it. If no modal implementation exists, treat it as a TUI feature.

For a concrete porting reference, see `references/helix-kakoune-modal-input-port.md`. It summarizes the `/home/swe/repos/pi-modal` OMP modal-editor implementation and maps its pure-engine/adapter split onto Hermes TUI's `TextInput` composer architecture.

Recommended approach:

1. Add a frontend/backed config field such as:
   ```yaml
   display:
     tui_input_mode: default  # default | helix | kakoune
   ```
2. Extend config typing/sync so the TUI receives it (`gatewayTypes.ts`, config sync/store, backend config schema/defaults as appropriate).
3. Add a small composer modal state machine (`insert`, `normal`, `select`) near `TextInput`, not scattered one-off key cases.
4. Keep overlays and global semantics intact: approval/clarify prompts, pagers, model/session pickers, Ctrl+C interrupt, PageUp/PageDown transcript scroll, and voice toggle must still win where appropriate.
5. Start with a small useful subset: Esc→normal, `i`/`a` insert, `h/j/k/l` movement, `w/b/e` word movement, `x` select line, `d` delete selection, `y` yank, `p` paste, `u` undo, and preserve existing Shift/Alt+Enter newline behavior.
6. Add tests for pass-through collisions, especially `Esc`, `Tab`, `Ctrl+C`, paste, and voice shortcuts. `TextInput.shouldPassThroughToGlobalHandler()` is a key collision point.

## ANSI/Input-Corruption Debugging

When the composer receives numeric `...;...M` fragments, `[I` / `[O`, or keyboard and mouse input appear to freeze after pane/focus changes, use `references/ansi-input-leak-debugging.md`. It contains protocol signatures, active-install/revision checks, the split-SGR differential tokenizer probe, terminal-mode lifecycle checks, issue-search vocabulary, and guidance for separating a Hermes parser defect from a multiplexer mouse-state defect.

## Pitfalls

- Always identify the active packaged TUI revision before analyzing a source checkout. With Nix, `command -v`, `readlink -f`, `HERMES_TUI_DIR`, `HERMES_REVISION`, and the named flake lock are stronger evidence than the HEAD of a nearby repository.
- Do not treat visible ANSI-like composer text as model output or ordinary user text. Classify SGR mouse, focus, and bracketed-paste signatures first, then trace the tokenizer → key parser → `TextInput` path.
- A multiplexer can be the trigger without being the primary defect: pane switching legitimately creates focus reports, while a TUI tokenizer may incorrectly turn split protocol bytes into printable text.
- The TUI dist bundle can be huge; prefer source files when available, and read only focused sections of `dist/entry.js` when source is unavailable.
- On Nix, the installed `$HERMES_TUI_DIR` may contain only `dist/`; use derivations to find the source input.
- `terminal.modal_mode` in Hermes config is not proof of TUI modal composer support; verify it is read by the TUI before telling the user it can enable Helix/Kakoune mode.
- Do not add keybindings that silently collide with global handlers or overlay prompts.
- Platform modifier behavior differs: macOS action modifier is Cmd/Super/Meta depending on terminal support; Linux/Windows action modifier is usually Ctrl.
- Rebuild and type-check the TUI after changes; for source checkouts use `npm --prefix ui-tui run build` or the repository's documented command.

## Verification

For capability audits:

- Cite exact files/fields inspected.
- Distinguish current observed implementation from intended/stable public API.
- If using Nix, report the locked revision or `HERMES_REVISION` when relevant.

For input/keybinding changes:

1. Run TypeScript type-check/build.
2. Run focused TUI tests if present (`textInput`, `useInputHandlers`, terminal/platform tests).
3. Manually smoke-test `hermes --tui` in a real terminal for cursor, paste, mouse, and overlay behavior.
4. Verify existing global shortcuts and approval prompts still work.
