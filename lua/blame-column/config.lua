local M = {}

local structurizers = require("blame-column.structurizers")
local colorizers = require("blame-column.colorizers")
local ci_formatters = require("blame-column.ci_formatters")
local fci_openers = require("blame-column.fci_openers")

---@class blameColumn.OptsCommitInfo
---@field public enabled_from_blame boolean
---@field public formatter_fn function
---@field public colorizer_fn function
---@field public datetime_format string
---@field public max_width integer
---@field public window_opts table<string, any>
---@field public follow_cursor boolean
local OptsCommitInfo = {}

---@class blameColumn.OptsFullCommitInfo
---@field public enabled_from_blame boolean
---@field public opener_fn function
local OptsFullCommitInfo = {}

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
---@field public structurizer_fn function
---@field public colorizer_fn function
---@field public commit_info blameColumn.OptsCommitInfo
---@field public full_commit_info blameColumn.OptsFullCommitInfo
---@field public mappings table<string, string>
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
	datetime_format = "%d.%m.%Y",
	-- Enable or disable relative dates ("today", "yesterday")
	relative_dates = true,
	-- Defines the contents & hl groups of a string in git-blame window
	structurizer_fn = structurizers.colorized_date_author,
	-- Defines the coloring of a string in git-blame window
	colorizer_fn = colorizers.time_based_bg,
	-- Options for commit information pop-up window
	commit_info = {
		-- Enable or disable opening from the blame window
		enabled_from_blame = true,
		-- Defines the contents of pop-up window
		formatter_fn = ci_formatters.default_formatter,
		-- Defines the colors of pop-up window
		colorizer_fn = ci_formatters.default_colorizer,
		-- Datetime format for commit's times
		datetime_format = "%d.%m.%Y %H:%M:%S",
		-- The maximum width of the pop-up window. -1 == "unlimited"
		max_width = -1,
		-- Options of commit info pop-up window
		window_opts = {
			border = "single",
			wrap = false,
			number = false,
			relativenumber = false,
			cursorline = false,
			signcolumn = "no",
			list = false,
		},
		-- If true, the pop-up window will follow the cursor and be redrawn for each line of git blame
		follow_cursor = true,
	},
	-- Options for full commit information in third-party plugin
	full_commit_info = {
		-- Enable or disable opening from the blame window
		enabled_from_blame = true,
		-- Defines the function that will be performed to open
		opener_fn = fci_openers.diffview,
	},
	mappings = {
		open_commit_info_from_blame = "K",
		close_commit_info_from_blame = "<ESC>",
		close_commit_info = "<ESC>",
		open_full_commit_info_from_blame = "L",
	},
}

M.opts = defaults

---@param opts blameColumn.Opts
M.setup = function(opts)
	M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})
end

return M
