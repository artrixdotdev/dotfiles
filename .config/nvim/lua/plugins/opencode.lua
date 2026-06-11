return {
   "nickjvandyke/opencode.nvim",
   version = "*",
   keys = {
      {
         "<leader>oo",
         function()
            require("opencode").start()
         end,
         mode = { "n", "t" },
         desc = "Start opencode",
      },
      {
         "<leader>oa",
         function()
            require("opencode").ask "@this: "
         end,
         mode = { "n", "x" },
         desc = "Ask opencode",
      },
      {
         "<leader>oA",
         function()
            require("opencode").prompt "@this:"
         end,
         mode = { "n", "x" },
         desc = "Ask opencode and submit",
      },
      {
         "<leader>os",
         function()
            require("opencode").select()
         end,
         mode = "n",
         desc = "Select opencode action",
      },
      {
         "<leader>od",
         function()
            require("opencode").prompt "Review @diagnostics and propose fixes"
         end,
         mode = "n",
         desc = "Review diagnostics",
      },
      {
         "<leader>or",
         function()
            require("opencode").prompt "Review @this for correctness and readability"
         end,
         mode = { "n", "x" },
         desc = "Review selection",
      },
      {
         "<leader>of",
         function()
            require("opencode").prompt "Fix @this"
         end,
         mode = { "n", "x" },
         desc = "Fix selection",
      },
      {
         "<leader>ot",
         function()
            require("opencode").prompt "Add tests for @this"
         end,
         mode = { "n", "x" },
         desc = "Add tests",
      },
      {
         "<leader>on",
         function()
            require("opencode").command "session.new"
         end,
         mode = "n",
         desc = "New opencode session",
      },
      {
         "<leader>oc",
         function()
            require("opencode").command "session.compact"
         end,
         mode = "n",
         desc = "Compact session",
      },
      {
         "<leader>oi",
         function()
            require("opencode").command "session.interrupt"
         end,
         mode = "n",
         desc = "Interrupt opencode",
      },
      {
         "go",
         function()
            return require("opencode").operator "@this "
         end,
         mode = { "n", "x" },
         expr = true,
         desc = "Send range to opencode",
      },
      {
         "goo",
         function()
            return require("opencode").operator "@this " .. "_"
         end,
         mode = "n",
         expr = true,
         desc = "Send line to opencode",
      },
   },
   config = function()
      local function has_zellij()
         return vim.env.ZELLIJ ~= nil and vim.fn.executable "zellij" == 1
      end

      local function open_in_zellij()
         local nvim_socket = vim.v.servername
         local opencode_port = "4096"
         vim.system({
            "zellij",
            "run",
            "--name",
            "opencode",
            "--cwd",
            vim.fn.getcwd(),
            "--",
            "env",
            "NVIM=" .. nvim_socket,
            "NVIM_LISTEN_ADDRESS=" .. nvim_socket,
            "opencode",
            "--port",
            opencode_port,
         }, { detach = true })
      end

      local opts = {
         lsp = {
            enabled = true,
         },
      }

      if has_zellij() then
         opts.server = {
            url = "http://127.0.0.1:4096",
            start = open_in_zellij,
            toggle = open_in_zellij,
            stop = function()
               vim.notify("Close the opencode zellij pane to stop opencode", vim.log.levels.INFO)
            end,
         }
      end

      vim.g.opencode_opts = opts

      vim.o.autoread = true

      local ok, wk = pcall(require, "which-key")
      if ok then
         wk.add { { "<leader>o", group = "opencode" } }
      end
   end,
}
