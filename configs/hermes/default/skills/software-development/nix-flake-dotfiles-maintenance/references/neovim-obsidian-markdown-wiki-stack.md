# Neovim Obsidian/wiki Markdown stack in this dotfiles repo

Use this note when adding or repairing Obsidian/wiki-oriented Markdown editing in the user's dotfiles-managed Neovim setup.

## Desired stack

For Obsidian-native Markdown/wiki editing, the user chose these as invariants:

- `obsidian-nvim/obsidian.nvim` for Obsidian vault workflows, wikilinks, daily notes, backlinks, and workspace-aware commands.
- `markdown-oxide` as the Markdown LSP, replacing `marksman` for Obsidian-style Markdown/wiki linking behavior.
- `MeanderingProgrammer/render-markdown.nvim` for inline Markdown rendering.

## Dependency wiring pattern

In this repo, keep plugin setup minimal and scoped:

- Add lazy specs under `configs/neovim/lua/core/` or `configs/neovim/lua/ui/` and wire them from `configs/neovim/lua/cfg/lazy.lua`.
- Add Mason package names in `configs/neovim/lua/core/mason.lua` for editor-managed binaries.
- Add declarative packages in `nix/modules/neovim.nix` for Home Manager-managed availability outside Mason.
- For this stack, include both `markdown-oxide` and `tree-sitter` declaratively when available.
- For `render-markdown.nvim`, keep explicit lazy dependencies on `nvim-treesitter/nvim-treesitter` and `nvim-tree/nvim-web-devicons`.

## nvim-treesitter main-branch API pitfall

If `render-markdown.nvim` plus newer Neovim hits Tree-sitter errors such as `attempt to call method 'range' (a nil value)`, inspect the `nvim-treesitter` branch/API before blaming render-markdown. Moving `nvim-treesitter` and `nvim-treesitter-textobjects` to `main` may require rewriting old `require("nvim-treesitter.configs").setup(...)` configuration.

For the main-branch API, configure parsers with `require("nvim-treesitter").install(...)`, start Tree-sitter from a `FileType` autocmd with `pcall(vim.treesitter.start, args.buf)`, and set the indent expression explicitly, for example:

```lua
vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
```

Make sure the `tree-sitter` CLI is installed declaratively, because parser installation can depend on it.

## Verification sequence

After edits, verify all three layers rather than stopping at Nix eval:

1. Home Manager evals for affected hosts, e.g. `cbox`, `emc`, `dgx`, and `mbp` when available.
2. Lazy/plugin load in a headless Markdown buffer:
   - `obsidian.nvim` loaded
   - `render-markdown.nvim` loaded
   - `nvim-treesitter` loaded
3. Markdown LSP attachment in a headless Markdown buffer; expect `markdown_oxide` to attach.
4. Tree-sitter activation in a Markdown buffer; do not accept plugin-installed as proof that parsing/rendering works.

## Reporting

When the working tree is already dirty, explicitly distinguish files intentionally touched for the Neovim Markdown/wiki task from unrelated staged/untracked changes. Do not stage or commit unless the user asks.