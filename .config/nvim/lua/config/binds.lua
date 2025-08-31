local wk = require "which-key"

wk.add {
   -- Aliases
   { ";", ":", mode = "n" },

   -- Misc
   { "<leader>u", "<cmd>lua require('undotree').toggle()<cr>", mode = "n", desc = "Toggle undo tree" },

   -- Clipboard
   { "cp", '"+y"', mode = { "n", "v" }, desc = "Copy to clipboard", group = "clipboard" },
   { "cv", '"+p"', mode = { "n", "v" }, desc = "Paste from clipboard", group = "clipboard" },

   -- File
   { "<leader>f", group = "file" },
   { "<leader>ft", "<cmd>Neotree position=right toggle <cr>", desc = "Open file tree", mode = "n" },
   { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find File", mode = "n" },
}
