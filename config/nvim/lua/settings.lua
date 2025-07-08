local opt = vim.opt
local cmd = vim.cmd
local user_command = vim.api.nvim_create_user_command


-- Colors
-- ───────────────────────────────────────────────────
opt.termguicolors = true
cmd('highlight Normal guibg=NONE guifg=NONE')
cmd('highlight NonText guibg=NONE')


-- File & Syntax Higlighting
-- ───────────────────────────────────────────────────
cmd('filetype plugin indent on')
cmd('syntax on')


-- Settings
-- ───────────────────────────────────────────────────

-- yank to clipboard
-- o.clipboard = 'unnamedplus'
-- enable mouse
opt.mouse         = 'a'                   
-- show partial commands
opt.showcmd       = true                  
-- line numbers
opt.number        = true                  
-- incremental search
opt.incsearch     = true                  
-- backspace over everything
opt.backspace     = { 'indent', 'eol', 'start' }


-- Tabs & Indentation
-- ───────────────────────────────────────────────────
opt.softtabstop   = 2
opt.shiftwidth    = 2
opt.expandtab     = true


-- Custom Commands
-- ───────────────────────────────────────────────────
user_command('Q', 'q!', {})
user_command('W', 'w !sudo tee % > /dev/null', {})
user_command('X', 'x !sudo tee % > /dev/null', {})

