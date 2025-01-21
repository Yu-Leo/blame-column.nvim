local M = {}

local color_utils = require("blame-column.color_utils")

local function get_random_light_color(opts)
	local r = math.random(opts.r_min, opts.r_max)
	local g = math.random(opts.g_min, opts.g_max)
	local b = math.random(opts.b_min, opts.b_max)
	return color_utils.rgb_to_hex(r, g, b)
end

---@return vim.api.keyset.highlight
M.random_fg = function(_, _)
	local opts = require("blame-column.config").opts.random_fg_opts
	return {
		fg = get_random_light_color(opts),
	}
end

---@param line_info blameColumn.LineInfo
---@param general_info blameColumn.GeneralInfo
---@return vim.api.keyset.highlight
local time_based_bg_color = function(general_info, line_info, opts)
	local delta = 0
	if general_info.total_commits > 1 then
		delta = (opts.lightness_max - opts.lightness_min) / (general_info.total_commits - 1)
	end

	local lightness = opts.lightness_min + delta * line_info.time_order
	return {
		bg = color_utils.hsl_to_hex(opts.hue, opts.saturation, lightness),
	}
end

---@class blameColumn.ColorizerFn
---@param general_info blameColumn.GeneralInfo
---@param line_info blameColumn.LineInfo
---@return vim.api.keyset.highlight
M.time_based_bg = function(general_info, line_info)
	local opts = require("blame-column.config").opts.time_based_bg_opts
	return time_based_bg_color(general_info, line_info, opts)
end

return M
