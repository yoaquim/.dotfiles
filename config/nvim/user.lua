---@type LazyPluginSpec[]
return {
  
  -- Snacks Picker Configuration
  -- ───────────────────────────────────────────────────
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        prompt = "🔭 ",
      },
    },
  },

  -- mini.vim Plugins
  -- ───────────────────────────────────────────────────
  { "echasnovski/mini.snippets" },
  {
    "echasnovski/mini.splitjoin",
    keys = {
      { "gS", "<cmd>lua require('mini.splitjoin').toggle()<cr>", desc = "Toggle splitjoin" },
    },
    config = function()
      require("mini.splitjoin").setup()
    end,
  },
  {
    "echasnovski/mini.surround",
    keys = {
      { "sa", desc = "Add surrounding", mode = { "n", "v" } },
      { "sd", desc = "Delete surrounding" },
      { "sf", desc = "Find right surrounding" },
      { "sF", desc = "Find left surrounding" },
      { "sh", desc = "Highlight surrounding" },
      { "sr", desc = "Replace surrounding" },
      { "sn", desc = "Update `n_lines`" },
    },
    config = function()
      require("mini.surround").setup()
    end,
  },
  {
    "echasnovski/mini.move",
    keys = {
      { "<C-M-h>", desc = "Move left" },
      { "<C-M-l>", desc = "Move right" },
      { "<C-M-j>", desc = "Move down" },
      { "<C-M-k>", desc = "Move up" },
    },
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

  -- LSP and Language Support
  -- ───────────────────────────────────────────────────
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        -- Language servers
        "typescript-language-server",
        "pyright",
        "terraform-ls",
        "css-lsp",
        "html-lsp",
        "tailwindcss-language-server",
        "solargraph",
        "json-lsp",
        "yaml-language-server",
        "dockerfile-language-server",
        "bash-language-server",
        "marksman",
        -- Formatters
        "prettier",
        "black",
        "stylua",
        "shfmt",
        -- Linters
        "eslint_d",
        "flake8",
        "shellcheck",
        -- Debuggers
        "node-debug2-adapter",
        "debugpy",
      },
    },
  },

  -- Debugging Support
  -- ───────────────────────────────────────────────────
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-neotest/nvim-nio",
      "mfussenegger/nvim-dap-python",
      "mxsdev/nvim-dap-vscode-js",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      
      -- DAP UI setup
      dapui.setup()
      
      -- Auto open/close DAP UI
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
      
      -- Python debugging
      require("dap-python").setup("python")
      
      -- JavaScript/TypeScript debugging
      require("dap-vscode-js").setup({
        node_path = "node",
        debugger_path = vim.fn.stdpath("data") .. "/lazy/vscode-js-debug",
        adapters = { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" },
      })
      
      -- Virtual text
      require("nvim-dap-virtual-text").setup()
    end,
  },
  {
    "microsoft/vscode-js-debug",
    build = "npm install --legacy-peer-deps && npx gulp vsDebugServerBundle && mv dist out",
  },

  -- Testing Support
  -- ───────────────────────────────────────────────────
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-neotest/neotest-python",
      "nvim-neotest/neotest-jest",
    },
    config = function()
      require("neotest").setup({
        adapters = {
          require("neotest-python")({
            dap = { justMyCode = false },
          }),
          require("neotest-jest")({
            jestCommand = "npm test --",
            jestConfigFile = "jest.config.js",
            env = { CI = true },
            cwd = function()
              return vim.fn.getcwd()
            end,
          }),
        },
      })
    end,
  },

  -- Docker Support
  -- ───────────────────────────────────────────────────
  {
    "https://codeberg.org/esensar/nvim-dev-container",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("devcontainer").setup({})
    end,
  },

  -- AI/Copilot Support
  -- ───────────────────────────────────────────────────
  {
    "github/copilot.vim",
    config = function()
      vim.g.copilot_no_tab_map = true
      vim.keymap.set('i', '<C-g>', 'copilot#Accept("\\<CR>")', {
        expr = true,
        replace_keycodes = false
      })
      vim.keymap.set('i', '<C-j>', '<Plug>(copilot-next)')
      vim.keymap.set('i', '<C-k>', '<Plug>(copilot-previous)')
      vim.keymap.set('i', '<C-o>', '<Plug>(copilot-dismiss)')
    end,
  },

  -- Color Schemes
  -- ───────────────────────────────────────────────────
  { "RRethy/base16-nvim" },
  { "marko-cerovac/material.nvim" },
  { "Yazeed1s/minimal.nvim" },
}

