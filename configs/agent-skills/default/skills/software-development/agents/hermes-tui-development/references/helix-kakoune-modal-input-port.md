# Helix/Kakoune modal composer port reference

Session-derived reference for porting a selection-first modal input mode into Hermes TUI.

## Reference implementation inspected

A working external implementation was found in `/home/swe/repos/pi-modal`, an OMP extension named `omp-modal-navigation`.

Key files:

- `README.md` — supported modes and keybindings.
- `src/index.ts` — extension lifecycle, commands, status/help UI.
- `src/modal/editor.ts` — editor adapter around OMP `CustomEditor`.
- `src/modal/engine.ts` — pure modal state machine.
- `src/modal/buffer.ts` — prompt text/cursor/selection mutation helpers.
- `src/modal/keymap.ts` — terminal input to printable/named token decoding.
- `src/modal/motions.ts` — grapheme/word/line motions.
- `src/modal/registers.ts` — default and named registers.
- `docs/superpowers/specs/2026-07-05-helix-prompt-core-design.md` — scoped Helix prompt-core design.

## Existing OMP modal architecture

```text
pure engine             adapter/editor               extension hook
-----------             --------------               --------------
ModalEngine      ->     ModalEditor        ->        pi.on("session_start")
PromptBuffer            CustomEditor wrap            ctx.ui.setEditorComponent()
motions/registers       insert delegates             ctx.ui.setStatus()
```

Current implemented behavior in that reference:

- Modes: `normal`, `insert`, `select`, `surround`, `register`, `history`.
- Motions: `h/j/k/l`, arrows, `w/b/e`, `0/$`, `f<char>`, Home/End, Up/Down.
- Editing: `i/a/I/A`, `c`, `d/D`, `y/Y`, `p/P`, `u/U`.
- Registers: default register plus `a-z` via `"` prefix.
- Selection model: single primary selection with `anchor + cursor`.
- UX: mode status (`--`, `[i]`, `[v]`, `[s]`, `["]`, `[h]`), help/status commands, selection highlighting.
- History bridge: `Ctrl+k` enters a history mode; insert mode delegates to the host editor so normal paste/autocomplete/submit behavior is preserved.

## Hermes TUI mapping

Hermes TUI does not currently expose an OMP-style prompt-editor extension hook equivalent to `ctx.ui.setEditorComponent`. The practical porting target is the built-in frontend composer:

- `ui-tui/src/components/textInput.tsx` — text editing, cursor movement, paste/copy, mouse selection, undo/redo, pass-through keys.
- `ui-tui/src/app/useInputHandlers.ts` — global hotkeys, overlays, transcript scroll, interrupts, session switcher, completions/history/queue, voice.
- `ui-tui/src/components/appLayout.tsx` — main composer render site and prompt/status layout.
- `ui-tui/src/content/hotkeys.ts` — user-facing hotkey table.
- `ui-tui/src/hooks/useInputHistory.ts` and `ui-tui/src/hooks/useCompletion.ts` — history/completion integration.
- `hermes_cli/config.py` — default `display` config fields.
- `website/docs/user-guide/tui.md` — docs for launch/config/keybindings.

Recommended implementation shape:

1. Port/adapt the OMP pure engine into frontend-only modules, e.g. `ui-tui/src/lib/modal/` or `ui-tui/src/lib/inputMode/`.
2. Keep the engine pure: text, cursor, anchor/selection, registers, mode, pending input, undo/redo.
3. Add a config field such as:
   ```yaml
   display:
     tui_input_mode: default  # default | helix | kakoune
   ```
4. Wire `TextInput` with an `inputMode?: 'default' | 'helix' | 'kakoune'` prop and keep default behavior byte-for-byte where possible.
5. Let global Hermes TUI keys win before modal handling: `Ctrl+C`, `Ctrl+X`, `Tab`, `Shift+Tab`, `PageUp/PageDown`, `Esc` where it closes overlays/selection, configured voice shortcuts, and external editor open.
6. Preserve insert-mode compatibility with current TUI behavior: paste handling, image/file-path normalization, completion, submit/newline semantics, and mouse selection should not regress.
7. Show mode state in prompt/status chrome instead of relying only on hidden internal mode.

## Test strategy

Use TDD for this class of change. Start by porting/adapting pure engine tests from `/home/swe/repos/pi-modal/test/engine.test.ts`, `motions.test.ts`, and `registers.test.ts`, then add Hermes-specific adapter tests around `TextInput` helper functions and pass-through collisions.

Important regression cases:

- `Esc` exits modal insert/select without breaking overlay dismissal or queue-edit cancel.
- `/` still types slash commands in insert/default modes; prompt-local search should only be active in normal mode if implemented.
- `Tab` still applies completions and does not get swallowed by modal mode.
- `Ctrl+C` still interrupts/clears/exits globally.
- `Ctrl+X` still opens/deletes live-session switcher/queue paths.
- PageUp/PageDown and wheel continue transcript scrolling.
- Paste and bracketed paste still route through existing collapse/image/file-drop logic.
- Voice toggle shortcuts pass through even when the composer is focused.
- Mouse selection/copy/paste keeps working or is explicitly disabled only while a modal selection is active.

## Pitfalls from the reference

- The OMP implementation currently has mixed normal-mode motion semantics: `h/j/k/l/f` move the cursor, while `w/b/e/0/$` create selections. Decide the Hermes prompt-local invariant before expanding counts/search/text objects.
- The OMP design notes call out `moveWordEndForward` as needing true word-end semantics before broadening the motion surface.
- Do not document Alt/Ctrl keybindings until the Hermes/Ink key decoder is proven to distinguish them reliably in target terminals.
- Do not add a generic plugin mechanism just to support this unless there is an independent Hermes TUI extension API requirement; the existing Hermes TUI composer is the current integration seam.
