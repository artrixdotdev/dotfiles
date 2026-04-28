return {
   {
      "mfussenegger/nvim-dap",
      dependencies = {
         "rcarriga/nvim-dap-ui",
         "nvim-neotest/nvim-nio",
      },
      keys = {
         {
            "<leader>db",
            function()
               require("dap").toggle_breakpoint()
            end,
            desc = "Toggle breakpoint",
         },
         {
            "<leader>dc",
            function()
               require("dap").continue()
            end,
            desc = "Debug continue",
         },
         {
            "<leader>di",
            function()
               require("dap").step_into()
            end,
            desc = "Debug step into",
         },
         {
            "<leader>do",
            function()
               require("dap").step_over()
            end,
            desc = "Debug step over",
         },
         {
            "<leader>dO",
            function()
               require("dap").step_out()
            end,
            desc = "Debug step out",
         },
         {
            "<leader>dr",
            function()
               require("dap").repl.open()
            end,
            desc = "Debug REPL",
         },
         {
            "<leader>du",
            function()
               require("dapui").toggle()
            end,
            desc = "Toggle debug UI",
         },
      },
      config = function()
         local dap = require "dap"
         local dapui = require "dapui"

         dapui.setup()

         dap.listeners.before.attach.dapui_config = function()
            dapui.open()
         end
         dap.listeners.before.launch.dapui_config = function()
            dapui.open()
         end
         dap.listeners.before.event_terminated.dapui_config = function()
            dapui.close()
         end
         dap.listeners.before.event_exited.dapui_config = function()
            dapui.close()
         end
      end,
   },
}
