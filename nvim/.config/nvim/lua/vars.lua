--[[ vars.lua ]]

-- Setup shortcuts
local g = vim.g
local opt = vim.opt
local cmd = vim.api.nvim_command

g.t_co = 256
g.background = "dark"

-- Update the packpath
local packer_path = vim.fn.stdpath('config') .. '/site'
vim.o.packpath = vim.o.packpath .. ',' .. packer_path

-- [[ Theme ]]
opt.syntax = "ON"                -- str:  Allow syntax highlighting
opt.termguicolors = true         -- bool: If term supports ui color then enable
cmd('colorscheme sourcerer')     -- cmd:  Set the colorscheme
