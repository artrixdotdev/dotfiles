-- local M = {}
--
-- M.base46 = {
--    theme = "blossom_light",
--    changed_themes = {
--       catppuccin = {
--          base_30 = {
--             black = "#12121c",
--             darker_black = "#0e0e17",
--          },
--          base_16 = {
--             base00 = "#101019",
--             base01 = "#12121c",
--             base04 = "#0e0e17",
--          },
--       },
--    },
--    -- hl_override = {
--    -- 	Comment = { italic = true },
--    -- 	["@comment"] = { italic = true },
--    -- },
-- }

-- local theme = require("config.base46").get_theme_tb "base_30"
--
-- for k, v in pairs(theme) do
--    print(k .. " = " .. v)
-- end

return {
   integrations = {
      defaults = true,
      syntax = true,
      treesitter = true,
      semantic_tokens = true,
      lsp = true,
      telescope = true,
      mason = true,
      blink = true,
      whichkey = true,
      alpha = true,
      devicons = true,
      git = true,
      statusline = true,
      notify = true,
   },
}
