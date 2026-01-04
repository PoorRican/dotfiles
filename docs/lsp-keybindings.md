# LSP Keybindings Reference

This document covers the LSP (Language Server Protocol) keybindings in the nvim configuration, with mappings to PyCharm equivalents for users transitioning from JetBrains IDEs.

## New LSP Keybindings (from `on_attach`)

These keybindings are active when an LSP server attaches to a buffer. They are defined in `nvim/.config/nvim/lua/lazy-config.lua:160-173`.

| Nvim Keybinding | Action | PyCharm Equivalent |
|-----------------|--------|-------------------|
| `gd` | Go to definition | `Cmd+B` or `Cmd+Click` |
| `gD` | Go to declaration | `Cmd+B` (same in PyCharm) |
| `gi` | Go to implementation | `Cmd+Option+B` |
| `gr` | Find references | `Option+F7` (Find Usages) |
| `K` | Hover documentation | Hover mouse or `F1` (Quick Documentation) |
| `Ctrl+k` | Signature help | `Cmd+P` (Parameter Info) |
| `<leader>rn` | Rename symbol | `Shift+F6` |
| `<leader>ca` | Code action | `Option+Enter` (Show Intention Actions) |
| `[d` | Previous diagnostic | `F2` then `Shift+F2` |
| `]d` | Next diagnostic | `F2` |
| `<leader>e` | Show diagnostic float | Hover over error or `Cmd+F1` |

## Existing Telescope LSP Keybindings

These provide fuzzy-finder interfaces for LSP features. Defined in `nvim/.config/nvim/lua/keys.lua:23-26`.

| Nvim Keybinding | Action | PyCharm Equivalent |
|-----------------|--------|-------------------|
| `<leader>fd` | Telescope: LSP definitions | `Cmd+B` with popup |
| `<leader>fs` | Telescope: Workspace symbols | `Cmd+Option+O` (Go to Symbol) |
| `<leader>fr` | Telescope: LSP references | `Option+F7` (Find Usages window) |
| `<leader>fu` | Telescope: Incoming calls | `Ctrl+Option+H` (Call Hierarchy) |

## Trouble Diagnostics Keybindings

Trouble provides a structured diagnostics panel. Defined in `nvim/.config/nvim/lua/keys.lua:69-86`.

| Nvim Keybinding | Action | PyCharm Equivalent |
|-----------------|--------|-------------------|
| `<leader>xx` | Toggle all diagnostics | `Cmd+6` (Problems tool window) |
| `<leader>xw` | Buffer diagnostics | Problems filtered to current file |
| `<leader>xd` | Buffer diagnostics (alias) | Same as above |
| `<leader>xl` | Location list | N/A (Vim-specific) |
| `<leader>xq` | Quickfix list | N/A (Vim-specific) |
| `<leader>xs` | LSP symbols panel | `Cmd+7` (Structure tool window) |

## Relationship Between Keybindings

The new `on_attach` keybindings and existing Telescope keybindings complement each other:

```
Direct Jump (on_attach)          Fuzzy Search (Telescope)
─────────────────────────────    ─────────────────────────────
gd  → jump to definition         <leader>fd → search definitions
gr  → jump to first reference    <leader>fr → search all references
gi  → jump to implementation     (no telescope equivalent)
```

**When to use which:**
- Use `gd`, `gr`, `gi` for quick, direct navigation when you know what you want
- Use `<leader>f*` Telescope variants when you want to preview multiple results or search fuzzy
- Use `<leader>x*` Trouble variants when you want a persistent panel of diagnostics/symbols

## Quick Reference Card

```
Navigation                 Refactoring              Diagnostics
──────────────────────    ──────────────────────   ──────────────────────
gd   → definition         <leader>rn → rename      [d   → prev diagnostic
gD   → declaration        <leader>ca → code action ]d   → next diagnostic
gi   → implementation                              <leader>e  → float diag
gr   → references                                  <leader>xx → trouble panel
K    → hover docs
Ctrl+k → signature help
```

## Note on Leader Key

The default leader key is `\` (backslash). So `<leader>rn` means pressing `\` then `rn`.
The currently configured leader key is `,`.

To check your leader key: `:echo mapleader`
