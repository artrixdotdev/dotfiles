-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}

M.base46 = {
   theme = "catppuccin",
   changed_themes = {
      catppuccin = {
         base_30 = {
            black = "#12121c",
            darker_black = "#0e0e17",
         },
         base_16 = {
            base00 = "#101019",
            base01 = "#12121c",
            base04 = "#0e0e17",
         },
      },
   },
   -- hl_override = {
   -- 	Comment = { italic = true },
   -- 	["@comment"] = { italic = true },
   -- },
}

M.ui = {
   statusline = {
      theme = "minimal",
      separator_style = "round",
   },
}

M.nvdash = {
   load_on_startup = true,
}

return M
