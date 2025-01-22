local config = require("blame-column.config")
local blame_window = require("blame-column.blame_window")

local api = vim.api

local M = {}

local function setup_highlights_group()
	vim.api.nvim_set_hl(0, "BlameColumnSummary", { link = "TabLineSel", default = true })
	vim.api.nvim_set_hl(0, "BlameColumnHash", { link = "Comment", default = true })
	vim.api.nvim_set_hl(0, "BlameColumnAuthor", { link = "DiagnosticInfo", default = true })
	vim.api.nvim_set_hl(0, "BlameColumnTime", { link = "DiagnosticWarn", default = true })
end

M.setup = function(opts)
	config.setup(opts)
	setup_highlights_group()
	api.nvim_create_user_command("BlameColumnToggle", M.toggle, {})
end

M.toggle = function()
	blame_window.toggle()
end

return M
