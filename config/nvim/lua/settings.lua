-- ~/.config/nvim/lua/settings.lua
local opt = vim.opt
local cmd = vim.cmd
local g   = vim.g

-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │                                  Leader                                     │
-- └─────────────────────────────────────────────────────────────────────────────┘
g.mapleader = ' '

-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │                        File & Syntax Higlighting                            │
-- └─────────────────────────────────────────────────────────────────────────────┘
cmd('filetype plugin indent on')
cmd('syntax on')

-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │                            Performance & UI                                 │
-- └─────────────────────────────────────────────────────────────────────────────┘
opt.mouse         = 'a'                   -- enable mouse
opt.backspace     = { 'indent', 'eol', 'start' }
opt.showcmd       = true                  -- show partial commands
opt.number        = true                  -- line numbers
opt.incsearch     = true                  -- incremental search

-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │                            Tabs & Indentation                               │
-- └─────────────────────────────────────────────────────────────────────────────┘
opt.softtabstop   = 2
opt.shiftwidth    = 2
opt.expandtab     = true

-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │                              User Commands                                  │
-- └─────────────────────────────────────────────────────────────────────────────┘
vim.api.nvim_create_user_command('Q', 'q!', {})
vim.api.nvim_create_user_command('W', 'w !sudo tee % > /dev/null', {})
