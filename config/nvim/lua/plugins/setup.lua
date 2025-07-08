local M = {}

function M.setup()
  -- 1 - Setup mini.nvim plugins
  -- ───────────────────────────────────────────────────
  require('mini.pairs').setup()
  require('mini.comment').setup()
  require('mini.align').setup()
  require('mini.icons').setup()
  require('mini.completion').setup()
  require('mini.splitjoin').setup()
  require('mini.surround').setup()
  require('mini.diff').setup({ view = { style = 'sign' } })

  -- mini.keymap
  -- __________________________
  local keymap = require('mini.keymap')
  keymap.setup()
  -- use tab to multi-step for popups, completion, etc.
  keymap.map_multistep('i', '<Tab>',   { 'pmenu_next' })
  keymap.map_multistep('i', '<S-Tab>', { 'pmenu_prev' })
  keymap.map_multistep('i', '<CR>',    { 'pmenu_accept','minipairs_cr' })
  keymap.map_multistep('i', '<BS>',    { 'minipairs_bs' })

  -- `jk` (and `kj`) <esc> everywhere, including terminal
  keymap.map_combo({ 'i','c','x','s' }, 'jk', '<BS><BS><Esc>')
  keymap.map_combo({ 'i','c','x','s' }, 'kj', '<BS><BS><Esc>')
  keymap.map_combo('t', 'jk', '<BS><BS><C-\\><C-n>')
  keymap.map_combo('t', 'kj', '<BS><BS><C-\\><C-n>')

  -- mini.move
  -- __________________________
  require('mini.move').setup({
    mappings = {
      -- move visual selection in Visual mode
      left       = '<C-M-h>',
      right      = '<C-M-l>',
      down       = '<C-M-j>',
      up         = '<C-M-k>',
      -- move current line in Normal mode
      line_left  = '<C-M-h>',
      line_right = '<C-M-l>',
      line_down  = '<C-M-j>',
      line_up    = '<C-M-k>',
    },
  })
 
  
  -- 2 - Setup Plugins
  -- ───────────────────────────────────────────────────
  require('mason').setup()
  require('nvim-web-devicons').setup{} 

  
  -- 3 - Configure Plugins
  -- ───────────────────────────────────────────────────
  
  -- lazy-git
  -- __________________________
  vim.keymap.set('n','<leader>gg',':LazyGit<CR>',{ silent=true })
  
  -- treesitter 
  -- __________________________
  require('plugins.config.treesitter').setup()
  
  -- nvim-tree
  -- __________________________
  require('plugins.config.nvim-tree').setup()
  
  -- telescope
  -- __________________________
  require('plugins.config.telescope').setup()
  
  
  -- 4 - Set colorscheme
  -- ───────────────────────────────────────────────────
  vim.cmd('colorscheme minimal')
end

return M

