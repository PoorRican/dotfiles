# Selection-first modal editor emulation research

Use this reference when evaluating whether one editor or plugin can reproduce another editor's modal interaction model, especially Vim/Neovim versus Helix/Kakoune.

## Core distinction

Do not reduce the problem to keybinding parity. Separate:

1. **Key spelling** — which keys invoke commands.
2. **Motion semantics** — word boundaries, line crossing, counts, wrapping, and inclusive/exclusive endpoints.
3. **Selection model** — whether a cursor is a point or a one-character selection; replace-selection versus extend-selection behavior.
4. **Composition grammar** — operator→motion versus selection→action.
5. **Selection cardinality** — one visual range versus native multiple ranges with a primary range.
6. **Integration surface** — LSP, Tree-sitter, registers, undo, macros, dot-repeat, text objects, surrounds, pickers, and buffer-local plugin maps.

A mapping-only implementation can reproduce key spelling while failing the remaining layers.

## Upstream baseline (dated pointer)

Dated 2026-08, Helix 25.07.1 at release commit `a05c151bb6e8e9c65ec390b0ae2afe7a5efd619b`: the selection-first and multiple-selection model is described in `book/src/usage.md`, the complete default key dispatcher is `helix-term/src/keymap/default.rs` (Select clones Normal and replaces motions with extending variants), and a Selection holds one or more ranges plus a primary index (`helix-core/src/selection.rs`). `f/F/t/T` cross lines, unlike Vim (`book/src/keymap.md`). Revalidate every pin against the installed release and current stable before reuse; current master docs may contain mappings absent from stable.

## Evaluation workflow

1. Record the installed editor version, latest stable release, and pinned source commit.
2. Enumerate the complete upstream dispatcher, not just the rendered “Movement” table. Include Goto, Match, View, Window, Space, bracket/unimpaired, search, syntax, and Select-mode overrides.
3. Inventory target-editor mappings in two ways:
   - static repository search for global, lazy, and buffer-local declarations;
   - runtime map dump after lazy startup, because declarations and effective precedence differ.
4. Compare by mode and by prefix. A two-key upstream leaf such as `gr` conflicts with every existing `gr…` mapping even when no exact `gr` mapping exists.
5. Audit terminal/multiplexer interception for Alt and Ctrl keys before blaming the editor.
6. Distinguish:
   - exact conflicts;
   - compatible keys with extra side effects;
   - prefix conflicts;
   - local-popup conflicts;
   - semantic conflicts caused by the composition model.
7. Inspect candidate implementations' source and issue tracker for unsupported features; README claims such as “Helix-like” are not completeness evidence.
8. Report adoption levels separately:
   - strict movement table;
   - all motion families;
   - complete interaction model.

## Neovim implementation findings (survey 2026-08; plugin status changes, revalidate)

No reviewed Neovim/Vim compatibility layer completely reproduced Helix's interaction model.

- A broad mapping plugin (`chtenb/helix.vim`) explicitly lacked generic multiple-selection, Tree-sitter and LSP-dependent support, had global side effects (`notimeout`, `whichwrap`, `gdefault`), used lowercase marks internally, altered Visual Escape and contained unsupported/TODO commands.
- An archived Visual-mode-based experiment (`00sapo/visual.nvim`) lacked macro support and native multiple selections; a word-motion plugin (`luiscassih/AniMotion.nvim`) deliberately covered only selection-first word motions.
- Prototype loaders that delete all existing Normal and buffer-local mappings are unsafe in plugin-heavy lazy-loaded configurations.

Treat these as references or partial components, not proof that full emulation is available.

## High-value conflict heuristics

- If the target editor uses bare comma as an immediate action while Neovim uses comma as `<leader>`, the entire leader namespace conflicts; both cannot be immediate simultaneously.
- If the target reserves Space as a submode, inspect literal `Space…` maps separately from `<leader>` maps.
- Selection-first `d/c/y/>/</=` replaces operator-pending composition, affecting surrounds, comments, Tree-sitter text objects, and plugin operators even when their top-level keys do not collide.
- A single Visual selection cannot model native multiple selections. A multicursor plugin adds another state engine and requires operation-by-operation adapters.
- Lazy and buffer-local mappings require policy-based application to editable buffers; a one-time global remap is not sufficient.
- Multiplexers commonly intercept Helix syntax motions such as `Alt-i`, `Alt-o`, `Alt-n`, `Alt-,`, and `Alt-.`.

## Recommended report shape

Lead with whether exact parity is possible. Then provide:

1. terminology and behavioral model;
2. three adoption levels;
3. candidate implementation comparison;
4. exact target-config conflicts with file/line evidence;
5. semantic/plugin side effects;
6. recommended architecture and the first unavoidable policy decision (often leader ownership).

Avoid presenting a broad keymap transplant as a low-risk configuration change.
