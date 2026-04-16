-- Theming system
return {
   "AvengeMedia/base46",
   priority = 1000,
   lazy = false,
   opts = require "config.theme",
   config = function(_, opts)
      require("base46").setup(opts)
      vim.cmd.colorscheme "dms"
   end,
}
