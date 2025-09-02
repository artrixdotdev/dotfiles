dofile(vim.g.base46_cache .. "whichkey")

-- Visually displays keybindings and their descriptions
return {
   "folke/which-key.nvim",
   event = "VeryLazy",
   keys = { "<leader>", "<c-w>", '"', "'", "`", "c", "v", "g" },

   opts = function()
      return {
         preset = "helix",
         delay = 500,
      }
   end,
}
