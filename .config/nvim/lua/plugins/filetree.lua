-- File tree plugin
return {

   {
      "mikavilpas/yazi.nvim",
      version = "*",
      cmd = { "Yazi" },
      dependencies = {
         { "nvim-lua/plenary.nvim", lazy = true },
      },
      opts = {
         open_for_directories = false,
         floating_window_scaling_factor = 0.9,
         yazi_floating_window_border = "rounded",
         keymaps = {
            show_help = "<f1>",
         },
      },
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
