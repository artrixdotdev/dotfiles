return {
   "supermaven-inc/supermaven-nvim",
   opts = function()
      local colors = require("config.base46").get_theme_tb "base_30"

      return {
         keymaps = {
            accept_suggestion = "<Tab>",
            accept_word = "<S-Tab>",
         },
         color = {
            suggestion_color = colors.grey_fg or "#6c7086",
            cterm = 244,
         },
         disable_inline_completion = false, -- disables inline completion for use with cmp
         disable_keymaps = false, -- disables built in keymaps for more manual control
      }
   end,
}
