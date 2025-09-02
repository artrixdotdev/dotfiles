-- Plugin for making the nvim ui "better"
return {
   "folke/noice.nvim",
   event = "VeryLazy",
   opts = {

      cmdline = {
         enabled = true, -- enables the Noice cmdline UI
         view = "cmdline_popup", -- view for rendering the cmdline. Change to `cmdline` to get a classic cmdline at the bottom
         opts = {}, -- global options for the cmdline. See section on views
         ---@type table<string, CmdlineFormat>
         format = {
            -- conceal: (default=true) This will hide the text in the cmdline that matches the pattern.
            -- view: (default is cmdline view)
            -- opts: any options passed to the view
            -- icon_hl_group: optional hl_group for the icon
            -- title: set to anything or empty string to hide
            cmdline = { pattern = "^:", icon = "", lang = "vim" },
            search_down = { kind = "search", pattern = "^/", icon = " ", lang = "regex" },
            search_up = { kind = "search", pattern = "^%?", icon = " ", lang = "regex" },
            filter = { pattern = "^:%s*!", icon = "$", lang = "bash" },
            lua = { pattern = { "^:%s*lua%s+", "^:%s*lua%s*=%s*", "^:%s*=%s*" }, icon = "", lang = "lua" },
            help = { pattern = "^:%s*he?l?p?%s+", icon = "" },
            input = { view = "cmdline_input", icon = "󰥻 " }, -- Used by input()
            -- lua = false, -- to disable a format, set to `false`
         },
      },
      messages = {
         -- NOTE: If you enable messages, then the cmdline is enabled automatically.
         -- This is a current Neovim limitation.
         enabled = true, -- enables the Noice messages UI
         view = "notify", -- default view for messages
         view_error = "notify", -- view for errors
         view_warn = "notify", -- view for warnings
         view_history = "messages", -- view for :messages
         view_search = "virtualtext", -- view for search count messages. Set to `false` to disable
      },
      popupmenu = {
         enabled = true, -- enables the Noice popupmenu UI
         ---@type 'nui'|'cmp'
         backend = "nui", -- backend to use to show regular cmdline completions
         ---@type NoicePopupmenuItemKind|false
         -- Icons for completion item kinds (see defaults at noice.config.icons.kinds)
         kind_icons = {}, -- set to `false` to disable icons
      },
      -- default options for require('noice').redirect
      -- see the section on Command Redirection
      ---@type NoiceRouteConfig
      redirect = {
         view = "popup",
         filter = { event = "msg_show" },
      },
      -- You can add any custom commands below that will be available with `:Noice command`
      ---@type table<string, NoiceCommand>
      commands = {
         history = {
            -- options for the message history that you get with `:Noice`
            view = "split",
            opts = { enter = true, format = "details" },
            filter = {
               any = {
                  { event = "notify" },
                  { error = true },
                  { warning = true },
                  { event = "msg_show", kind = { "" } },
                  { event = "lsp", kind = "message" },
               },
            },
         },
         -- :Noice last
         last = {
            view = "popup",
            opts = { enter = true, format = "details" },
            filter = {
               any = {
                  { event = "notify" },
                  { error = true },
                  { warning = true },
                  { event = "msg_show", kind = { "" } },
                  { event = "lsp", kind = "message" },
               },
            },
            filter_opts = { count = 1 },
         },
         -- :Noice errors
         errors = {
            -- options for the message history that you get with `:Noice`
            view = "popup",
            opts = { enter = true, format = "details" },
            filter = { error = true },
            filter_opts = { reverse = true },
         },
         all = {
            -- options for the message history that you get with `:Noice`
            view = "split",
            opts = { enter = true, format = "details" },
            filter = {},
         },
      },
      notify = {
         -- Noice can be used as `vim.notify` so you can route any notification like other messages
         -- Notification messages have their level and other properties set.
         -- event is always "notify" and kind can be any log level as a string
         -- The default routes will forward notifications to nvim-notify
         -- Benefit of using Noice for this is the routing and consistent history view
         enabled = true,
         view = "notify",
      },
      lsp = {
         progress = {
            enabled = true,
            -- Lsp Progress is formatted using the builtins for lsp_progress. See config.format.builtin
            -- See the section on formatting for more details on how to customize.
            --- @type NoiceFormat|string
            format = "lsp_progress",
            --- @type NoiceFormat|string
            format_done = "lsp_progress_done",
            throttle = 1000 / 30, -- frequency to update lsp progress message
            view = "mini",
         },

         message = {
            -- Messages shown by lsp servers
            enabled = true,
            view = "notify",
            opts = {},
         },
         -- defaults for hover and signature help
         documentation = {
            view = "hover",
            ---@type NoiceViewOptions
            opts = {
               lang = "markdown",
               replace = true,
               render = "plain",
               format = { "{message}" },
               win_options = { concealcursor = "n", conceallevel = 3 },
            },
         },
      },
      markdown = {
         hover = {
            ["|(%S-)|"] = vim.cmd.help, -- vim help links
            ["%[.-%]%((%S-)%)"] = require("noice.util").open, -- markdown links
         },
         highlights = {
            ["|%S-|"] = "@text.reference",
            ["@%S+"] = "@parameter",
            ["^%s*(Parameters:)"] = "@text.title",
            ["^%s*(Return:)"] = "@text.title",
            ["^%s*(See also:)"] = "@text.title",
            ["{%S-}"] = "@parameter",
         },
      },
      health = {
         checker = true, -- Disable if you don't want health checks to run
      },
      ---@type NoicePresets
      presets = {
         -- you can enable a preset by setting it to true, or a table that will override the preset config
         -- you can also add custom presets that you can enable/disable with enabled=true
         bottom_search = false, -- use a classic bottom cmdline for search
         command_palette = true, -- position the cmdline and popupmenu together
         long_message_to_split = false, -- long messages will be sent to a split
         inc_rename = false, -- enables an input dialog for inc-rename.nvim
         lsp_doc_border = true, -- add a border to hover docs and signature help
      },
   },
   dependencies = {
      -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
      "MunifTanjim/nui.nvim",
      -- OPTIONAL:
      --   `nvim-notify` is only needed, if you want to use the notification view.
      --   If not available, we use `mini` as the fallback
      "rcarriga/nvim-notify",
   },
}
