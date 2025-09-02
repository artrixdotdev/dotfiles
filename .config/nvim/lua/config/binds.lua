local wk = require "which-key"

wk.add {
   -- Aliases
   { ";", ":", mode = "n" },

   -- Misc
   { "<leader>u", "<cmd>lua require('undotree').toggle()<cr>", mode = "n", desc = "Toggle undo tree" },
   { "<leader>s", "<cmd>Telescope lsp_document_symbols<cr>", mode = "n", desc = "Show LSP symbols" },

   -- Clipboard

   { "cy", '"+y"', mode = { "n", "v" }, desc = "Copy to clipboard", group = "clipboard" },
   { "cp", '"+p"', mode = { "n", "v" }, desc = "Paste from clipboard", group = "clipboard" },

   -- File
   { "<leader>f", group = "file" },
   { "<leader>ft", "<cmd>Neotree position=right toggle <cr>", desc = "Open file tree", mode = "n" },
   { "<leader>fw", "<cmd>Telescope live_grep<cr>", desc = "Search word", mode = "n" },
   { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find File", mode = "n" },

   -- Hover
   -- {
   --    "K",
   --    function()
   --       require("pretty_hover").hover()
   --    end,
   --    mode = "n",
   --    desc = "Hover",
   -- },
   -- -- {
   --    "gK",
   --    function()
   --       require("hover").hover_select()
   --    end,
   --    mode = "n",
   --    desc = "Hover (select)",
   -- },
   -- {
   --    "<C-p>",
   --    function()
   --       require("hover").hover_switch "previous"
   --    end,
   --    mode = "n",
   --    desc = "Hover (previous source)",
   -- },
   -- {
   --    "<C-n>",
   --    function()
   --       require("hover").hover_switch "next"
   --    end,
   --    mode = "n",
   --    desc = "Hover (next source)",
   -- },
   -- {
   --    "<MouseMove>",
   --    function()
   --       require("hover").hover_mouse()
   --    end,
   --    mode = "n",
   --    desc = "Hover (mouse)",
   -- },
}
