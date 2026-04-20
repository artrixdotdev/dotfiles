local function generate_colors()
   local base46 = require "config.base46"
   local theme = base46.get_theme_tb "base_16"
   local base30 = base46.get_theme_tb "base_30"
   local opts = require "config.theme"

   local higlights = {
      ["@variable"] = { fg = theme.base05 },
      ["@variable.builtin"] = { fg = theme.base09 },
      ["@variable.parameter"] = { fg = theme.base08 },
      ["@variable.member"] = { fg = theme.base08 },
      ["@variable.member.key"] = { fg = theme.base08 },

      ["@module"] = { fg = theme.base08 },
      -- ["@module.builtin"] = { fg = theme.base08 },

      ["@constant"] = { fg = theme.base09 },
      ["@constant.builtin"] = { fg = theme.base09 },
      ["@constant.macro"] = { fg = theme.base08 },

      ["@string"] = { fg = theme.base0B },
      ["@string.regex"] = { fg = theme.base0C },
      ["@string.escape"] = { fg = theme.base0C },
      ["@character"] = { fg = theme.base08 },
      -- ["@character.special"] = { fg = theme.base08 },
      ["@number"] = { fg = theme.base09 },
      ["@number.float"] = { fg = theme.base09 },

      ["@annotation"] = { fg = theme.base0F },
      ["@attribute"] = { fg = theme.base0A },
      ["@error"] = { fg = theme.base08 },

      ["@keyword.exception"] = { fg = theme.base08 },
      ["@keyword"] = { fg = theme.base0E },
      ["@keyword.function"] = { fg = theme.base0E },
      ["@keyword.return"] = { fg = theme.base0E },
      ["@keyword.operator"] = { fg = theme.base0E },
      ["@keyword.import"] = { link = "Include" },
      ["@keyword.conditional"] = { fg = theme.base0E },
      ["@keyword.conditional.ternary"] = { fg = theme.base0E },
      ["@keyword.repeat"] = { fg = theme.base0A },
      ["@keyword.storage"] = { fg = theme.base0A },
      ["@keyword.directive.define"] = { fg = theme.base0E },
      ["@keyword.directive"] = { fg = theme.base0A },

      ["@function"] = { fg = theme.base0D },
      ["@function.builtin"] = { fg = theme.base0D },
      ["@function.macro"] = { fg = theme.base08 },
      ["@function.call"] = { fg = theme.base0D },
      ["@function.method"] = { fg = theme.base0D },
      ["@function.method.call"] = { fg = theme.base0D },
      ["@constructor"] = { fg = theme.base0C },

      ["@operator"] = { fg = theme.base05 },
      ["@reference"] = { fg = theme.base05 },
      ["@punctuation.bracket"] = { fg = theme.base0F },
      ["@punctuation.delimiter"] = { fg = theme.base0F },
      ["@symbol"] = { fg = theme.base0B },
      ["@tag"] = { fg = theme.base0A },
      ["@tag.attribute"] = { fg = theme.base08 },
      ["@tag.delimiter"] = { fg = theme.base0F },
      ["@text"] = { fg = theme.base05 },
      ["@text.emphasis"] = { fg = theme.base09 },
      ["@text.strike"] = { fg = theme.base0F, strikethrough = true },
      ["@type.builtin"] = { fg = theme.base0A },
      ["@definition"] = { sp = theme.base04, underline = true },
      ["@scope"] = { bold = true },
      ["@property"] = { fg = theme.base08 },

      -- markup
      ["@markup.heading"] = { fg = theme.base0D },
      ["@markup.raw"] = { fg = theme.base09 },
      ["@markup.link"] = { fg = theme.base08 },
      ["@markup.link.url"] = { fg = theme.base09, underline = true },
      ["@markup.link.label"] = { fg = theme.base0C },
      ["@markup.list"] = { fg = theme.base08 },
      ["@markup.strong"] = { bold = true },
      ["@markup.underline"] = { underline = true },
      ["@markup.italic"] = { italic = true },
      ["@markup.strikethrough"] = { strikethrough = true },
      ["@markup.quote"] = { bg = opts.transparency and nil or base30.black2 },

      ["@comment"] = { fg = base30.grey_fg },
      ["@comment.todo"] = { fg = base30.grey, bg = base30.white },
      ["@comment.warning"] = { fg = base30.black2, bg = theme.base09 },
      ["@comment.note"] = { fg = base30.black, bg = base30.blue },
      ["@comment.danger"] = { fg = base30.black2, bg = base30.red },

      ["@diff.plus"] = { fg = base30.green },
      ["@diff.minus"] = { fg = base30.red },
      ["@diff.delta"] = { fg = base30.light_grey },
   }
   base46.install_integration("treesitter", higlights)
