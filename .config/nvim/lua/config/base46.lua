local M = {}

local function base46()
   return require "base46"
end

function M.get_theme_tb(name)
   local current = vim.g.colors_name or "dms"
   local theme = base46().theme_tables[current]

   if not theme then
      vim.cmd.colorscheme "dms"
      theme = base46().theme_tables[current] or base46().theme_tables.dms
   end

   return theme and theme[name] or {}
end

function M.install_integration(name, highlights)
   local ok, integration = pcall(require, "base46.integrations." .. name)
   if ok and type(integration) == "table" then
      for group, value in pairs(highlights) do
         integration[group] = value
      end
      return
   end

   for group, value in pairs(highlights) do
      vim.api.nvim_set_hl(0, group, value)
   end
end

return M
