local map = vim.keymap.set
local opts = { silent = true }

-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │                              Custom Motions                                 │
-- └─────────────────────────────────────────────────────────────────────────────┘
-- Delete word backwards (vb"_d)
map('n', 'dw', 'vb"_d', opts)

-- Delete without yanking
map('n', '<leader>d', '"_d', opts)
map('n', 'x',   '"_x', opts)

-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │                              File Shortcuts                                 │
-- └─────────────────────────────────────────────────────────────────────────────┘
map('n', '<Leader>w', '<Cmd>w<CR>', opts)
map('n', '<Leader>W', '<Cmd>W<CR>', opts)
map('n', '<Leader>q', '<Cmd>q<CR>', opts)
map('n', '<Leader>Q', '<Cmd>Q<CR>', opts)
map('n', '<Leader>x', '<Cmd>x<CR>', opts)
map('n', '<Leader>X', '<Cmd>X<CR>', opts)

-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │                              Fast Scrolling                                 │
-- └─────────────────────────────────────────────────────────────────────────────┘
-- On many mac setups <M-j> isn't caught, so map both <M-j> *and* the literal ∆/˚
for _, mode in ipairs({ 'n', 'v' }) do
  map(mode, '<M-j>', '5j', opts)
  map(mode, '<M-k>', '5k', opts)
  map(mode, '<M-J>', '15j', opts)
  map(mode, '<M-K>', '15k', opts)
  -- literal Mac Option-j/k characters:
  map(mode, '∆', '5j', opts)
  map(mode, '˚', '5k', opts)
  map(mode, 'Ô', '15j', opts)
  map(mode, '', '15k', opts)
end

-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │                               Fold Toggling                                 │
-- └─────────────────────────────────────────────────────────────────────────────┘
-- In normal: if inside a fold, za, else insert a space
map('n', '\\', function()
  return (vim.fn.foldlevel('.') > 0) and 'za' or '<Space>'
end, { expr = true, silent = true })

-- In visual: create a fold
map('v', '\\', 'zf', opts)

-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │                              Search Higlight                                │
-- └─────────────────────────────────────────────────────────────────────────────┘
map('n', '<Leader>h', function()
  vim.opt.hlsearch = not vim.opt.hlsearch:get()
end, opts)

-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │                             Window Navigation                               │
-- └─────────────────────────────────────────────────────────────────────────────┘
map('n', '<C-h>', '<C-w>h', opts)
map('n', '<C-j>', '<C-w>j', opts)
map('n', '<C-k>', '<C-w>k', opts)
map('n', '<C-l>', '<C-w>l', opts)

-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │                             Visual Line Mode                                │
-- └─────────────────────────────────────────────────────────────────────────────┘
map('n', '<Leader><Leader>', 'V', opts)

