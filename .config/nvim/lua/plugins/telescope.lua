local function generate_colors()
   local colors = require("base46-extracted").get_theme_tb "base_30"

   local hl = {
      TelescopePromptTitle = {
         fg = colors.black,
         bg = colors.red,
      },

      TelescopeSelection = { bg = colors.black2, fg = colors.white },
      TelescopeResultsDiffAdd = { fg = colors.green },
      TelescopeResultsDiffChange = { fg = colors.yellow },
      TelescopeResultsDiffDelete = { fg = colors.red },

      TelescopeMatching = { bg = colors.one_bg, fg = colors.blue },
      TelescopeBorder = { fg = colors.one_bg3 },
      TelescopePromptBorder = { fg = colors.one_bg3 },
      TelescopeResultsTitle = { fg = colors.black, bg = colors.green },
      TelescopePreviewTitle = { fg = colors.black, bg = colors.blue },
      TelescopePromptPrefix = { fg = colors.red, bg = colors.black },
      TelescopeNormal = { bg = colors.black },
      TelescopePromptNormal = { bg = colors.black },
   }
   require("base46-extracted").install_integration("telescope", hl)
end

return {
   "nvim-telescope/telescope.nvim",
   event = "VeryLazy",
   requires = { { "nvim-lua/plenary.nvim", "artrixdotdev/base46-extracted", "nvim-treesitter/nvim-treesitter" } },
   opts = function()
      generate_colors()
      return {

         file_ignore_patterns = {
            "yarn%.lock",
            "node_modules/",
            "raycast/",
            "dist/",
            "%.next",
            "%.git/",
            "%.gitlab/",
            "build/",
            "target/",
            "package%-lock%.json",
         },

         extensions = {
            aerial = {
               -- Set the width of the first two columns (the second
               -- is relevant only when show_columns is set to 'both')
               col1_width = 4,
               col2_width = 30,
               -- How to format the symbols
               format_symbol = function(symbol_path, filetype)
                  if filetype == "json" or filetype == "yaml" then
                     return table.concat(symbol_path, ".")
                  else
                     return symbol_path[#symbol_path]
                  end
               end,
               -- Available modes: symbols, lines, both
               show_columns = "both",
            },
         },
      }
   end,
   on_init = function()
      require("telescope").load_extension "aerial"
   end,
}
