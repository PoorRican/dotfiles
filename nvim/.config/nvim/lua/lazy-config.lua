return {
  -- [[ Filesystem & Navigation ]]
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('nvim-tree').setup({})
    end,
    -- Example lazy-loading:
    -- cmd = "NvimTreeToggle",
    -- keys = { { "<leader>e", "<cmd>NvimTreeToggle<CR>", desc = "Toggle NvimTree" } },
  },

  -- [[ UI & Ricing ]]
  { 'mhinz/vim-startify' },
  { 'DanilaMihailov/beacon.nvim' },
  {
    "xero/evangelion.nvim",
    lazy = false,
    priority = 1000,
  }, -- Colorscheme
  {
    "scottmckendry/cyberdream.nvim",
    lazy = false, -- Load colorschemes early
    priority = 1000,
  },
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { { 'nvim-tree/nvim-web-devicons', lazy = true } },
    config = function()
      require('lualine').setup({})
    end,
  },

  -- [[ Development & Productivity ]]
  {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    cmd = "Telescope", -- Lazy load on command
    config = function()
      require('telescope').setup({})
      -- Add your telescope mappings here, e.g.:
      -- local builtin = require('telescope.builtin')
      -- vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
      -- vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
    end,
  },
  { 'majutsushi/tagbar', cmd = "TagbarToggle" },
  { 'Yggdroot/indentLine' },
  { 'tpope/vim-fugitive', cmd = {"Git", "G"} },
  { 'junegunn/gv.vim', cmd = "GV" },
  {
    "rbong/vim-flog",
    lazy = true,
    cmd = { "Flog", "Flogsplit", "Floggit" },
    dependencies = {
      "tpope/vim-fugitive",
    },
  },
  {
    'windwp/nvim-autopairs',
    event = "InsertEnter", -- Load when entering insert mode
    opts = {}, -- lazy.nvim will call require("nvim-autopairs").setup(opts)
  },
  { 'voldikss/vim-floaterm', cmd = {"FloatermNew", "FloatermToggle"} },
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = {"TroubleToggle", "Trouble"},
    opts = {
      modes = {
        lsp = {
          filter = {
            -- Filter out virtual environments and system locations
            ["not"] = {
              filename = {
                "%.local/share/nvim/mason/",
                "%.pyenv/",
                "%.venv/",
                "venv/",
                "__pycache__/",
                "site%-packages/",
                "dist%-packages/",
                "/usr/lib/python",
                "/usr/local/lib/python",
              },
            },
          },
        },
      },
    },
  },
  { 'airblade/vim-gitgutter', event = {"BufReadPost", "BufWritePost"} },
  {
    'ThePrimeagen/refactoring.nvim',
    dependencies = {
        {"nvim-lua/plenary.nvim"},
        {"nvim-treesitter/nvim-treesitter"}
    },
    -- Consider adding specific commands or keymaps for lazy-loading
    config = function()
      require('refactoring').setup({})
    end,
  },
  {
    "greggh/claude-code.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim", -- Required for git operations
    },
    config = function()
      require("claude-code").setup()
    end
  },

  -- [[ LSP, Completion, Treesitter ]]
  {
    'williamboman/mason.nvim',
    event = {"BufReadPre", "BufNewFile"},
    config = function()
      require("mason").setup()
    end
  },
  {
    'williamboman/mason-lspconfig.nvim',
    dependencies = {"williamboman/mason.nvim", "neovim/nvim-lspconfig"},
    event = {"BufReadPre", "BufNewFile"},
    opts = {
      ensure_installed = { "ruff", "pyright", "marksman", "yamlls", "jsonls", "bashls", "lua_ls", "html", "cssls", "ts_ls" },
      automatic_enable = false,  -- We'll call vim.lsp.enable() manually
    },
  },
  {
    'neovim/nvim-lspconfig',
    event = {"BufReadPre", "BufNewFile"},
    config = function()
      -- Helper function to find Python interpreter
      local function get_python_path()
        -- Check for .venv/bin/python
        local venv_python = vim.fn.getcwd() .. "/.venv/bin/python"
        if vim.fn.executable(venv_python) == 1 then
          return venv_python
        end

        -- Check for uv managed Python
        local uv_python = vim.fn.system("uv which python 2>/dev/null"):gsub("\n", "")
        if vim.fn.executable(uv_python) == 1 then
          return uv_python
        end

        -- Fall back to system Python
        return vim.fn.exepath("python3") or vim.fn.exepath("python")
      end

      -- LSP keybindings via LspAttach autocmd
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('UserLspConfig', {}),
        callback = function(ev)
          local opts = { buffer = ev.buf, silent = true }
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
          vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
          vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
          vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
          vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
          vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
          vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
          vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
          vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts)

          -- Document highlight on cursor hold
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if client and client:supports_method('textDocument/documentHighlight') then
            local highlight_group = vim.api.nvim_create_augroup('LspDocumentHighlight', { clear = false })
            vim.api.nvim_clear_autocmds({ group = highlight_group, buffer = ev.buf })

            vim.api.nvim_create_autocmd('CursorHold', {
              group = highlight_group,
              buffer = ev.buf,
              callback = function()
                vim.lsp.buf.document_highlight()
              end,
            })

            vim.api.nvim_create_autocmd('CursorMoved', {
              group = highlight_group,
              buffer = ev.buf,
              callback = function()
                vim.lsp.buf.clear_references()
              end,
            })
          end
        end,
      })

      local python_root_files = {"pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", ".venv", "uv.lock", ".git"}

      -- Configure ruff for Python linting/formatting
      vim.lsp.config('ruff', {
        cmd = { vim.fn.expand("~/.local/share/nvim/mason/bin/ruff"), "server" },
        filetypes = {"python"},
        root_markers = python_root_files,
      })

      -- Configure pyright for Python type checking and intellisense
      vim.lsp.config('pyright', {
        cmd = { vim.fn.expand("~/.config/nvim/pyright-wrapper.sh"), "--stdio" },
        filetypes = {"python"},
        root_markers = python_root_files,
        settings = {
          python = {
            pythonPath = get_python_path(),
            analysis = {
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              autoImportCompletions = true,
              diagnosticMode = "openFilesOnly",
              typeCheckingMode = "basic",
              logLevel = "Warning",
              exclude = {
                "**/__pycache__",
                "**/node_modules",
                "**/.venv",
                "**/venv",
                "**/.git",
                "**/dist",
                "**/build",
                "**/.mypy_cache",
                "**/.pytest_cache",
                "**/.tox",
                "**/site-packages",
              },
              extraPaths = {},
              stubPath = "",
            },
          },
        },
        init_options = {
          nodeOptions = {
            maxOldSpaceSize = 8192,
          },
        },
        flags = {
          debounce_text_changes = 300,
        },
      })

      -- Enable all LSP servers
      vim.lsp.enable({
        'ruff',
        'pyright',
        'lua_ls',
        'marksman',
        'yamlls',
        'jsonls',
        'bashls',
        'nil_ls',
        'html',
        'cssls',
        'gopls',
        'ts_ls',
      })
    end
  },
  {
    'mrcjkb/rustaceanvim',
    version = '^5',
    lazy = false,  -- Plugin handles lazy loading itself
  },
  {
    "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    opts = {}, -- Using default options
  },
  {
    'nvim-treesitter/nvim-treesitter',
    event = {"BufReadPost", "BufNewFile"},
    config = function()
      require('nvim-treesitter.configs').setup {
        highlight = { enable = true },
        indent = { enable = true },
        auto_install = false,
      }
    end,
  },
  {
    'hrsh7th/nvim-cmp',
    event = "InsertEnter",
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-nvim-lua',
      'hrsh7th/cmp-nvim-lsp-signature-help',
      'hrsh7th/cmp-vsnip',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-buffer',
      'hrsh7th/vim-vsnip', -- Snippet engine
    },
    config = function()
      local cmp = require('cmp')
      cmp.setup({
        -- Your nvim-cmp setup here
        snippet = {
          expand = function(args)
            vim.fn["vsnip#anonymous"](args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          -- Tab and Shift-Tab for cycling through completion items
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif vim.fn["vsnip#available"](1) == 1 then
              vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>(vsnip-expand-or-jump)", true, true, true), "")
            else
              fallback()
            end
          end, { "i", "s" }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif vim.fn["vsnip#jumpable"](-1) == 1 then
              vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>(vsnip-jump-prev)", true, true, true), "")
            else
              -- Dedent: remove one level of indentation
              local line = vim.api.nvim_get_current_line()
              local col = vim.api.nvim_win_get_cursor(0)[2]
              local before_cursor = line:sub(1, col)
              local indent_size = vim.bo.shiftwidth
              
              -- Check if we're at the beginning or only whitespace before cursor
              if before_cursor:match("^%s*$") then
                -- Calculate current indent level
                local current_indent = #before_cursor:match("^%s*")
                if current_indent >= indent_size then
                  -- Remove one indent level
                  local new_indent = current_indent - indent_size
                  local new_line = string.rep(" ", new_indent) .. line:sub(current_indent + 1)
                  vim.api.nvim_set_current_line(new_line)
                  vim.api.nvim_win_set_cursor(0, {vim.api.nvim_win_get_cursor(0)[1], new_indent})
                else
                  fallback()
                end
              else
                fallback()
              end
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'nvim_lua' },
          { name = 'vsnip' },
          { name = 'path' },
        }, {
          { name = 'buffer' },
        })
      })
    end,
  },

  -- [[ Focus & Dimming ]]
  {
    "folke/snacks.nvim",
    opts = {
      dim = {
        scope = {
          min_size = 5,
          max_size = 20,
          siblings = true,
        },
        animate = {
          enabled = vim.fn.has("nvim-0.10") == 1,
          easing = "outQuad",
          duration = {
            step = 20,
            total = 300,
          },
        },
        filter = function(buf)
          return vim.g.snacks_dim ~= false and vim.b[buf].snacks_dim ~= false and vim.bo[buf].buftype == ""
        end,
      }
    }
  },

  -- [[ Other Utilities ]]
  { 'puremourning/vimspector', cmd = "Vimspector" }, -- Or other specific Vimspector commands
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = {"BufReadPost", "BufNewFile"},
    opts = {}, -- lazy.nvim will call require("todo-comments").setup(opts)
  },
  { 'MaxMEllon/vim-jsx-pretty', ft = {"javascriptreact", "typescriptreact"} },

  -- [[ Writing ]]
  { 'vimwiki/vimwiki', ft = "vimwiki", cmd = "VimwikiIndex" },
  { 'junegunn/goyo.vim', cmd = "Goyo" },
}
