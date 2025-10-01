local function center_text(lines)
   local centered = {}
   local max_width = 0

   -- Calculate actual display width for each line
   for _, line in ipairs(lines) do
      -- Strip all ANSI escape sequences
      local clean_line = line:gsub("\027%[[%d;]*m", "")
      local width = vim.fn.strdisplaywidth(clean_line)
      if width > max_width then
         max_width = width
      end
   end

   -- Get terminal width and calculate padding
   local term_width = vim.o.columns
   local padding = math.max(0, math.floor((term_width - max_width) / 2))

   -- Center each line
   for _, line in ipairs(lines) do
      local clean_line = line:gsub("\027%[[%d;]*m", "")
      local line_width = vim.fn.strdisplaywidth(clean_line)
      local line_padding = padding + math.floor((max_width - line_width) / 2)
      local spaces = string.rep(" ", math.max(0, line_padding))
      table.insert(centered, spaces .. line)
   end

   return centered
end

local function generate_colors()
   local theme = require("base46-extracted").get_theme_tb "base_16"

   local highlights = {
      AlphaHeader = { fg = theme.base0D, bold = true },
      AlphaHeaderSecondary = { fg = theme.base0E },
      AlphaButtons = { fg = theme.base05 },
      AlphaShortcut = { fg = theme.base09 },
      AlphaFooter = { fg = theme.base0C, italic = true },

      -- optional accents
      AlphaKeyPrefix = { fg = theme.base08 },
      AlphaHighlight = { fg = theme.base0B, bold = true },
   }

   require("base46-extracted").install_integration("greeter", highlights)
end

-- Generate username header
local hero_output = vim.system({ "sh", "-c", "whoami | figlet -f larry3d" }, { text = true }):wait()

if hero_output.stderr ~= nil and hero_output.stderr ~= "" then
   error(hero_output.stderr)
end

local hero_text = hero_output.stdout
if hero_text == nil or hero_text == "" then
   hero_text = "No hero text"
end

local hero = vim.split(hero_text, "\n")

-- Generate ASCII art from image
local image_path = vim.fn.expand "~/Pictures/wallpapers/Cosmic_Islands.png"
local ascii_art = {}

if vim.fn.filereadable(image_path) == 1 then
   local ascii_output = vim.system({
      "ascii-image-converter",
      image_path,
      "--color",

      "-H",
      "13",
   }, { text = true }):wait()

   if ascii_output.stdout and ascii_output.stdout ~= "" then
      ascii_art = vim.split(ascii_output.stdout, "\n")
   end
end
table.insert(ascii_art, "")

return {
   {
      "m00qek/baleia.nvim",
      version = "*",
      config = function()
         vim.g.baleia = require("baleia").setup {
            async = false,
         }

         -- Command to colorize the current buffer
         vim.api.nvim_create_user_command("BaleiaColorize", function()
            vim.g.baleia.once(vim.api.nvim_get_current_buf())
         end, { bang = true })

         -- Command to show logs
         vim.api.nvim_create_user_command("BaleiaLogs", vim.g.baleia.logger.show, { bang = true })
      end,
   },
   {
      "artrixdotdev/alpha-nvim",
      event = "VimEnter",
      enabled = true,
      init = false,
      dependencies = {
         "nvim-tree/nvim-web-devicons",
      },
      opts = function()
         generate_colors()
         local dashboard = require "alpha.themes.dashboard"

         local combined = ascii_art
         vim.list_extend(combined, hero)
         dashboard.section.header.val = center_text(combined)
         dashboard.section.header.opts = {
            position = "center",
         }

         dashboard.section.buttons.val = {
            dashboard.button("f", " " .. " Find file", "<cmd> Telescope find_files <cr>"),
            dashboard.button("n", " " .. " New file", [[<cmd> ene <BAR> startinsert <cr>]]),
            dashboard.button("g", " " .. " Find text", [[<cmd> Telescope live_grep <cr>]]),
            dashboard.button("r", " " .. " Restore Session", [[<cmd> lua require("persistence").load() <cr>]]),
            dashboard.button("l", "󰒲 " .. " Lazy", "<cmd> Lazy <cr>"),
            dashboard.button("u", " " .. " Update", "<cmd> Lazy update<cr>"),
            dashboard.button("q", " " .. " Quit", "<cmd> qa <cr>"),
         }
         for _, button in ipairs(dashboard.section.buttons.val) do
            button.opts.hl = "AlphaButtons"
            button.opts.hl_shortcut = "AlphaShortcut"
         end
         dashboard.section.header.opts.hl = "AlphaHeader"
         dashboard.section.buttons.opts.hl = "AlphaButtons"
         dashboard.section.footer.opts.hl = "AlphaFooter"
         dashboard.opts.layout[1].val = 3
         dashboard.opts.opts.set_lines = vim.g.baleia.buf_set_lines

         return dashboard
      end,
      config = function(_, dashboard)
         -- close Lazy and re-open when the dashboard is ready
         if vim.o.filetype == "lazy" then
            vim.cmd.close()
            vim.api.nvim_create_autocmd("User", {
               once = true,
               pattern = "AlphaReady",
               callback = function()
                  require("lazy").show()
               end,
            })
         end

         require("alpha").setup(dashboard.opts)

         vim.api.nvim_create_autocmd("User", {
            once = true,
            pattern = "LazyVimStarted",
            callback = function()
               local stats = require("lazy").stats()
               local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
               dashboard.section.footer.val = "⚡ Neovim loaded "
                  .. stats.loaded
                  .. "/"
                  .. stats.count
                  .. " plugins in "
                  .. ms
                  .. "ms"
               pcall(vim.cmd.AlphaRedraw)
            end,
         })

         vim.api.nvim_create_autocmd("VimResized", {
            once = true,
            pattern = "AlphaReady",
            callback = function()
               local combined = ascii_art
               vim.list_extend(combined, hero)
               dashboard.section.header.val = center_text(combined)
               pcall(vim.cmd.AlphaRedraw)
            end,
         })
      end,
   },
}
