-- Symbols/outline plugin, meant to integrate with telescope
return {
   "stevearc/aerial.nvim",
   opts = {
      lazy_load = false,
   },
   dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
   },
}
