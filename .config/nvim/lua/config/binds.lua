--- Philosophy:
--- Avoid using CTRL and ALT as they are reserved for zellij and other programs
---
--- Use <leader> for keybinds that do not directly affect or interact with the code (exceptions can be made).
--- All keybinds that directly edit the code shouldn't be prefixed with <leader> or any other modifier

local wk = require "which-key"

wk.add {
   -- Aliases
   { ";", ":", mode = "n" },

   -- Misc
   {
      "<leader>u",
      function()
         require("undotree").toggle()
      end,
      mode = "n",
      desc = "Toggle undo tree",
   },
   { "<leader>s", "<cmd>Telescope aerial<cr>", mode = "n", desc = "Show LSP symbols" },

   -- Session Management
   { "<leader>q", group = "session" },

   {
      "<leader>qs",
      function()
         require("persistence").load()
      end,
      desc = "Restore Session",
      mode = "n",
   },
   {
      "<leader>qS",
      function()
         require("persistence").select()
      end,
      desc = "Select Session",
      mode = "n",
   },
   {
      "<leader>ql",
      function()
         require("persistence").load { last = true }
      end,
      desc = "Restore Last Session",
      mode = "n",
   },
   {
      "<leader>qd",
      function()
         require("persistence").stop()
      end,
      desc = "Don't Save Current Session",
      mode = "n",
   },
   -- Clipboard

   { "cy", '"+y"', mode = { "v" }, desc = "Copy to clipboard", group = "clipboard" },
   { "cyy", '"+yy"', mode = { "n" }, desc = "Copy line to clipboard", group = "clipboard" },
   { "cp", '"+p"', mode = { "n", "v" }, desc = "Paste from clipboard", group = "clipboard" },

   -- File
   { "<leader>f", group = "file" },
   { "<leader>ft", "<cmd>Neotree position=right toggle <cr>", desc = "Open file tree", mode = "n" },
   { "<leader>fw", "<cmd>Telescope live_grep<cr>", desc = "Search word", mode = "n" },
   { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find File", mode = "n" },
   {
      "<leader>fb",
      function()
         require("snipe").open_buffer_menu()
      end,
      desc = "Open buffer",
      mode = "n",
   },
   -- Smart Splits: Resizing
   {
      "<A-h>",
      function()
         require("smart-splits").resize_left()
      end,
      mode = "n",
      desc = "Resize split left",
   },
   {
      "<A-j>",
      function()
         require("smart-splits").resize_down()
      end,
      mode = "n",
      desc = "Resize split down",
   },
   {
      "<A-k>",
      function()
         require("smart-splits").resize_up()
      end,
      mode = "n",
      desc = "Resize split up",
   },
   {
      "<A-l>",
      function()
         require("smart-splits").resize_right()
      end,
      mode = "n",
      desc = "Resize split right",
   },

   -- Smart Splits: Moving between splits
   {
      "<C-h>",
      function()
         require("smart-splits").move_cursor_left()
      end,
      mode = "n",
      desc = "Move to left split",
   },
   {
      "<C-j>",
      function()
         require("smart-splits").move_cursor_down()
      end,
      mode = "n",
      desc = "Move to below split",
   },
   {
      "<C-k>",
      function()
         require("smart-splits").move_cursor_up()
      end,
      mode = "n",
      desc = "Move to above split",
   },
   {
      "<C-l>",
      function()
         require("smart-splits").move_cursor_right()
      end,
      mode = "n",
      desc = "Move to right split",
   },
   {
      "<C-\\>",
      function()
         require("smart-splits").move_cursor_previous()
      end,
      mode = "n",
      desc = "Move to previous split",
   },

   -- Smart Splits: Swapping buffers
   { "<leader><leader>", group = "swap buffer" },
   {
      "<leader><leader>h",
      function()
         require("smart-splits").swap_buf_left()
      end,
      mode = "n",
      desc = "Swap buffer left",
   },
   {
      "<leader><leader>j",
      function()
         require("smart-splits").swap_buf_down()
      end,
      mode = "n",
      desc = "Swap buffer down",
   },
   {
      "<leader><leader>k",
      function()
         require("smart-splits").swap_buf_up()
      end,
      mode = "n",
      desc = "Swap buffer up",
   },
   {
      "<leader><leader>l",
      function()
         require("smart-splits").swap_buf_right()
      end,
      mode = "n",
      desc = "Swap buffer right",
   },
   -- LSP
   { "<leader>r", group = "lsp" },
   {
      "<leader>rn",
      function()
         vim.lsp.buf.rename()
      end,
      desc = "Rename",
      mode = "n",
   },
   {
      "<leader>rr",
      function()
         vim.lsp.buf.references()
      end,
      desc = "References",
      mode = "n",
   },
   {
      "<leader>ra",
      function()
         vim.lsp.buf.code_action()
      end,
      desc = "Code action",
      mode = "n",
   },
   {
      "<leader>rd",
      function()
         vim.lsp.buf.declaration()
      end,
      desc = "Declaration",
      mode = "n",
   },
   {
      "<leader>ri",
      function()
         vim.lsp.buf.implementation()
      end,
      desc = "Implementation",
      mode = "n",
   },
   {
      "rt",
      function()
         vim.lsp.buf.type_definition()
      end,
      desc = "Type definition",
      mode = "n",
   },
}
