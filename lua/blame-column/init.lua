local config = require("blame-column.config")
local blame_window = require("blame-column.blame_window")

local api = vim.api

local M = {}

M.setup = function(opts)
	config.setup(opts)
	api.nvim_create_user_command("BlameColumnToggle", M.toggle, {})
end

M.toggle = function()
	blame_window.toggle()
end

return M
