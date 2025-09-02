vim.api.nvim_set_option("clipboard", "unnamed")
vim.opt.wrap = false
vim.wo.relativenumber = true
vim.opt.fillchars = { eob = " " }
vim.diagnostic.config { virtual_text = { current_line = true } }
vim.o.winborder = "single"
