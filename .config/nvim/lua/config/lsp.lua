local wk = require "which-key"

local pid = vim.fn.getpid()

-- Keymaps for LSP
function on_attach(client, bufnr)
   wk.add {
      buffer = bufnr,
      {
         mode = "n",
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
   }
end

-- Disable semantic tokens globally; treesitter highlighting is configured separately.
function on_init(client, _)
   client.server_capabilities.semanticTokensProvider = nil
end

-- Capabilities
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

-- Servers list
local servers = {
   "html",
   "cssls",
   "eslint",
   "biome",
   "taplo",
   "mdx_analyzer",

   {
      "tailwindcss",
      filetypes = {
         "astro",
         "css",
         "html",
         "javascript",
         "javascriptreact",
         "mdx",
         "svelte",
         "typescript",
         "typescriptreact",
         "vue",
      },
      settings = {
         tailwindCSS = {
            includeLanguages = {
               eelixir = "html-eex",
               eruby = "erb",
               htmlangular = "html",
               templ = "html",
            },
         },
      },
   },

   {
      "lua_ls",
      settings = {
         Lua = {
            workspace = {
               library = {
                  [vim.fn.expand "$VIMRUNTIME/lua"] = true,
                  ["$VIMRUNTIME/lua/vim/lsp"] = true,
               },
            },
         },
      },
   },

   {
      "qmlls",
      cmd = { "qmlls", "-E" },
      filetypes = { "qml", "qmldir" },
   },

   {
      "nushell",
      cmd = { "nu", "--lsp" },
      filetypes = { "nu" },
      root_dir = function(bufnr, on_dir)
         local path = vim.api.nvim_buf_get_name(bufnr)
         on_dir(vim.fs.root(path, ".git") or vim.fs.dirname(path))
      end,
      single_file_support = true,
   },

   {
      "jsonls",
      settings = {
         json = {
            schemas = require("schemastore").json.schemas(),
            validate = { enable = true },
         },
      },
   },

   {
      "yamlls",
      filetypes = { "yaml" },
      settings = {
         yaml = {
            schemaStore = {
               enable = false,
               url = "",
            },
            schemas = require("schemastore").yaml.schemas(),
         },
      },
   },
}

if vim.env.PREFIX and vim.env.PREFIX:match "com%.termux" then
   table.insert(servers, {
      "termux",
      cmd = { "termux-language-server" },
      filetypes = { "sh", "bash" },
   })
end

-- Setup all servers
for _, lsp in ipairs(servers) do
   local name = lsp
   local opts = {}

   if type(lsp) == "table" then
      name = lsp[1]
      opts = vim.tbl_deep_extend("force", {}, lsp, {})
      opts[1] = nil
   end

   local config = {
      on_attach = on_attach,
      on_init = on_init,
      capabilities = capabilities,
   }

   config = vim.tbl_deep_extend("force", config, opts)

   vim.lsp.config(name, config)
   vim.lsp.enable(name)
end
