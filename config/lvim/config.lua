-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │                               Appearance                                    │
-- └─────────────────────────────────────────────────────────────────────────────┘
lvim.colorscheme = "minimal"

-- remove bg highlights for comments, and make them dark gray
-- lvim.autocommands = {
--   {
--     { "ColorScheme" },
--     {
--       pattern = "*",
--       callback = function()
--         vim.api.nvim_set_hl(0, "@comment", { fg="#808080", bg = "NONE", underline = false, bold = true })
--       end,
--     },
--   },
-- }

-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │                                 Plugins                                     │
-- └─────────────────────────────────────────────────────────────────────────────┘

-- turn off core pluging lsp logging, seems to greatly increases performance
vim.lsp.set_log_level("off")

-- install plugins
lvim.plugins = {
  -- colorschemes
  {"RRethy/base16-nvim"},
  {"marko-cerovac/material.nvim"},
  {"rose-pine/neovim"},
  {"yazeed1s/minimal.nvim"},
  -- plugins
  {"ChristianChiarulli/swenv.nvim"},
  {"mfussenegger/nvim-dap"},
  {"mfussenegger/nvim-dap-python" },
  {"nvim-neotest/nvim-nio"},
  {"nvim-neotest/neotest"},
  {"nvim-neotest/neotest-python"},
  {"nvim-neotest/neotest-jest"},
  {"echasnovski/mini.icons"},
  {"echasnovski/mini.surround"},
  {"echasnovski/mini.splitjoin"},
  {
    "echasnovski/mini.move",
    config = function ()
      require("mini.move").setup({
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
    end
  },
}


-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │                         Syntax, Formatting, Linting                         │
-- └─────────────────────────────────────────────────────────────────────────────┘

-- automatically install python syntax highlighting
lvim.builtin.treesitter.ensure_installed = {
  "lua", "python", "typescript", "tsx", "javascript", "bash", "json", "yaml", "markdown", "terraform"
}

-- setup formatting
local formatters = require "lvim.lsp.null-ls.formatters"
formatters.setup {
  { name = "black" },
  {
    name = "prettier",
    ---@usage arguments to pass to the formatter
    -- these cannot contain whitespace
    -- options such as `--line-width 80` become either `{"--line-width", "80"}` or `{"--line-width=80"}`
    args = { "--print-width", "100" },
    ---@usage only start in these filetypes, by default it will attach to all filetypes it supports
    filetypes = { "typescript", "typescriptreact" },
  },
}
lvim.format_on_save.enabled = true
lvim.format_on_save.pattern = { "*.py", ".ts", ".tsx", ".js", ".jsx", ".tf", ".hcl"}

-- setup linting
local linters = require "lvim.lsp.null-ls.linters"
linters.setup { { command = "flake8", filetypes = { "python" } } }


-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │                                Debugging                                    │
-- └─────────────────────────────────────────────────────────────────────────────┘

lvim.builtin.dap.active = true
local mason_path = vim.fn.glob(vim.fn.stdpath "data" .. "/mason/")
pcall(function()
  require("dap-python").setup(mason_path .. "packages/debugpy/venv/bin/python")
end)


-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │                                 Testing                                     │
-- └─────────────────────────────────────────────────────────────────────────────┘

require("neotest").setup({
  adapters = {
    require("neotest-python")({
      -- Extra arguments for nvim-dap configuration
      -- See https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for values
      dap = {
        justMyCode = false,
        console = "integratedTerminal",
      },
      args = { "--log-level", "DEBUG", "--quiet" },
      runner = "pytest",
    })
  }
})


lvim.builtin.which_key.mappings["dm"] = { "<cmd>lua require('neotest').run.run()<cr>",
  "Test Method" }
lvim.builtin.which_key.mappings["dM"] = { "<cmd>lua require('neotest').run.run({strategy = 'dap'})<cr>",
  "Test Method DAP" }
lvim.builtin.which_key.mappings["df"] = {
  "<cmd>lua require('neotest').run.run({vim.fn.expand('%')})<cr>", "Test Class" }
lvim.builtin.which_key.mappings["dF"] = {
  "<cmd>lua require('neotest').run.run({vim.fn.expand('%'), strategy = 'dap'})<cr>", "Test Class DAP" }
lvim.builtin.which_key.mappings["dS"] = { "<cmd>lua require('neotest').summary.toggle()<cr>", "Test Summary" }


-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │                                Key Bindings                                 │
-- └─────────────────────────────────────────────────────────────────────────────┘

-- map <ESC> to `jk` and `kj`
vim.keymap.set({ "i", "v" }, "jk", "<Esc>", { noremap = true, silent = true })
vim.keymap.set({ "i", "v" }, "kj", "<Esc>", { noremap = true, silent = true })

-- fast scrolling
for _, mode in ipairs({ 'normal_mode', 'visual_mode' }) do
  lvim.keys[mode]["<M-j>"] =  "5j"
  lvim.keys[mode]["<M-k>"] =  "5k"
  lvim.keys[mode]["<M-J>"] =  "15j"
  lvim.keys[mode]["<M-K>"] =  "15k"
  --literal mac option-j/k characters:
  lvim.keys[mode]["∆"] =  "5j"
  lvim.keys[mode]["˚"] =  "5k"
  lvim.keys[mode]["Ô"] =  "15j"
  lvim.keys[mode][""] =  "15k"
end

-- switch python envs
lvim.builtin.which_key.mappings["C"] = {
  name = "Python",
  c = { "<cmd>lua require('swenv.api').pick_venv()<cr>", "Choose Env" },
}

