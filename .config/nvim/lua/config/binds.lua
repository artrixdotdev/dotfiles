
local wk = require("which-key")

wk.add({
    { "<leader>f", group = "file" }, -- group
 { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find File", mode = "n" },
})
