return {
   {
      "mrjones2014/smart-splits.nvim",
      dependencies = {
         { "smart-splits-nvim/backend-zellij-lua", main = "smart-splits-backend-zellij-lua", opts = {} },
      },
      opts = {
         mux = {
            backend = "smart-splits-backend-zellij-lua",
            warn_if_unusable = false,
         },
      },
   },
}
