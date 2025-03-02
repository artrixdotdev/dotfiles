-- Load NvChad base mappings
require "nvchad.mappings"

local map = vim.keymap.set
local bufnr = vim.api.nvim_get_current_buf()

-- Utility functions
local function move_line(direction)
  local current_line = vim.fn.line "."
  local last_line = vim.fn.line "$"

  -- Check boundaries
  if (direction == "up" and current_line == 1) or (direction == "down" and current_line == last_line) then
    return
  end

  local current_col = vim.fn.col "."
  vim.cmd "delete"

  if direction == "up" then
    vim.cmd "-put!"
    vim.fn.cursor(current_line - 1, current_col)
  else
    vim.cmd "put"
    vim.fn.cursor(current_line + 1, current_col)
  end
end

-- General mappings
local general_mappings = {
  -- Mode switching
  { modes = "n", lhs = ";", rhs = ":", opts = { desc = "CMD enter command mode" } },
  { modes = "i", lhs = "jk", rhs = "<ESC>", opts = { desc = "Exit insert mode" } },
  { modes = "i", lhs = "<C-;>", rhs = "<ESC>:", opts = { desc = "Enter command mode" } },
  -- Undo/Redo
  { modes = { "i", "n" }, lhs = "<C-z>", rhs = "<CMD>undo<CR>", opts = { desc = "Undo" } },
  { modes = { "i", "n" }, lhs = "<C-y>", rhs = "<CMD>redo<CR>", opts = { desc = "Redo" } },

  -- Select all (fixed)
  { modes = { "n", "i" }, lhs = "<C-a>", rhs = "ggVG", opts = { desc = "Select all" } },

  { modes = { "v" }, lhs = "<Tab>", opts = { desc = "Indent line" }, rhs = "<CMD>call <SID>IndentLine()<CR>" },
}

-- Line operations (with HJKL support)
local line_operations = {
  -- Arrow key mappings for line duplication
  { modes = { "n", "i" }, lhs = "<S-A-Up>", rhs = "<CMD>LineDuplicate -1<CR>", opts = { desc = "Duplicate line up" } },
  {
    modes = { "n", "i" },
    lhs = "<S-A-Down>",
    rhs = "<CMD>LineDuplicate +1<CR>",
    opts = { desc = "Duplicate line down" },
  },
  -- HJKL mappings for line duplication
  { modes = { "n", "i" }, lhs = "<S-A-k>", rhs = "<CMD>LineDuplicate -1<CR>", opts = { desc = "Duplicate line up" } },
  { modes = { "n", "i" }, lhs = "<S-A-j>", rhs = "<CMD>LineDuplicate +1<CR>", opts = { desc = "Duplicate line down" } },

  -- Arrow key mappings for visual duplication
  {
    modes = { "v" },
    lhs = "<S-A-Up>",
    rhs = "<CMD>VisualDuplicate -1<CR>",
    opts = { desc = "Duplicate selection up" },
  },
  {
    modes = { "v" },
    lhs = "<S-A-Down>",
    rhs = "<CMD>VisualDuplicate +1<CR>",
    opts = { desc = "Duplicate selection down" },
  },
  -- HJKL mappings for visual duplication
  { modes = { "v" }, lhs = "<S-A-k>", rhs = "<CMD>VisualDuplicate -1<CR>", opts = { desc = "Duplicate selection up" } },
  {
    modes = { "v" },
    lhs = "<S-A-j>",
    rhs = "<CMD>VisualDuplicate +1<CR>",
    opts = { desc = "Duplicate selection down" },
  },
}

-- Line movement mappings
local movement_mappings = {
  -- Arrow key mappings
  {
    modes = { "n", "i" },
    lhs = "<A-Up>",
    rhs = function()
      move_line "up"
    end,
    opts = { desc = "Move line up" },
  },
  {
    modes = { "n", "i" },
    lhs = "<A-Down>",
    rhs = function()
      move_line "down"
    end,
    opts = { desc = "Move line down" },
  },
  -- HJKL mappings
  {
    modes = { "n", "i" },
    lhs = "<A-k>",
    rhs = function()
      move_line "up"
    end,
    opts = { desc = "Move line up" },
  },
  {
    modes = { "n", "i" },
    lhs = "<A-j>",
    rhs = function()
      move_line "down"
    end,
    opts = { desc = "Move line down" },
  },
}

-- Menu mappings
local menu_mappings = {
  {
    modes = "n",
    lhs = "<RightMouse>",
    rhs = function()
      vim.cmd.exec '"normal! \\<RightMouse>"'
      local options = vim.bo.ft == "NvimTree" and "nvimtree" or "default"
      require("menu").open(options, { mouse = true })
    end,
    opts = { desc = "Open context menu" },
  },
  {
    modes = "n",
    lhs = "<C-m>",
    rhs = function()
      require("menu").open "default"
    end,
    opts = { desc = "Open default menu" },
  },
}

-- Language specific mappings
local lang_mappings = {
  {
    modes = "n",
    lhs = "K",
    rhs = function()
      vim.cmd.RustLsp { "hover", "actions" }
    end,
    opts = { silent = true, buffer = bufnr, desc = "Rust hover actions" },
  },
}

-- Visual mode mappings for indenting and unindenting
local visual_mappings = {
  -- Indent selected lines
  {
    modes = "v",
    lhs = "<Tab>",
    rhs = ">gv",
    opts = { desc = "Indent selected lines" },
  },
  -- Unindent selected lines
  {
    modes = "v",
    lhs = "<S-Tab>",
    rhs = "<gv",
    opts = { desc = "Unindent selected lines" },
  },
}

-- Apply all mappings
local function apply_mappings(mappings)
  for _, mapping in ipairs(mappings) do
    map(mapping.modes, mapping.lhs, mapping.rhs, mapping.opts)
  end
end

-- Apply mappings by category
apply_mappings(general_mappings)
apply_mappings(line_operations)
apply_mappings(movement_mappings)
apply_mappings(menu_mappings)
apply_mappings(lang_mappings)
apply_mappings(visual_mappings)

-- Optional: Save mapping (commented out as per original config)
map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>", { desc = "Save file" })
