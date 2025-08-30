return {
  "supermaven-inc/supermaven-nvim",
 opts = {
     keymaps = {
         accept_suggestion = "<A-L>",
       },
       color = {
         suggestion_color = "#ffffff",
         cterm = 244,
       },
       log_level = "info", -- set to "off" to disable logging completely
       disable_inline_completion = false, -- disables inline completion for use with cmp
       disable_keymaps = false, -- disables built in keymaps for more manual control
     }

}
