# Editor and multiplexer behavior

## Process-aware navigation

When a multiplexer binding intercepts a key in the active mode, an editor-only mapping cannot receive that key unless the multiplexer passes it through. Trace both sides: how the multiplexer detects the foreground application and forwards the key, and how the editor handles internal movement and invokes multiplexer movement at an edge. Exact process-name detection can fail through wrappers or nested shells.

Check key encoding and effective mappings in each relevant editor and multiplexer mode, including insert, terminal, prompt, scroll, and locked modes. Scoped bindings can change which component receives a key; autolocking around an editor is not equivalent to detecting the currently focused pane. Trace each direction separately: a pane-or-tab action can have asymmetric semantics. A successful command exit does not necessarily prove focus moved.

Check companion plugin releases and requirements independently of the parent project's example, which may lag. Inspect permissions, startup behavior, and whether edge navigation invokes an external executable. Separate released behavior from unreleased fixes.

## Modal emulation

Keybinding parity is not interaction-model parity. Compare motion boundaries, counts and endpoint semantics, point versus selection behavior, operator–motion versus selection–action grammar, multiple selections, and integration with undo, macros, text objects, and plugin operators. A single selection or mapping transplant cannot establish equivalent multiple-selection behavior.

Scope the upstream dispatcher inventory to the requested parity; inspect mode overrides and prefix conflicts, not just the visible movement table. Compare static mappings with effective mappings after lazy loading, including buffer-local and popup contexts. A two-key leaf can conflict with longer mappings sharing its prefix even without an exact mapping collision. Check terminal and multiplexer interception before attributing missing keys to the editor. Report exact conflicts and semantic differences separately from superficial key matches.

An immediate comma action conflicts with a comma leader namespace; a Space submode can conflict with literal Space-prefixed mappings even when the leader uses another key. Check Alt-based motions against actual multiplexer bindings and terminal encoding rather than assuming they reach the editor.
