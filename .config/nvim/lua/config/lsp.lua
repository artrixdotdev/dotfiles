local wk = require("which-key")
local lspconfig = require("lspconfig")


function on_attach(client, bufnr)
  wk.add({
    buffer = bufnr, -- make sure mappings are buffer-local
    {
      mode = "n", -- normal mode
      { "gD", vim.lsp.buf.declaration, desc = "LSP Go to declaration" },
      { "gd", vim.lsp.buf.definition, desc = "LSP Go to definition" },
      { "<leader>wa", vim.lsp.buf.add_workspace_folder, desc = "LSP Add workspace folder" },
      { "<leader>wr", vim.lsp.buf.remove_workspace_folder, desc = "LSP Remove workspace folder" },
      {
        "<leader>wl",
        function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end,
        desc = "LSP List workspace folders",
      },
      { "<leader>D", vim.lsp.buf.type_definition, desc = "LSP Go to type definition" },
    },
  })
end

function on_init(client, _)
  if client.supports_method "textDocument/semanticTokens" then
    client.server_capabilities.semanticTokensProvider = nil
  end
end

local capabilities = vim.lsp.protocol.make_client_capabilities()

capabilities.textDocument.completion.completionItem = {
  documentationFormat = { "markdown", "plaintext" },
  snippetSupport = true,
  preselectSupport = true,
  insertReplaceSupport = true,
  labelDetailsSupport = true,
  deprecatedSupport = true,
  commitCharactersSupport = true,
  tagSupport = { valueSet = { 1 } },
  resolveSupport = {
    properties = {
      "documentation",
      "detail",
      "additionalTextEdits",
    },
  },
}


local servers = { "html", "cssls", "eslint", "biome", "taplo", "mdx_analyzer" }


for _, lsp in ipairs(servers) do
  local name = lsp
  local opts = {}

  -- If it's a table, extract the name and merge options
  if type(lsp) == "table" then
    name = lsp[1]
    opts = vim.tbl_deep_extend("force", {}, lsp, {})
    opts[1] = nil -- remove the name key
  end

  -- Base config
  local config = {
    on_attach = on_attach,
    on_init = on_init,
    capabilities = capabilities,
  }

  config = vim.tbl_deep_extend("force", config, opts)

  lspconfig[name].setup(config)
end
