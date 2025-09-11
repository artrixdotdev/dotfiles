local M = {}

M.assign_highlights = function(hl)
   for group, opts in pairs(hl) do
      vim.api.nvim_set_hl(0, group, opts)
   end
end

return M
