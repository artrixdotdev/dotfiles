dofile(vim.g.base46_cache .. "mason")

-- LSP, DAP, and linter manager
return {
   "mason-org/mason.nvim",
   opts = {
      ui = {
         icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
         },
      },
   },
}
