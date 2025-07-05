-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │                              Load mini.nvim                                 │
-- └─────────────────────────────────────────────────────────────────────────────┘
local path_package = vim.fn.stdpath('data') .. '/site/'
local mini_path = path_package .. 'pack/deps/start/mini.nvim'
if not vim.loop.fs_stat(mini_path) then
  vim.cmd('echo "Installing `mini.nvim`" | redraw')
  local clone_cmd = { 'git', 'clone', '--filter=blob:none', 'https://github.com/echasnovski/mini.nvim', mini_path }
  vim.fn.system(clone_cmd)
  vim.cmd('packadd mini.nvim | helptags ALL')
  vim.cmd('echo "Installed `mini.nvim`" | redraw')
end
-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │                             Setup mini.deps                                 │
-- └─────────────────────────────────────────────────────────────────────────────┘
require('mini.deps').setup({ path = { package = path_package } })
local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │                          Add mini.nvim plugins                              │
-- └─────────────────────────────────────────────────────────────────────────────┘

-- mini.pairs: https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-pairs.md
-- ─────────────────────────────────────────────────────────────────────────────
add('echasnovski/mini.pairs')
require('mini.pairs').setup()

-- mini.comment: https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-comment.md
-- ─────────────────────────────────────────────────────────────────────────────
add('echasnovski/mini.pairs')
add('echasnovski/mini.comment')
require('mini.comment').setup()

-- mini.align: https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-align.md
-- ─────────────────────────────────────────────────────────────────────────────
add('echasnovski/mini.align')
require('mini.align').setup()

-- mini.icons: https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-align.md
-- ─────────────────────────────────────────────────────────────────────────────
add('echasnovski/mini.icons')
require('mini.icons').setup()

-- mini.completion: https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-completion.md
-- ─────────────────────────────────────────────────────────────────────────────
add('echasnovski/mini.completion')
require('mini.completion').setup()

-- mini.splitjoin: https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-splitjoin.md
-- ─────────────────────────────────────────────────────────────────────────────
add('echasnovski/mini.splitjoin')
require('mini.splitjoin').setup()

-- mini.surround: https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-surround.md
-- ─────────────────────────────────────────────────────────────────────────────
add('echasnovski/mini.surround')
require('mini.surround').setup()

-- mini.diff: https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-diff.md
-- ─────────────────────────────────────────────────────────────────────────────
add('echasnovski/mini.diff')
require('mini.diff').setup({
  view = {
    style = 'sign'
  }
})

-- mini.keymap: https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-keymap.md
-- ─────────────────────────────────────────────────────────────────────────────
add('echasnovski/mini.keymap')
local keymap = require('mini.keymap')
local mode = { 'i', 'c', 'x', 's' }
keymap.setup()
keymap.map_multistep('i', '<Tab>',   { 'pmenu_next' })
keymap.map_multistep('i', '<S-Tab>', { 'pmenu_prev' })
keymap.map_multistep('i', '<CR>',    { 'pmenu_accept', 'minipairs_cr' })
keymap.map_multistep('i', '<BS>',    { 'minipairs_bs' })
-- Remap <Esc> to `jk`
keymap.map_combo(mode, 'jk', '<BS><BS><Esc>')
-- To not have to worry about the order of keys, also map "kj"
keymap.map_combo(mode, 'kj', '<BS><BS><Esc>')
-- Escape into Normal mode from Terminal mode
keymap.map_combo('t', 'jk', '<BS><BS><C-\\><C-n>')
keymap.map_combo('t', 'kj', '<BS><BS><C-\\><C-n>')

-- mini.move: https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-move.md
-- ─────────────────────────────────────────────────────────────────────────────
add('echasnovski/mini.move')
require('mini.move').setup({
  mappings = {
    -- Move visual selection in Visual mode. 
    left = '<C-M-h>',
    right = '<C-M-l>',
    down = '<C-M-j>',
    up = '<C-M-k>',
    -- Move current line in Normal mode
    line_left = '<C-M-h>',
    line_right = '<C-M-l>',
    line_down = '<C-M-j>',
    line_up = '<C-M-k>',
  }
})

-- mini.snippets: https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-snippets.md
-- ─────────────────────────────────────────────────────────────────────────────
add('echasnovski/mini.snippets')
local snippets = require('mini.snippets')
local gen_loader = snippets.gen_loader
snippets.setup({
  snippets = {
    -- Load custom file with global snippets first (adjust for Windows)
    gen_loader.from_file('~/.config/nvim/snippets/global.json'),
    -- Load snippets based on current language by reading files from
    -- "snippets/" subdirectories from 'runtimepath' directories.
    gen_loader.from_lang(),
  },
})

-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │                             Add nvim plugins                                │
-- └─────────────────────────────────────────────────────────────────────────────┘

-- friendly-snippets: https://github.com/rafamadriz/friendly-snippets
-- ─────────────────────────────────────────────────────────────────────────────
add({source = 'rafamadriz/friendly-snippets'})

