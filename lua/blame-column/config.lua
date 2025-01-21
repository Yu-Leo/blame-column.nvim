local M = {}

local structurizers = require("blame-column.structurizers")
local colorizers = require("blame-column.colorizers")

---@class blameColumn.Opts
---@field public side string
---@field public dynamic_width boolean
---@field public auto_width boolean
---@field public max_width integer
---@field public ignore_filetypes string[]
---@field public ignore_filenames string[]
---@field public window_opts table<string, any>
---@field public hl_by_fields boolean
---@field public time_based_bg_opts table<string, integer>
---@field public random_fg_opts table<string, integer>
---@field public datetime_format string
---@field public relative_dates boolean
---@field public structurizer_fn blameColumn.StructurizerFn
---@field public colorizer_fn blameColumn.ColorizerFn
local defaults = {
	-- On which side of the window with the source buffer the git-blame window will be located.
	-- Available values: "left", "right"
	side = "left",
	-- true: calculate the width of the window based on the content
	-- false: fixed width == max_width
	dynamic_width = true,
	-- true: dynamically change the window width for different source buffers depending on the content
	-- false: do not change the width when changing the source buffer
	auto_width = true,
	-- If dynamic_width = true: the maximum width of the git-blame window. -1 == "unlimited"
	-- If dynamic_width = false: fixed width of the git-blame window. Must be positive number
	max_width = -1,
	-- Types of files for which git-blame window will not be opened
	ignore_filetypes = { "toggleterm", "NvimTree" },
	-- Names of files for which git-blame window will not be opened
	ignore_filenames = { "" },
	-- Options of git-blame window
	window_opts = {
		wrap = false,
		number = false,
		relativenumber = false,
		cursorline = false,
		signcolumn = "no",
		list = false,
	},
	-- false: use one hl group for the entire line
	-- true: use different hl groups for different line fields
	hl_by_fields = false,
	-- Options for colorizers.time_based_bg colorizer
	time_based_bg_opts = {
		hue = 215,
		saturation = 52,
		lightness_min = 10,
		lightness_max = 45,
	},
	-- Options for colorizers.random_fg colorizer
	random_fg_opts = {
		r_min = 100,
		r_max = 220,
		g_min = 100,
		g_max = 220,
		b_min = 100,
		b_max = 220,
	},
	-- Datetime format for commit's times
	datetime_format = "%Y-%m-%d",
	-- Enable or disable relative dates ("today", "yesterday")
	relative_dates = true,
	-- Defines the contents & hl groups of a string in git-blame window
	structurizer_fn = structurizers.colorized_date_author,
	-- Defines the coloring of a string in git-blame window
	colorizer_fn = colorizers.time_based_bg,
}

M.opts = defaults

M.setup = function(opts)
	M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})
end

return M
