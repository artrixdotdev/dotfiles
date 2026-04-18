local function generate_colors()
   local base46 = require "config.base46"
   local base16 = base46.get_theme_tb "base_16"
   local colors = base46.get_theme_tb "base_30"

   local highlights = {
      BlinkCmpMenu = { bg = colors.black },
      BlinkCmpMenuBorder = { fg = colors.grey_fg },
      BlinkCmpMenuSelection = { link = "PmenuSel", bold = true },
      BlinkCmpScrollBarThumb = { bg = colors.grey },
      BlinkCmpScrollBarGutter = { bg = colors.black2 },
      BlinkCmpLabel = { fg = colors.white },
      BlinkCmpLabelDeprecated = { fg = colors.red, strikethrough = true },
      BlinkCmpLabelMatch = { fg = colors.blue, bold = true },
      BlinkCmpLabelDetail = { fg = colors.light_grey },
      BlinkCmpLabelDescription = { fg = colors.light_grey },
      BlinkCmpSource = { fg = colors.grey_fg },
      BlinkCmpGhostText = { fg = colors.grey_fg },
      BlinkCmpDoc = { bg = colors.black },
      BlinkCmpDocBorder = { fg = colors.grey_fg },
      BlinkCmpDocSeparator = { fg = colors.grey },
      BlinkCmpDocCursorLine = { bg = colors.one_bg },
      BlinkCmpSignatureHelp = { bg = colors.black },
      BlinkCmpSignatureHelpBorder = { fg = colors.grey_fg },
      BlinkCmpSignatureHelpActiveParameter = { fg = colors.blue, bold = true },
   }

   -- Kind highlights
   local kinds = {
      Constant = base16.base09,
      Function = base16.base0D,
      Identifier = base16.base08,
      Field = base16.base08,
      Variable = base16.base0E,
      Snippet = colors.red,
      Text = base16.base0B,
      Structure = base16.base0E,
      Type = base16.base0A,
      Keyword = base16.base07,
      Method = base16.base0D,
      Constructor = colors.blue,
      Folder = base16.base07,
      Module = base16.base0A,
      Property = base16.base08,
      Enum = colors.blue,
      Unit = base16.base0E,
      Class = colors.teal,
      File = base16.base07,
      Interface = colors.green,
      Color = colors.white,
      Reference = base16.base05,
      EnumMember = colors.purple,
      Struct = base16.base0E,
      Value = colors.cyan,
      Event = colors.yellow,
      Operator = base16.base05,
      TypeParameter = base16.base08,
      Copilot = colors.green,
      Codeium = colors.vibrant_green,
      TabNine = colors.baby_pink,
      SuperMaven = colors.yellow,
   }

   for kind, color in pairs(kinds) do
      highlights["BlinkCmpKind" .. kind] = { fg = color }
   end

   base46.install_integration("blink", highlights)
end

return {
   "saghen/blink.cmp",
   build = function()
      require("blink.cmp").build():wait(60000)
   end,
   -- optional: provides snippets for the snippet source
   dependencies = { "saghen/blink.lib", "rafamadriz/friendly-snippets", "onsails/lspkind.nvim", "AvengeMedia/base46" },

   -- use a release tag to download pre-built binaries
   -- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
   -- build = 'cargo build --release',
   -- If you use nix, you can build from source using latest nightly rust with:
   -- build = 'nix run .#build-plugin',

   ---@module 'blink.cmp'
   ---@type blink.cmp.Config
   opts = function()
      generate_colors()
      return {
         -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
         -- 'super-tab' for mappings similar to vscode (tab to accept)
         -- 'enter' for enter to accept
         -- 'none' for no mappings
         --
         -- All presets have the following mappings:
         -- C-space: Open menu or open docs if already open
         -- C-n/C-p or Up/Down: Select next/previous item
         -- C-e: Hide menu
         -- C-k: Toggle signature help (if signature.enabled = true)
         --
         -- See :h blink-cmp-config-keymap for defining your own keymap
         keymap = { preset = "enter" },

         appearance = {
            -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
            -- Adjusts spacing to ensure icons are aligned
            nerd_font_variant = "mono",
         },

         -- (Default) Only show the documentation popup when manually triggered
         completion = {
            menu = {
               draw = {
                  components = {
                     kind_icon = {
                        text = function(ctx)
                           local icon = ctx.kind_icon
                           if vim.tbl_contains({ "Path" }, ctx.source_name) then
                              local dev_icon, _ = require("nvim-web-devicons").get_icon(ctx.label)
                              if dev_icon then
                                 icon = dev_icon
                              end
                           else
                              icon = require("lspkind").symbolic(ctx.kind, {
                                 mode = "symbol",
                              })
                           end

                           return icon .. ctx.icon_gap
                        end,

                        -- Optionally, use the highlight groups from nvim-web-devicons
                        -- You can also add the same function for `kind.highlight` if you want to
                        -- keep the highlight groups in sync with the icons.
                        highlight = function(ctx)
                           local hl = ctx.kind_hl
                           if vim.tbl_contains({ "Path" }, ctx.source_name) then
                              local dev_icon, dev_hl = require("nvim-web-devicons").get_icon(ctx.label)
                              if dev_icon then
                                 hl = dev_hl
                              end
                           end
                           return hl
                        end,
                     },
                  },
               },
            },
            documentation = {
               auto_show = true,
               draw = function(opts)
                  if opts.item and opts.item.documentation and opts.item.documentation.value then
                     local out = require("pretty_hover.parser").parse(opts.item.documentation.value)
                     opts.item.documentation.value = out:string()
                  end

                  opts.default_implementation(opts)
               end,
            },
         },

         -- Default list of enabled providers defined so that you can extend it
         -- elsewhere in your config, without redefining it, due to `opts_extend`
         sources = {
            default = { "lsp", "path", "snippets", "buffer" },
         },

         -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
         -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
         -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
         --
         -- See the fuzzy documentation for more information
         fuzzy = { implementation = "prefer_rust_with_warning" },
      }
   end,
   opts_extend = { "sources.default" },
}
