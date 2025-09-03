-- Theming system
return {
   "artrixdotdev/base46-extracted",
   build = function()
      require("base46-extracted").compile()
      require("base46-extracted").load_all_highlights()
   end,
   opts = require "config.theme",
}
