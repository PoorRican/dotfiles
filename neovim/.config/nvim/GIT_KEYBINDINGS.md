# Git Keybindings

This document describes all git-related keybindings configured in Neovim.

## Plugins

- **gitsigns.nvim** - Git signs in the gutter and hunk operations
- **vim-fugitive** - Comprehensive git wrapper
- **vim-flog** - Git branch viewer

## Hunk Navigation

| Key | Action | Description |
|-----|--------|-------------|
| `]c` | Next hunk | Jump to the next git hunk (change) |
| `[c` | Previous hunk | Jump to the previous git hunk (change) |

## Hunk Actions

All hunk actions use the `,h` prefix (leader = `,`).

| Key | Action | Description |
|-----|--------|-------------|
| `,hs` | Stage hunk | Stage the current hunk under cursor |
| `,hs` (visual) | Stage selected | Stage selected lines in visual mode |
| `,hr` | Reset hunk | Reset/discard changes in current hunk |
| `,hr` (visual) | Reset selected | Reset selected lines in visual mode |
| `,hp` | Preview hunk | Show inline diff preview of hunk |
| `,hb` | Blame line | Show full git blame for current line |
| `,hu` | Undo stage hunk | Undo staging of a hunk |

## Buffer Actions

| Key | Action | Description |
|-----|--------|-------------|
| `,hS` | Stage buffer | Stage all changes in current file |
| `,hR` | Reset buffer | Reset all changes in current file |
| `,hc` | **Commit file** | **Stage current file and open commit buffer** |

## Diff & Toggle

| Key | Action | Description |
|-----|--------|-------------|
| `,hd` | Diff this | Show diff for current file |
| `,hD` | Diff HEAD | Show diff against HEAD |
| `,tb` | Toggle blame | Toggle inline git blame |
| `,td` | Toggle deleted | Toggle showing deleted lines |

## Vim-Fugitive Commands

These are command-line commands provided by vim-fugitive:

| Command | Description |
|---------|-------------|
| `:G` or `:Git` | Open git status buffer |
| `:Git add %` | Stage current file |
| `:Git commit` | Create a commit |
| `:Git commit %` | Commit current file only |
| `:Gdiffsplit` | Open diff in split view |
| `:Git blame` | Show git blame |
| `:Git log` | Show git log |
| `:Flog` | Open git branch viewer |

### Git Status Buffer (`,:G`)

In the git status buffer, you can use these keybindings:

- `s` - Stage file under cursor
- `u` - Unstage file under cursor
- `=` - Toggle inline diff
- `cc` - Create commit
- `-` - Stage/unstage file (toggle)
- `X` - Discard changes

## Quick Workflows

### Quick commit current file
1. `,hc` - Opens commit buffer with current file staged
2. Write commit message
3. `:wq` to save and commit

### Stage and commit specific hunks
1. `,hp` - Preview the hunk
2. `,hs` - Stage the hunk (repeat for multiple hunks)
3. `:Git commit` - Commit staged changes

### Review changes before committing
1. `]c` / `[c` - Navigate between hunks
2. `,hp` - Preview each hunk
3. `,hs` - Stage hunks you want to commit
4. `,hc` - Commit staged changes

### Stage specific lines
1. Select lines in visual mode (`V`)
2. `,hs` - Stage only selected lines
3. `:Git commit` - Commit staged changes

## Configuration

The git keybindings are configured in:
- `neovim/.config/nvim/lua/ui/signs.lua` - Gitsigns configuration and keybindings
- `neovim/.config/nvim/lua/core/git.lua` - Fugitive and Flog plugin setup
