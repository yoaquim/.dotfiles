local map = vim.keymap.set
local user_command = vim.api.nvim_create_user_command
local opts = { silent = true }

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

