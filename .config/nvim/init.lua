vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"

require "config.lazy"
require "config.options"
require "config.binds"
require "config.lsp"

dofile(vim.g.base46_cache .. "syntax")
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")
