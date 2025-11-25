local map = vim.keymap.set
local opt = vim.opt
local cmd = vim.cmd
local user_command = vim.api.nvim_create_user_command
local opts = { silent = true }

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

-- force disable clipboard after config loads
vim.schedule(function()
  vim.opt.clipboard = ""
end)
-- additional clipboard override with autocmd
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.opt.clipboard = ""
  end,
})
-- enable mouse
opt.mouse          = 'a'
-- show partial commands
opt.showcmd        = true
-- absolute line numbers
opt.relativenumber = false
-- incremental search
opt.incsearch      = true
-- backspace over everything
opt.backspace      = { 'indent', 'eol', 'start' }


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


-- Deleting
-- ───────────────────────────────────────────────────

-- delete word backwards (vb"_d)
map('n', 'dw', 'vb"_d', opts)
-- delete without yanking
map('n', '<leader>d', '"_d', opts)
map('n', 'x',   '"_x', opts)


-- Copy-Pasting
-- ───────────────────────────────────────────────────

-- copy to clipboard
map('v', '<leader>y', '"+y', opts)
map('n', '<leader>y', '"+y', opts)
map('n', '<leader>yy', '"+yy', opts)
map('n', '<leader>Y', '"+yg_', opts)
-- paste from clipboard
map('v', '<leader>p', '"+p', opts)
map('v', '<leader>P', '"+P', opts)
map('n', '<leader>p', '"+p', opts)
map('n', '<leader>P', '"+P', opts)
-- paste from clipboard and fix indentation
map('n', '<leader>pp', '"+p=`]', opts)
map('n', '<leader>PP', '"+P=`]', opts)


-- File Shortcuts
-- ───────────────────────────────────────────────────
map('n', '<Leader>w', '<Cmd>w<CR>', opts)
map('n', '<Leader>W', '<Cmd>W<CR>', opts)
map('n', '<Leader>q', '<Cmd>q<CR>', opts)
map('n', '<Leader>Q', '<Cmd>Q<CR>', opts)
map('n', '<Leader>x', '<Cmd>x<CR>', opts)
map('n', '<Leader>X', '<Cmd>X<CR>', opts)


-- Fast Scrolling
-- ───────────────────────────────────────────────────

-- on many mac setups <M-j> isn't caught, 
-- so map both <M-j> *and* the literal chars 
for _, mode in ipairs({ 'n', 'v' }) do
  map(mode, '<M-j>', '5j', opts)
  map(mode, '<M-k>', '5k', opts)
  map(mode, '<M-J>', '15j', opts)
  map(mode, '<M-K>', '15k', opts)
  map(mode, '∆', '5j', opts)
  map(mode, '˚', '5k', opts)
  map(mode, 'Ô', '15j', opts)
  map(mode, '', '15k', opts)
end


-- Fold Toggling
-- ───────────────────────────────────────────────────

-- in normal: if inside a fold, za, else insert a space
map('n', '\\', function()
  return (vim.fn.foldlevel('.') > 0) and 'za' or '<Space>'
end, { expr = true, silent = true })

-- in visual: create a fold
map('v', '\\', 'zf', opts)


-- Search Higlight
-- ───────────────────────────────────────────────────
map('n', '<Leader>h', function()
  vim.opt.hlsearch = not vim.opt.hlsearch:get()
end, opts)


-- Window Navigation
-- ───────────────────────────────────────────────────
map('n', '<C-h>', '<C-w>h', opts)
map('n', '<C-j>', '<C-w>j', opts)
map('n', '<C-k>', '<C-w>k', opts)
map('n', '<C-l>', '<C-w>l', opts)


-- Buffer Navigation
-- ───────────────────────────────────────────────────
map('n', '<leader>bj', ':bnext<CR>', opts)
map('n', '<leader>bk', ':bprevious<CR>', opts)
map('n', '<leader>bd', ':bdelete<CR>', opts)
map('n', '<leader>bl', ':buffers<CR>', opts)
-- Simple buffer navigation (j=prev, k=next for intuitive up/down)
map('n', '<leader>j', ':bprevious<CR>', opts)
map('n', '<leader>k', ':bnext<CR>', opts)


-- Debugging
-- ───────────────────────────────────────────────────
map('n', '<leader>db', "<cmd>lua require'dap'.toggle_breakpoint()<cr>", opts)
map('n', '<leader>dc', "<cmd>lua require'dap'.continue()<cr>", opts)
map('n', '<leader>di', "<cmd>lua require'dap'.step_into()<cr>", opts)
map('n', '<leader>do', "<cmd>lua require'dap'.step_over()<cr>", opts)
map('n', '<leader>dO', "<cmd>lua require'dap'.step_out()<cr>", opts)
map('n', '<leader>dr', "<cmd>lua require'dap'.repl.toggle()<cr>", opts)
map('n', '<leader>dl', "<cmd>lua require'dap'.run_last()<cr>", opts)
map('n', '<leader>du', "<cmd>lua require'dapui'.toggle()<cr>", opts)
map('n', '<leader>dt', "<cmd>lua require'dap'.terminate()<cr>", opts)


-- Testing
-- ───────────────────────────────────────────────────
map('n', '<leader>tt', "<cmd>lua require'neotest'.run.run()<cr>", opts)
map('n', '<leader>tf', "<cmd>lua require'neotest'.run.run(vim.fn.expand('%'))<cr>", opts)
map('n', '<leader>td', "<cmd>lua require'neotest'.run.run({strategy = 'dap'})<cr>", opts)
map('n', '<leader>ts', "<cmd>lua require'neotest'.run.stop()<cr>", opts)
map('n', '<leader>ta', "<cmd>lua require'neotest'.run.attach()<cr>", opts)


-- Set colorscheme
-- ───────────────────────────────────────────────────
vim.cmd('colorscheme base16-darkmoss')

