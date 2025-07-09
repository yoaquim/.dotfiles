---@type LazyPluginSpec[]
return {
  
  -- Custom Plugins
  -- ───────────────────────────────────────────────────
  { "echasnovski/mini.snippets" },
  {
    "echasnovski/mini.splitjoin",
    config = function()
      require("mini.splitjoin").setup()
    end,
  },
  {
    "echasnovski/mini.surround",
    config = function()
      require("mini.surround").setup()
    end,
  },
  {
    "echasnovski/mini.move",
    config = function()
      require("mini.move").setup {
        mappings = {
          left       = "<C-M-h>",
          right      = "<C-M-l>",
          down       = "<C-M-j>",
          up         = "<C-M-k>",
          line_left  = "<C-M-h>",
          line_right = "<C-M-l>",
          line_down  = "<C-M-j>",
          line_up    = "<C-M-k>",
        },
      }
    end,
  },

  -- Color Schemes
  -- ───────────────────────────────────────────────────
  { "RRethy/base16-nvim" },
  { "marko-cerovac/material.nvim" },
  { "Yazeed1s/minimal.nvim" },
}

