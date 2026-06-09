return {
   "henriklovhaug/Preview.nvim",
   cmd = { "Preview" },
   ft = { "markdown" },
   config = function()
      require("preview").setup()
   end,
}
