-- File tree plugin
return {

   {
      "stevearc/oil.nvim",
      ---@module 'oil'
      ---@type oil.SetupOpts
      opts = {},
      -- Optional dependencies
      dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
      -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
      lazy = false,
   },
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
         filesystem = {
            filtered_items = {
               visible = false, -- hide filtered items on open
               hide_gitignored = true,
               hide_dotfiles = false,
               hide_by_name = {
                  "package-lock.json",
                  ".changeset",
                  ".prettierrc.json",
               },
               never_show = { ".git" },
            },
         },
      },
   },
}
