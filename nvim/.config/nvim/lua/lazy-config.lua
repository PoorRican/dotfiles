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
    config = function()
      vim.cmd.colorscheme("evangelion")
    end,
  }, -- Colorscheme
  {
    "scottmckendry/cyberdream.nvim",
    lazy = false, -- Load colorschemes early
    priority = 1000,
    config = function()
      require("cyberdream").setup{}
      vim.cmd.colorscheme("cyberdream")
    end,
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
    'windwp/nvim-autopairs',
    event = "InsertEnter", -- Load when entering insert mode
    opts = {}, -- lazy.nvim will call require("nvim-autopairs").setup(opts)
  },
  { 'voldikss/vim-floaterm', cmd = {"FloatermNew", "FloatermToggle"} },
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = {"TroubleToggle", "Trouble"},
    opts = {}, -- lazy.nvim will call require("trouble").setup(opts)
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
  { 'williamboman/mason.nvim', cmd = "Mason" },
  {
    'williamboman/mason-lspconfig.nvim',
    dependencies = {"williamboman/mason.nvim", "neovim/nvim-lspconfig"},
    opts = {
      ensure_installed = { "ruff_lsp", "marksman", "yamlls", "jsonls", "bashls", "lua_ls", "nil_ls", "html", "cssls", "gopls", "tsserver" }
    }
  },
  { 'neovim/nvim-lspconfig', event = {"BufReadPre", "BufNewFile"} }, -- Load on buffer events
  {
    'simrat39/rust-tools.nvim',
    ft = "rust", -- Load for rust files
    dependencies = {"neovim/nvim-lspconfig"},
    config = function()
      require('rust-tools').setup({})
    end,
  },
  {
    "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    opts = {}, -- Using default options
  },
  {
    'nvim-treesitter/nvim-treesitter',
    build = ":TSUpdate",
    event = {"BufReadPost", "BufNewFile"},
    config = function()
      require('nvim-treesitter.configs').setup {
        highlight = { enable = true },
        indent = { enable = true },
        ensure_installed = { "bash", "c", "cpp", "css", "go", "html", "javascript", "json", "lua", "nix", "python", "rust", "toml", "tsx", "typescript", "yaml" },
        auto_install = true,
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
