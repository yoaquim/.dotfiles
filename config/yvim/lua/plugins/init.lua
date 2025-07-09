-- 1 - Make sure mini.nvim is installed 
-- ───────────────────────────────────────────────────
local path_package = vim.fn.stdpath('data') .. '/site/'
local mini_path    = path_package .. 'pack/deps/start/mini.nvim'
if not vim.loop.fs_stat(mini_path) then
  vim.cmd('echo "Installing `mini.nvim`…" | redraw')
  vim.fn.system({
    'git','clone','--filter=blob:none',
    'https://github.com/echasnovski/mini.nvim',
    mini_path,
  })
  vim.cmd('packadd mini.nvim | helptags ALL')
  vim.cmd('echo "Installed `mini.nvim`" | redraw')
end

-- 2 - Load mini.deps, dependency manager
-- ───────────────────────────────────────────────────
require('mini.deps').setup({ path = { package = path_package }})
local add = MiniDeps.add

-- 3 - Install Plugins
-- ───────────────────────────────────────────────────
require('plugins.registry')(add)

-- 4 - Configure plugins
-- ───────────────────────────────────────────────────
require('plugins.setup').setup()

