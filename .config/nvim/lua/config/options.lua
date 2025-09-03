vim.opt.wrap = false
vim.wo.relativenumber = true
vim.opt.fillchars = { eob = " " }
vim.diagnostic.config { virtual_text = { current_line = true } }
-- Runs whoami command to get liveshare username
vim.g.instant_username = vim.fn.system("whoami"):gsub("%s+", "")

local snipe = require "snipe"
snipe.ui_select_menu = require("snipe.menu"):new { position = "center" }
snipe.ui_select_menu:add_new_buffer_callback(function(m)
   vim.keymap.set("n", "<esc>", function()
      m:close()
   end, { nowait = true, buffer = m.buf })
end)
vim.ui.select = snipe.ui_select
vim.o.winborder = "single"
