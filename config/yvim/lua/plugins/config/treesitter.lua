local M = {}

function M.setup()
  require('nvim-treesitter.configs').setup({
    ensure_installed = { "lua","python","typescript","tsx","javascript",
                         "bash","json","yaml","markdown","terraform" },
    highlight = { enable = true },
  })
end

return M

