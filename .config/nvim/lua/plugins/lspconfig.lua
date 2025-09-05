local function generate_colors()
   local colors = require("base46-extracted").get_theme_tb "base_30"
   local colorize = require("base46-extracted.colors").change_hex_lightness

   local hl = {
      -- LSP References
      LspReferenceText = { bg = colors.one_bg3 },
      LspReferenceRead = { bg = colors.one_bg3 },
      LspReferenceWrite = { bg = colors.one_bg3 },

      -- Lsp Diagnostics
      DiagnosticHint = { fg = colors.purple },
      DiagnosticError = { fg = colors.red },
      DiagnosticWarn = { fg = colors.yellow },
      DiagnosticInfo = { fg = colors.green },
      LspSignatureActiveParameter = { fg = colors.black, bg = colors.green },

      LspInlayHint = {
         bg = colorize(colors.black2, vim.o.bg == "dark" and 0 or 3),
         fg = colors.light_grey,
      },
   }
   require("base46-extracted").install_integration("lsp", hl)
end

return {
   {
      "neovim/nvim-lspconfig",
      dependencies = {
         "artrixdotdev/base46-extracted",
      },
      config = function()
         generate_colors()
      end,
   },
   {
      "Fildo7525/pretty_hover",
      event = "LspAttach",
      opts = {},
   },
}
