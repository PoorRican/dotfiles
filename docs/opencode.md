# opencode.nvim

Neovim integration for [opencode](https://github.com/sst/opencode) - an AI coding assistant.

## Official Documentation

- **Plugin**: https://github.com/nickjvandyke/opencode.nvim
- **opencode CLI**: https://opencode.ai
- **Configuration**: https://codecompanion.olimorris.dev

## Setup

The plugin is configured in `lua/core/opencode.lua` and requires:
- `opencode` CLI installed (`brew install opencode`)
- `OPENCODE_API_KEY` environment variable (configured in `.zshrc`)

## Keymaps

| Keymap | Description |
|--------|-------------|
| `<C-a>` | Ask opencode with current selection/cursor context |
| `<C-x>` | Select from prompt library and actions |
| `<C-.>` | Toggle opencode terminal |
| `go` | Operator mode - add range to opencode |
| `goo` | Add current line to opencode |

### Visual Mode
In visual mode, `<C-a>` and `<C-x>` work the same way but include the selected text as context.

## Context Placeholders

The plugin supports these placeholders in prompts:

| Placeholder | Context |
|-------------|---------|
| `@this` | Operator range or visual selection, else cursor position |
| `@buffer` | Current buffer |
| `@buffers` | All open buffers |
| `@visible` | Visible text |
| `@diagnostics` | Current buffer diagnostics |
| `@quickfix` | Quickfix list |
| `@diff` | Git diff |
| `@marks` | Global marks |

## Built-in Prompts

Access via `<C-x>`:

- `diagnostics` - Explain `@diagnostics`
- `diff` - Review git diff
- `document` - Add comments to `@this`
- `explain` - Explain `@this` and context
- `fix` - Fix `@diagnostics`
- `implement` - Implement `@this`
- `optimize` - Optimize for performance
- `review` - Review for correctness
- `test` - Add tests for `@this`

## Usage Examples

### Ask a question
```
<C-a>How do I center a div in CSS?
```

### Explain selected code
1. Select code in visual mode
2. Press `<C-x>` → select `explain`

### Fix LSP diagnostics
1. Move cursor to error
2. Press `<C-a>` → type `fix this`

### Add line to opencode
```
goo
```
Then type your prompt and press Enter.

## Commands

| Command | Description |
|---------|-------------|
| `:checkhealth opencode` | Verify setup |

## Troubleshooting

1. Run `:checkhealth opencode` to diagnose issues
2. Ensure `opencode` is installed: `opencode --version`
3. Verify API key: `echo $OPENCODE_API_KEY`
4. Start opencode manually: `opencode` in terminal
