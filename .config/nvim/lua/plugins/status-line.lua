return {
   "nvim-lualine/lualine.nvim",
   dependencies = {
      "nvim-tree/nvim-web-devicons",
      "AvengeMedia/base46",
      "mrjones2014/smart-splits.nvim",
   },
   priority = 850,
   opts = function()
      local colors = require("config.base46").get_theme_tb "base_30"
      local mux = require "smart-splits"

      local bubbles_theme = {
         normal = {
            a = { fg = colors.black, bg = colors.blue, gui = "bold" },
            b = { fg = colors.white, bg = colors.black2 },
            c = { fg = colors.light_grey, bg = colors.black },
         },
         insert = { a = { fg = colors.black, bg = colors.green, gui = "bold" } },
         visual = { a = { fg = colors.black, bg = colors.purple, gui = "bold" } },
         replace = { a = { fg = colors.black, bg = colors.red, gui = "bold" } },
         command = { a = { fg = colors.black, bg = colors.orange, gui = "bold" } },
         inactive = {
            a = { fg = colors.grey_fg, bg = colors.black },
            b = { fg = colors.grey_fg, bg = colors.black },
            c = { fg = colors.grey_fg, bg = colors.black },
         },
      }

      -- Custom separator component
      local gap = function()
         return ""
      end

      return {
         options = {
            theme = bubbles_theme,
            globalstatus = true,
            draw_empty = true,
            component_separators = "|",
            section_separators = "",
            disabled_filetypes = { statusline = { "alpha" } },
         },
         sections = {
            -- LEFT SIDE
            lualine_a = {
               {
                  function()
                     local mode = vim.fn.mode()
                     if mode == "n" then
                        return "󰘳 "
                     elseif mode == "i" then
                        return "󰘲 "
                     elseif mode == "v" or mode == "V" then
                        return "󰘯 "
                     else
                        return " "
                     end
                  end,
                  separator = { left = "", right = "" },
                  color = { gui = "bold" },
               },
            },
            lualine_b = {
               gap,
               {
                  "filetype",
                  icon_only = true,
                  color = { gui = "bold", bg = colors.one_bg3, fg = colors.white },
                  separator = { left = "  " },
               },
               {
                  "filename",
                  color = { bg = colors.one_bg3, fg = colors.white },
                  separator = { right = "" },
               },
            },
            lualine_c = {
               {
                  "diagnostics",

                  -- Table of diagnostic sources, available sources are:
                  --   'nvim_lsp', 'nvim_diagnostic', 'nvim_workspace_diagnostic', 'coc', 'ale', 'vim_lsp'.
                  -- or a function that returns a table as such:
                  --   { error=error_cnt, warn=warn_cnt, info=info_cnt, hint=hint_cnt }
                  sources = { "nvim_diagnostic", "coc" },

                  -- Displays diagnostics for the defined severity types
                  sections = { "error", "warn", "info", "hint" },

                  diagnostics_color = {
                     -- Same values as the general color option can be used here.
                     error = "DiagnosticError", -- Changes diagnostics' error color.
                     warn = "DiagnosticWarn", -- Changes diagnostics' warn color.
                     info = "DiagnosticInfo", -- Changes diagnostics' info color.
                     hint = "DiagnosticHint", -- Changes diagnostics' hint color.
                  },
                  symbols = { error = " ", warn = " ", info = " ", hint = " " },

                  colored = true, -- Displays diagnostics status in color if set to true.
                  update_in_insert = false, -- Update diagnostics in insert mode.
                  always_visible = false, -- Show diagnostics even if there are none.
               },
            },

            -- RIGHT SIDE
            lualine_x = {
               {
                  "branch",
                  icon = "󰘬",
                  separator = { left = "", right = " " },
                  color = { bg = colors.green, fg = colors.black, gui = "bold" },
                  on_click = mux.swap_buf_up(),
               },
            },
            lualine_y = {
               {
                  "diff",
                  symbols = {
                     added = "▴ ",
                     modified = "● ",
                     removed = "✕ ",
                  },
                  color = { bg = colors.black, fg = colors.light_grey },
               },
               {
                  function()
                     local ok, opencode = pcall(require, "opencode")
                     if not ok then
                        return ""
                     end
                     return opencode.statusline()
                  end,
                  color = { bg = colors.black2, fg = colors.teal, gui = "bold" },
               },
            },
            lualine_z = {
               {
                  "location",
                  separator = { left = " ", right = "" },
                  color = { bg = colors.sun, fg = colors.black, gui = "bold" },
               },
            },
         },
         tabline = {},
         extensions = {},
      }
   end,
}
