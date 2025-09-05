return {
   "lukas-reineke/indent-blankline.nvim",
   dependencies = { "nvim-treesitter/nvim-treesitter" },
   main = "ibl",
   ---@module "ibl"
   ---@type ibl.config
   opts = {
      indent = { char = "│" },
   },
}
