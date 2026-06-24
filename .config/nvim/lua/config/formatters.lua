-- All formatters must be installed via Mason or in the system path.
local function get_js_formatter(bufnr)
   if vim.fs.root(bufnr, { "biome.json", "biome.jsonc" }) then
      return { "biome" }
   end
   return { "prettierd", "prettier", stop_after_first = true }
end

return {
   lua = { "stylua" },
   rust = { "rustfmt", lsp_format = "fallback" },
   javascript = get_js_formatter,
   javascriptreact = get_js_formatter,
   typescript = get_js_formatter,
   typescriptreact = get_js_formatter,
   astro = { "prettierd", "prettier", lsp_format = "fallback" },
   kdl = { "kdlfmt" },
}
