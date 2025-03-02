local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    css = { "biome", "prettier" },
    html = { "biome", "prettier" },
    javascript = { "biome", "prettierd", "prettier", stop_after_first = true },
    json = { "biome", "prettierd", "prettier", stop_after_first = true },
    javascriptreact = { "biome", "prettierd", "prettier", stop_after_first = true },
    typescript = { "biome", "prettierd", "prettier", stop_after_first = true },
    typescriptreact = { "biome", "prettierd", "prettier", stop_after_first = true },
  },

  format_on_save = {
    -- These options will be passed to conform.format()
    timeout_ms = 500,
    lsp_fallback = true,
  },
}

return options
