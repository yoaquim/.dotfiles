---@type LazyPluginSpec[]
return {

  -- Treesitter Configuration
  -- ───────────────────────────────────────────────────
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "sql" },
    },
  },

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
    event = "VeryLazy",
    config = function()
      require("mini.move").setup({
        mappings = {
          left = '<C-M-h>',
          right = '<C-M-l>',
          down = '<C-M-j>',
          up = '<C-M-k>',
          line_left = '<C-M-h>',
          line_right = '<C-M-l>',
          line_down = '<C-M-j>',
          line_up = '<C-M-k>',
        },
      })
    end,
  },

  -- LSP and Language Support
  -- ───────────────────────────────────────────────────
  {
    "williamboman/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {
        -- Frontend
        "ts_ls",           -- TypeScript/JavaScript
        "tailwindcss",     -- Tailwind CSS
        "cssls",           -- CSS
        "html",            -- HTML
        -- Backend
        "sqlls",           -- SQL
        "pyright",         -- Python
        "ruby_lsp",        -- Ruby
        "bashls",          -- Bash
        -- DevOps
        "dockerls",        -- Docker
        "terraformls",     -- Terraform
        "yamlls",          -- YAML
        -- Documentation
        "jsonls",          -- JSON
        "marksman",        -- Markdown
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
      
      -- Configure JavaScript/TypeScript debug configurations
      for _, language in ipairs({ "typescript", "javascript", "typescriptreact", "javascriptreact" }) do
        dap.configurations[language] = {
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch file",
            program = "${file}",
            cwd = "${workspaceFolder}",
          },
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach",
            processId = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}",
          },
          {
            type = "pwa-node",
            request = "launch",
            name = "Debug Jest Tests",
            runtimeExecutable = "node",
            runtimeArgs = {
              "./node_modules/jest/bin/jest.js",
              "--runInBand",
            },
            rootPath = "${workspaceFolder}",
            cwd = "${workspaceFolder}",
            console = "integratedTerminal",
            internalConsoleOptions = "neverOpen",
          },
        }
      end
      
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
      "marilari88/neotest-vitest",
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
          require("neotest-vitest")({
            vitestCommand = "npm run test --",
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
      require("devcontainer").setup({
        -- Configure the plugin
        attach_mounts = {
          neovim_config = {
            enabled = true,
            options = { "readonly" }
          },
          neovim_data = {
            enabled = false,
            options = {}
          },
        },
        always_mount = {},
      })
    end,
    keys = {
      { "<leader>Ds", "<cmd>DevcontainerStart<cr>", desc = "Start dev container" },
      { "<leader>Da", "<cmd>DevcontainerAttach<cr>", desc = "Attach to dev container" },
      { "<leader>Dt", "<cmd>DevcontainerStop<cr>", desc = "Stop dev container" },
      { "<leader>De", "<cmd>DevcontainerExec<cr>", desc = "Execute in container" },
      { "<leader>Dl", "<cmd>DevcontainerLogs<cr>", desc = "View container logs" },
      { "<leader>Dr", "<cmd>DevcontainerRemoveAll<cr>", desc = "Remove all containers" },
      { "<leader>Dc", "<cmd>DevcontainerEditNearestConfig<cr>", desc = "Edit devcontainer config" },
    },
  },

  -- Database Client (nvim-dbee)
  -- ───────────────────────────────────────────────────
  {
    "kndndrj/nvim-dbee",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    build = function()
      require("dbee").install()
    end,
    config = function()
      require("dbee").setup({
        sources = {
          -- Load from .connections.json in current working directory
          require("dbee.sources").FileSource:new(vim.fn.getcwd() .. "/.connections.json"),
        },
      })
    end,
    keys = {
      { "<leader>B", "<cmd>lua require('dbee').toggle()<cr>", desc = "Toggle database client (dbee)" },
    },
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

  -- Neo-tree Configuration
  -- ───────────────────────────────────────────────────
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      filesystem = {
        filtered_items = {
          visible = true,
        },
        follow_current_file = {
          enabled = false,
        },
      },
    },
  },

  -- Spectre - Search and Replace
  -- ───────────────────────────────────────────────────
  {
    "nvim-pack/nvim-spectre",
    build = false,
    cmd = "Spectre",
    opts = { open_cmd = "noswapfile vnew" },
    keys = {
      { "<leader>S", "<cmd>lua require('spectre').toggle()<cr>", desc = "Toggle Spectre" },
      { "<leader>sw", "<cmd>lua require('spectre').open_visual({select_word=true})<cr>", desc = "Search current word" },
      { "<leader>sw", "<cmd>lua require('spectre').open_visual()<cr>", mode = "v", desc = "Search current word" },
      { "<leader>sp", "<cmd>lua require('spectre').open_file_search({select_word=true})<cr>", desc = "Search on current file" },
    },
  },

  -- Color Schemes
  -- ───────────────────────────────────────────────────
  { "RRethy/base16-nvim" },
  { "marko-cerovac/material.nvim" },
  { "Yazeed1s/minimal.nvim" },
}

