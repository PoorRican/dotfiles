# ANSI / Mouse / Focus Sequences Leaking into the TUI Composer

Use this reference when a Hermes Ink TUI shows numeric `...;...M` fragments, `[I` / `[O`, apparent random typing, or simultaneous keyboard/mouse lockups after pane, tab, focus, resize, or heavy-render transitions.

## Recognize the protocol signatures

- `ESC[<btn;col;rowM` / `...m`: SGR mouse press/release/motion reports.
- ESC-less tails such as `46M`, `35;46M`, or long semicolon/digit bursts: a mouse report was split and its continuation reached the text path.
- `ESC[I` / `ESC[O`, often visible as `[I` / `[O`: DEC focus-in/focus-out reports.
- `ESC[200~` / `ESC[201~`: bracketed-paste delimiters; investigate separately.

Do not initially blame the shell, model output, or multiplexer. The multiplexer may generate the focus transition that triggers the bug, while the TUI tokenizer or terminal-mode lifecycle mishandles the resulting bytes.

## Investigation sequence

1. Identify the **active packaged revision**, not merely a nearby checkout:
   - `command -v hermes`
   - `readlink -f "$(command -v hermes)"`
   - `hermes --version`
   - inspect `HERMES_TUI_DIR` and `HERMES_REVISION`
   - for Nix, compare these with the named flake input's locked revision.
2. Record terminal stack and versions: terminal emulator, `$TERM`, multiplexer version, shell, and whether focus/pane switching is the trigger.
3. Search upstream issues and PRs using protocol terms, not only the user's wording: `SGR mouse`, `mouse sequence leak`, `focus reporting`, `composer lock`, `stdin starvation`, `raw mode teardown`, `terminal mode reset`, `backpressure`.
4. Compare the installed revision with fixes; prove ancestry with Git rather than assuming a release contains a fix.
5. Trace this pipeline:
   - terminal/multiplexer emits focus or mouse report
   - Ink stdin reader chunks bytes
   - incomplete-sequence watchdog flushes tokenizer state
   - keypress parser classifies sequence versus text
   - `TextInput` inserts printable residue
6. Inspect terminal lifecycle independently: raw-mode transitions, mouse disable/re-enable, signal/exit backstops, startup reset, `SIGCONT`, resize, and focus-in handling.
7. Check rendering/backpressure paths because stdin, mouse, focus, and keyboard events share the same event loop. ANSI leakage and apparent input freeze can be two parts of one failure chain.

## Minimal differential reproduction

A decisive tokenizer probe uses one split SGR packet:

```ts
const tokenizer = createTokenizer({x10Mouse: true})
console.log(tokenizer.feed('\x1b[<0;35;'))
console.log(tokenizer.flush())
console.log(tokenizer.feed('46M'))
```

Broken behavior:

- `flush()` emits the incomplete `ESC[<0;35;` sequence.
- The continuation is emitted as text: `{type: 'text', value: '46M'}`.

Correct behavior:

- The first flush emits nothing and retains multi-byte CSI state.
- Feeding `46M` emits one complete mouse sequence/event with no printable text.
- Only a truly lone Escape should use ESC-delay timeout semantics; an already-started CSI/OSC/DCS/APC/SS3 sequence must not become text merely because a timer fired.

For a historical revision, create a temporary detached worktree and import both old and current tokenizer implementations into one temporary TypeScript probe. Run the same chunks through both. Remove the temporary worktree afterward. This is stronger evidence than source inspection alone.

## Hermes fixes to look for

The durable fix class is broader than regex-filtering leaked fragments:

- state-aware tokenizer flush that reassembles split control sequences
- bounded truncation valve for a partial that never completes
- disabling mouse tracking before raw-mode teardown
- reasserting modes after raw-mode re-entry
- process-exit and signal terminal-reset backstops
- stdin repump after readable-handler errors
- render-frame coalescing while stdout is backpressured

Treat regex sinks for semicolon/digit/`M` fragments as defensive hardening, not the primary fix: they risk false positives and cannot cover every split boundary.

## Workarounds and reporting

- Prefer updating the exact named Hermes flake/package input once a containing revision is verified.
- To reduce event volume while preserving ordinary clicks, `display.mouse_tracking: wheel` enables click + wheel without drag/hover; verify support in the installed revision first.
- For diagnosis, disabling mouse tracking entirely is stronger but intentionally removes TUI mouse interaction. Focus-report leakage can still remain on an unfixed tokenizer.
- Distinguish a Hermes parser defect from a separate multiplexer mouse-state/latch defect. A multiplexer issue may explain swallowed clicks but not ESC-less SGR coordinates entering the composer.
- Report exact old/new revisions, issue/PR links and states, the split-packet differential output, focused tests run, and any relevant test failure. Do not claim every freeze path is fixed merely because the ANSI tokenizer regression passes.
