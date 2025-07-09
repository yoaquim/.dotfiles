return function(add)

  -- https://github.com/echasnovski/mini.nvim
  -- ───────────────────────────────────────────────────
  add('echasnovski/mini.pairs')
  add('echasnovski/mini.comment')
  add('echasnovski/mini.align')
  add('echasnovski/mini.icons')
  add('echasnovski/mini.completion')
  add('echasnovski/mini.splitjoin')
  add('echasnovski/mini.surround')
  add('echasnovski/mini.diff')
  add('echasnovski/mini.keymap')
  add('echasnovski/mini.move')
  add('echasnovski/mini.snippets')

  -- https://github.com/nvim-treesitter/nvim-treesitter
  -- ───────────────────────────────────────────────────
  add({
    source = 'nvim-treesitter/nvim-treesitter',
    hooks = { post_checkout = function() vim.cmd('TSUpdate') end },
  })

  -- https://github.com/mason-org/mason.nvim
  -- ───────────────────────────────────────────────────
  add { source = 'mason-org/mason.nvim' }

  -- https://github.com/nvim-tree/nvim-tree.lua
  -- ───────────────────────────────────────────────────
  add { source = 'nvim-tree/nvim-tree.lua' }

  -- https://github.com/nvim-tree/nvim-web-devicon
  -- ───────────────────────────────────────────────────
  add { source = 'nvim-tree/nvim-web-devicons' }

  -- https://github.com/nvim-telescope/telescope.nvim
  -- ───────────────────────────────────────────────────
  add { source = 'nvim-lua/plenary.nvim' }
  add { source = 'nvim-telescope/telescope.nvim' }
  add { source = 'nvim-telescope/telescope-fzf-native.nvim' }

  -- https://github.com/kdheepak/lazygit.nvim
  -- ───────────────────────────────────────────────────
  add { source = 'kdheepak/lazygit.nvim' }
  
  -- https://github.com/rafamadriz/friendly-snippets
  -- ───────────────────────────────────────────────────
  add { source = 'rafamadriz/friendly-snippets' }

  -- Colorschemes
  -- ───────────────────────────────────────────────────
  add { source = 'RRethy/base16-nvim' }
  add { source = 'marko-cerovac/material.nvim' }
  add { source = 'rose-pine/neovim' }
  add { source = 'Yazeed1s/minimal.nvim' }
end

