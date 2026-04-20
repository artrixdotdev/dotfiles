return {
   {
      "davidmh/mdx.nvim",
      config = function()
         pcall(function()
            require("mdx").setup()
         end)
      end,
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
      opts = {
         server = {
            override = false,
         },
      },
   },
   {
      "pmizio/typescript-tools.nvim",
      dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
      opts = {
         filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
      },
   },
}
