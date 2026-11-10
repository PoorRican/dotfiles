# Process-aware editor–multiplexer navigation

Use this reference when researching one key family that must traverse editor windows, multiplexer panes, and multiplexer tabs without mode switching.

## Core architectural constraint

A static multiplexer keybind consumes the key before the foreground editor sees it. An editor-only plugin therefore cannot create seamless navigation while that same key remains globally bound by the multiplexer. The integration needs a process-aware router on the multiplexer side:

1. The multiplexer intercepts the directional key.
2. A router identifies the focused pane's foreground application.
3. If it is the editor, the router writes the same key into that pane.
4. The editor first attempts an internal window move.
5. At the editor edge, the editor invokes the multiplexer movement action.
6. For non-editor panes, the router invokes the multiplexer action directly.

This preserves the sequence `editor window A -> editor window B -> multiplexer pane -> adjacent tab` and the reverse path, assuming the editor retains its last-focused window.

## Research checklist

- Inspect the live editor and multiplexer versions before using current docs.
- Read the actual multiplexer key scopes. Local mode bindings may override shared bindings.
- Determine which directions use pane-only movement versus pane-or-tab movement; do not assume all four directions share tab semantics.
- Trace both halves of the integration: router behavior in non-editor panes and editor edge behavior.
- Verify how the router detects the foreground program: exact executable name, pane metadata, shell subprocess, title, or explicit editor state.
- Check key encoding for Alt/Meta. A router may synthesize an ESC-prefixed sequence or Kitty keyboard protocol sequence.
- Audit Normal, Insert, Terminal, prompt, and multiplexer scroll modes separately. A Normal-only editor map can turn a forwarded Alt key into an unintended Escape in Insert mode.
- Inspect plugin permissions and startup lifecycle. Pre-granting permissions avoids prompts but may not eliminate first-launch pane flashes.
- Pin released WASM/plugin URLs and source revisions. Pair public README guidance with tagged implementation.
- Verify whether editor-edge movement shells out synchronously to a CLI and whether the executable is available inside the pane environment.

## Zellij/Neovim case study (2026-08)

Observed 2026-08 on the then-current Zellij and Neovim releases; revalidate versions, plugin releases and source pins before reuse.

A robust composition was:

- Zellij-side router: `hiasr/vim-zellij-navigator` 0.3.0, minimum Zellij 0.42.2.
- Neovim-side movement: `mrjones2014/smart-splits.nvim`; latest stable checked was v2.1.0, but Zellij stability fixes existed only on the post-release branch.
- Horizontal router commands: `move_focus_or_tab`.
- Vertical router commands: `move_focus` when preserving a configuration where only left/right cross tabs.
- Router `move_mod`: `alt` when the public key family is `Alt+h/j/k/l`.
- Neovim setting: `zellij_move_focus_or_tab = true`; tagged source only applies tab-aware movement to left/right.

The Zellij router uses `list_clients()` to inspect the focused command, recognizes exact `nvim` or `vim`, writes the configured key into editor panes, and otherwise calls Zellij's movement API. It requests `WriteToStdin`, `ChangeApplicationState`, and `ReadApplicationState`. Its options must be repeated consistently on every `MessagePlugin` invocation because the first invocation supplies the loaded instance's configuration.

The parent smart-splits README still pointed to router 0.2.1, whose plugin ran `zellij action list-clients`; router 0.3.0 instead used the native plugin API and explicitly documented smart-splits support. Always check the companion project's latest release rather than inheriting the parent's pinned download URL.

Zellij's own dispatcher exposed an important asymmetry: `MoveFocusOrTab Left/Right` tries pane movement before previous/next tab, but `MoveFocusOrTab Up/Down` switches tabs directly. Previous/next tab movement wraps cyclically. Therefore use pane-or-tab only horizontally unless direct vertical tab switching is intended.

smart-splits resizing is also layered: counts/amounts apply to Neovim windows, but its Zellij backend discards the amount and calls `zellij action resize increase <direction>`. Preset Zellij split size is unsupported. Navigation and resizing cannot share the same Alt chord; use a separately encoded modifier family.

Pinned evidence:

- Router release: https://github.com/hiasr/vim-zellij-navigator/releases/tag/0.3.0
- Router source: https://github.com/hiasr/vim-zellij-navigator/tree/6d2a3e0c1d6c64daf1ed19e9ea0849259b71f180
- Editor integration release: https://github.com/mrjones2014/smart-splits.nvim/releases/tag/v2.1.0
- Minimal alternative: https://github.com/swaits/zellij-nav.nvim/tree/91cc2a642d8927ebde50ced5bf71ba470a0fc116

## Pitfalls found

- The latest stable editor plugin can lag unreleased mux-backend fixes. In smart-splits v2.1.0, Zellij edge detection moved left then right and ignored the requested direction; the post-release branch removed pane-ID probing, made Zellij edge behavior stop, and disabled unsupported split-at-edge behavior. Report tagged and branch behavior separately.
- A zero exit status from a multiplexer movement action does not prove focus changed. Some backends special-case success when pane IDs are unavailable, so trace no-neighbor behavior explicitly.
- `shared_except "locked"` makes routing available across most Zellij modes but not Locked mode. Separately audit which Neovim modes actually map the forwarded chord.
- Autolocking the multiplexer while the editor runs is not equivalent to process-aware routing. After focus leaves a still-running editor, the multiplexer can remain locked and stop handling the navigation key in the destination pane.
- A `VimLeave` hook handles editor exit, not editor focus loss.
- Preserve special multiplexer modes deliberately. For example, direct navigation in scroll mode may need to remain local while the process-aware router is scoped to non-scroll modes.
- Exact foreground-command matching can fail for wrappers, aliases that exec a different process, nested shells, or elevated launches.
- Do not recommend a Neovim-only navigator until proving how the multiplexer-bound key reaches Neovim.
