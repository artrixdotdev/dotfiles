require "nvchad.options"

-- add yours here!

-- local o = vim.o
-- o.cursorlineopt ='both' -- to enable cursorline!
--
vim.opt.wrap = false

vim.filetype.add {
   extension = { rasi = "rasi" },
   pattern = {
      [".*/waybar/config"] = "jsonc",
      [".*/mako/config"] = "dosini",
      [".*/kitty/*.conf"] = "bash",
      [".*/hypr/.*%.conf"] = "hyprlang",
      [".*/bun.lock"] = "json5",
      [".*/ghostty/config"] = "toml",
   },
}
