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

-- mini.comment: https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-comment.md
add('echasnovski/mini.comment')
require('mini.comment').setup()

-- mini.align: https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-align.md
add('echasnovski/mini.align')
require('mini.align').setup()

-- mini.icons: https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-align.md
add('echasnovski/mini.icons')
require('mini.icons').setup()

-- mini.snippets: https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-snippets.md
add('echasnovski/mini.snippets')
require('mini.snippets').setup()

-- mini.completion: https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-completion.md
add('echasnovski/mini.completion')
require('mini.completion').setup()

-- mini.splitjoin: https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-splitjoin.md
add('echasnovski/mini.splitjoin')
require('mini.splitjoin').setup()

-- mini.surround: https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-surround.md
add('echasnovski/mini.surround')
require('mini.surround').setup()

