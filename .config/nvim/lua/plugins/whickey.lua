-- Visually displays keybindings and their descriptions
return {
   "folke/which-key.nvim",
   event = "VeryLazy",
   keys = { "<leader>", "<c-w>", '"', "'", "`", "c", "v", "g" },

   opts = {
      preset = "helix",
      delay = 500,
   },
}
