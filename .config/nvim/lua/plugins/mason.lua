-- LSP, DAP, and linter manager
return {
   "mason-org/mason.nvim",
   dependencies = {
      "artrixdotdev/base46-extracted",
   },
   on_init = function()
      local colors = require("base46-extracted").get_theme_tb "base_30"

      require("base46-extracted").install_integration("mason", {
         MasonHeader = { bg = colors.red, fg = colors.black },
         MasonHighlight = { fg = colors.blue },
         MasonHighlightBlock = { fg = colors.black, bg = colors.green },
         MasonHighlightBlockBold = { link = "MasonHighlightBlock" },
         MasonHeaderSecondary = { link = "MasonHighlightBlock" },
         MasonMuted = { fg = colors.light_grey },
         MasonMutedBlock = { fg = colors.light_grey, bg = colors.one_bg },
      })
   end,
   opts = {
      registries = {
         "github:mason-org/mason-registry",
         "github:Crashdummyy/mason-registry",
      },
      ui = {
         icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
         },
      },
   },
}
