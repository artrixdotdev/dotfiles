return {
   {
      "davidmh/mdx.nvim",
      config = true,
      dependencies = { "nvim-treesitter/nvim-treesitter" },
   },
   {
      "luckasRanarison/tailwind-tools.nvim",
      name = "tailwind-tools",
      build = ":UpdateRemotePlugins",
      dependencies = {
         "nvim-treesitter/nvim-treesitter",
         "nvim-telescope/telescope.nvim",
         "neovim/nvim-lspconfig",
      },
      opts = {}, -- your configuration
   },
   {
      "pmizio/typescript-tools.nvim",
      dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
      opts = {},
   },
}
