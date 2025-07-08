-- require('telescope').setup({
--   defaults = {
--     theme = "",
--     -- prompt_prefix = "" .. " ",
--     prompt_prefix = "🔭" .. " ",
--     -- selection_caret = "" .. " ",
--     selection_caret = "➤ " .. " ",
--     color_devicons = true,
--     entry_prefix = "  ",
--     initial_mode = "insert",
--     selection_strategy = "reset",
--     vimgrep_arguments = {
--       "rg",
--       "--color=never",
--       "--no-heading",
--       "--with-filename",
--       "--line-number",
--       "--column",
--       "--smart-case",
--       "--hidden",
--       "--glob=!.git/",
--     },
--     ---@usage Mappings are fully customizable. Many familiar mapping patterns are setup as defaults.
--     mappings = {
--       i = {
--         ["<C-n>"] = actions.move_selection_next,
--         ["<C-p>"] = actions.move_selection_previous,
--         ["<C-c>"] = actions.close,
--         ["<C-j>"] = actions.cycle_history_next,
--         ["<C-k>"] = actions.cycle_history_prev,
--         ["<C-q>"] = function(...)
--           actions.smart_send_to_qflist(...)
--           actions.open_qflist(...)
--         end,
--         ["<CR>"] = actions.select_default,
--       },
--       n = {
--         ["<C-n>"] = actions.move_selection_next,
--         ["<C-p>"] = actions.move_selection_previous,
--         ["<C-q>"] = function(...)
--           actions.smart_send_to_qflist(...)
--           actions.open_qflist(...)
--         end,
--       },
--     },
--     file_ignore_patterns = {},
--     path_display = { "smart" },
--     winblend = 0,
--     border = {},
--     borderchars = nil,
--     color_devicons = true,
--     set_env = { ["COLORTERM"] = "truecolor" }, -- default = nil,
--   },
--   pickers = {
--     find_files = {
--       hidden = true,
--     },
--     live_grep = {
--       --@usage don't include the filename in the search results
--       only_sort_text = true,
--     },
--     grep_string = {
--       only_sort_text = true,
--     },
--     buffers = {
--       initial_mode = "normal",
--       mappings = {
--         i = {
--           ["<C-d>"] = actions.delete_buffer,
--         },
--         n = {
--           ["dd"] = actions.delete_buffer,
--         },
--       },
--     },
--     planets = {
--       show_pluto = true,
--       show_moon = true,
--     },
--     git_files = {
--       hidden = true,
--       show_untracked = true,
--     },
--     colorscheme = {
--       enable_preview = true,
--     },
--   },
--   extensions = {
--     fzf = {
--       fuzzy = true, -- false will only do exact matching
--       override_generic_sorter = true, -- override the generic sorter
--       override_file_sorter = true, -- override the file sorter
--       case_mode = "smart_case", -- or "ignore_case" or "respect_case"
--     },
--   },
--   sorting_strategy = 'ascending',
--   layout_strategy = 'center',
--   layout_config = {
--     center = {
--       width  = 0.75,   -- 75% of the screen width
--       height = 0.40,   -- 40% of the screen height
--       preview_cutoff = 1,  -- always cut off the previewer
--     }
--   },
--   border = false,
--   borderchars = {},
--   previewer        = false,
--   file_previewer   = false,
--   grep_previewer   = false,
--   qflist_previewer = false,
--   -- file_previewer = previewers.vim_buffer_cat.new,
--   -- grep_previewer = previewers.vim_buffer_vimgrep.new,
--   -- qflist_previewer = previewers.vim_buffer_qflist.new,
--   file_sorter = sorters.get_fuzzy_file,
--   generic_sorter = sorters.get_generic_fuzzy_sorter,
--   prompt_prefix = ">> ",
-- })

local M = {}

function M.setup()
  local telescope = require('telescope')
  local actions    = require('telescope.actions')
  local themes    = require('telescope.themes')
  local theme_config = function(title) 
    return   {
      prompt_title  = title,
      previewer     = false,
      results_title = false,
      layout_config = { width = 0.6, height = 0.2 },
    }
  end
  
  telescope.setup({
    defaults = {
      prompt_prefix = " 🔭 " .. " ",
      selection_caret = " ➤ " .. " ",
      color_devicons = true,
      sorting_strategy = 'ascending',
      previewer = false,
      mappings = {
        i = { ["<esc>"] = actions.close },
        n = { ["<esc>"] = actions.close },
      },
    },

    pickers = {
      find_files = themes.get_dropdown(theme_config('Find Files')),
      git_files = themes.get_dropdown(theme_config('Git Files')),
      live_grep = themes.get_dropdown(theme_config('Live Grep')),
      buffers = themes.get_dropdown(theme_config('Buffers')),
      help_tags = themes.get_dropdown(theme_config('Help Tags')),
    },

    extensions = {
      fzf = {
        fuzzy                    = true,
        override_generic_sorter  = true,
        override_file_sorter     = true,
        case_mode                = "smart_case",
      },
    },
  })

  local builtin = require('telescope.builtin')
  vim.keymap.set('n','<leader>ff',builtin.find_files,{ desc='Find files' })
  vim.keymap.set('n','<leader>fg',builtin.live_grep,{ desc='Live grep' })
  vim.keymap.set('n','<leader>fb',builtin.buffers,{ desc='Buffers' })
  vim.keymap.set('n','<leader>fh',builtin.help_tags,{ desc='Help tags' })
end

return M

