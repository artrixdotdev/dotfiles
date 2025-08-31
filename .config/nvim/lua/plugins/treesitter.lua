pcall(function()
   dofile(vim.g.base46_cache .. "syntax")
   dofile(vim.g.base46_cache .. "treesitter")
end)

return { "nvim-treesitter/nvim-treesitter", branch = "main", lazy = false, build = ":TSUpdate" }
