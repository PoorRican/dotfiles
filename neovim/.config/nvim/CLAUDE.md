# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

This is a modular Neovim configuration using **lazy.nvim** as the plugin manager. Each plugin has its own configuration file, making it easy to add, remove, or modify plugins.

### Directory Structure

```
lua/
├── cfg/                    # Core configuration
│   ├── general.lua         # Leader key, options, autocmds
│   ├── commands.lua        # Custom commands
│   ├── ui.lua              # UI settings (cursor, line numbers, colors)
│   ├── lazy.lua            # Plugin manager setup & plugin imports
│   └── pkglock.json        # Plugin lock file
├── core/                   # Core functionality plugins
├── ui/                     # UI/visual plugins
├── lsp/                    # Language server configurations
│   └── init.lua            # Main LSP setup, imports per-language configs
└── utils/                  # Shared utilities
    ├── functions.lua       # Helper functions
    ├── remaps.lua          # Keymap helper (map, noremap, map_virtual)
    └── icons.lua           # Icon definitions for UI elements
```

## Key Configuration Details

- **Leader key**: `,` (set in `cfg/general.lua`)
- **Indentation**: Tabs (not spaces), 2-character width
- **Folding**: Treesitter-based expression folding
- **Auto-save**: Triggers on `InsertLeave` and `FocusLost`
- **Auto-reload**: Enabled for external coding agents (`autoread` + `checktime`)
- **Local plugin dev**: Plugins in `~/.local/src` load locally instead of from GitHub

## Adding a New Plugin

1. Create a new file in `core/` (for functionality) or `ui/` (for visuals)
2. Return a lazy.nvim plugin spec table:
   ```lua
   return {
     "author/plugin-name",
     event = "BufReadPost",  -- lazy loading trigger
     opts = {},              -- passed to plugin.setup()
   }
   ```
3. Add `require("core/your-plugin")` to the spec list in `cfg/lazy.lua`

## Adding a New LSP

1. Create a new file in `lsp/` (e.g., `lsp/rustls.lua`)
2. Return a table with the server configuration
3. The `lsp/init.lua` handles the common setup pattern

## Keymap Utilities

Use `utils/remaps.lua` for keybindings:
```lua
local remap = require("utils.remaps")
remap.noremap("n", "<leader>x", ":SomeCommand<CR>", "Description")
remap.map_virtual({ "<leader>g", group = "git" })  -- which-key group
```
