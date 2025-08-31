dofile(vim.g.base46_cache .. "nvimtree")
-- File tree plugin
return {
   {
      "nvim-neo-tree/neo-tree.nvim",
      branch = "v3.x",
      dependencies = {
         "nvim-lua/plenary.nvim",
         "MunifTanjim/nui.nvim",
         "nvim-tree/nvim-web-devicons", -- optional, but recommended
      },
      lazy = false, -- neo-tree will lazily load itself
      -- @
      opts = {
         position = "right",
      },
   },
}
