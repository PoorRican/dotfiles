-- [[ plug.lua ]]

-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
  use {                                              -- filesystem navigation
    'kyazdani42/nvim-tree.lua',
    requires = 'kyazdani42/nvim-web-devicons'        -- filesystem icons
  }
  use { 'lewis6991/impatient.nvim' }                 -- speeds up load time
  use 'vimwiki/vimwiki'

  -- [[ Ricing ]]
  use { 'mhinz/vim-startify' }                       -- start screen
  use { 'DanilaMihailov/beacon.nvim' }               -- cursor jump
  use {
    'nvim-lualine/lualine.nvim',                     -- statusline
    requires = {'kyazdani42/nvim-web-devicons',
                opt = true}
  }
  use {
    "xero/evangelion.nvim",
    config = function() require("evangelion").setup{} end,
    run = ":colorscheme evangelion"
  }

  -- [[ Dev ]]
  use {
    'nvim-telescope/telescope.nvim',                 -- fuzzy finder
    requires = { {'nvim-lua/plenary.nvim'} }
  }
  use { 'majutsushi/tagbar' }                        -- code structure
  use { 'Yggdroot/indentLine' }                      -- see indentation
  use { 'tpope/vim-fugitive' }                       -- git integration
  use { 'junegunn/gv.vim' }                          -- commit history
  use {
    'windwp/nvim-autopairs',                         -- automatically close brackets, parentheses, curly braces, and so on
    config = function() require("nvim-autopairs").setup {} end
  }
  use { 'voldikss/vim-floaterm' }                    -- floating terminal
  use {
    "folke/trouble.nvim",                            -- diagnostics, references, quickfix and location lists
    requires = "nvim-tree/nvim-web-devicons",
    config = function()
    require("trouble").setup {
    }
  end
  }
  use 'airblade/vim-gitgutter'
  use {
    'ThePrimeagen/refactoring.nvim',
    requires = {
        {"nvim-lua/plenary.nvim"},
        {"nvim-treesitter/nvim-treesitter"}
    }
  }

  -- Rust config from https://rsdlt.github.io/posts/rust-nvim-ide-guide-walkthrough-development-debug/
  use 'williamboman/mason.nvim'    
  use 'williamboman/mason-lspconfig.nvim'
  use 'neovim/nvim-lspconfig' 
  use 'simrat39/rust-tools.nvim'
  use 'nvim-treesitter/nvim-treesitter'

  -- Completion framework:
  use 'hrsh7th/nvim-cmp' 

  -- GitHub Copilot
  use 'github/copilot.vim'

  -- LSP completion source:
  use 'hrsh7th/cmp-nvim-lsp'

  -- Useful completion sources:
  use 'hrsh7th/cmp-nvim-lua'
  use 'hrsh7th/cmp-nvim-lsp-signature-help'
  use 'hrsh7th/cmp-vsnip'
  use 'hrsh7th/cmp-path'
  use 'hrsh7th/cmp-buffer'
  use 'hrsh7th/vim-vsnip'
  use 'puremourning/vimspector'
  use { "folke/todo-comments.nvim",
    requires = "nvim-lua/plenary.nvim", "nvim-lua/plenary.nvim",
    config = function()
    require("todo-comments").setup {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    }
  end
  }
  use 'MaxMEllon/vim-jsx-pretty'
end)
