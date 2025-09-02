-- Theming system
return {
   dir = "~/Documents/Code/base46-extracted",
   name = "base46-extracted",
   dev = true,
   build = function()
      require("base46-extracted").compile()
      require("base46-extracted").load_all_highlights()
   end,
   opts = require "config.theme",
}