end

-- modified version of code from this config
--https://github.com/fredrikaverpil/dotfiles/blob/main/nvim-fredrik/lua/fredrik/plugins/core/treesitter.lua
return {
   {
      "nvim-treesitter/nvim-treesitter",
      lazy = true,
      event = "BufRead",
      branch = "main",
      build = ":TSUpdate",
      ---@class TSConfig
      opts = {
         -- custom handling of parsers
         ensure_installed = {
            "astro",
            "bash",
            "c",
            "css",
            "diff",
            "go",
            "gomod",
            "gowork",
            "gosum",
            "graphql",
            "html",
            "javascript",
            "typescript",
            "tsx",
            "jsdoc",
            "json",
            "json5",
            "lua",
            "luadoc",
            "luap",
            "markdown",
            "markdown_inline",
            "python",
            "query",
            "regex",
            "toml",
            "tsx",
            "typescript",
            "vim",
            "vimdoc",
            "yaml",
            "ruby",
            "rust",
            "kdl",
            "qmljs",
            "qmldir",
         },
      },
      config = function(_, opts)
         generate_colors()
         require "config.filemap"
         local parser_filetypes = {
            javascript = { "javascript", "javascriptreact" },
            qmljs = { "qml" },
            tsx = { "typescriptreact" },
         }

         -- install parsers from custom opts.ensure_installed
         if opts.ensure_installed and #opts.ensure_installed > 0 then
            require("nvim-treesitter").install(opts.ensure_installed)
            -- register and start parsers for filetypes
            for _, parser in ipairs(opts.ensure_installed) do
               local filetypes = parser_filetypes[parser] or { parser }
               vim.treesitter.language.register(parser, filetypes)

               vim.api.nvim_create_autocmd({ "FileType" }, {
                  pattern = filetypes,
                  callback = function(event)
                     pcall(vim.treesitter.start, event.buf, parser)
                  end,
               })
            end
         end

         -- Auto-install and start parsers for filetypes not listed above.
         vim.api.nvim_create_autocmd({ "FileType" }, {
            callback = function(event)
               local bufnr = event.buf
               local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })

               -- Skip if no filetype
               if filetype == "" then
                  return
               end

               -- Check if this filetype is already handled by explicit opts.ensure_installed config
               for _, parser in pairs(opts.ensure_installed) do
                  local ft_table = parser_filetypes[parser] or { parser }
                  if vim.tbl_contains(ft_table, filetype) then
                     return -- Already handled above
                  end
               end

               -- Get parser name based on filetype
               local parser_name = vim.treesitter.language.get_lang(filetype) -- might return filetype (not helpful)
               if not parser_name then
                  return
               end
               local parser_installed = pcall(vim.treesitter.get_parser, bufnr, parser_name)

               if not parser_installed then
                  -- If not installed, install parser synchronously
                  require("nvim-treesitter").install({ parser_name }):wait(30000)
               end

               -- let's check again
               parser_installed = pcall(vim.treesitter.get_parser, bufnr, parser_name)

               if parser_installed then
                  -- Start treesitter for this buffer
                  pcall(vim.treesitter.start, bufnr, parser_name)
               end
            end,
         })
      end,
   },
}
