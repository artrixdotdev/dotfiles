return {
   -- QOL rust plugin
   {
      "mrcjkb/rustaceanvim",
      dependencies = {
         "mfussenegger/nvim-dap",
      },
      lazy = false, -- This plugin is already lazy
      ft = "rust",
      config = function()
         vim.g.rustaceanvim = function()
            local extension_path = vim.fn.stdpath "data" .. "/mason/packages/codelldb/extension/"
            local codelldb_path = vim.fn.stdpath "data" .. "/mason/packages/codelldb/codelldb"
            local liblldb_path = extension_path .. "lldb/lib/liblldb"
            local this_os = vim.uv.os_uname().sysname

            -- The path is different on Windows
            if this_os:find "Windows" then
               codelldb_path = vim.fn.stdpath "data" .. "\\mason\\packages\\codelldb\\codelldb.exe"
               liblldb_path = extension_path .. "lldb\\bin\\liblldb.dll"
            else
               -- The liblldb extension is .so for Linux and .dylib for MacOS
               liblldb_path = liblldb_path .. (this_os == "Linux" and ".so" or ".dylib")
            end

            local cfg = require "rustaceanvim.config"
            return {
               dap = {
                  adapter = cfg.get_codelldb_adapter(codelldb_path, liblldb_path),
               },
            }
         end
      end,
   },
   -- Standard rust plugin
   {
      "rust-lang/rust.vim",
      ft = "rust",
      init = function()
         vim.g.rustfmt_autosave = 1
      end,
   },
   {
      "lommix/bevy_inspector.nvim",
      dependencies = {
         "nvim-telescope/telescope.nvim",
         "nvim-lua/plenary.nvim",
      },
      ft = "rust",
      cmd = { "BevyInspect", "BevyInspectNamed", "BevyInspectQuery" },
      keys = {
         { "<leader>bia", "<cmd>BevyInspect<cr>", desc = "List Bevy entities" },
         { "<leader>bin", "<cmd>BevyInspectNamed<cr>", desc = "List named Bevy entities" },
         { "<leader>biq", "<cmd>BevyInspectQuery<cr>", desc = "Query Bevy component" },
      },
      opts = {},
   },
}
