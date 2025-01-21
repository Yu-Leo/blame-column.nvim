local M = {}

---@class blameColumn.LineField
---@field public text string
---@field public hl? string
local LineField = {}

---@class blameColumn.StructedLine
---@field public format string
---@field public fields blameColumn.LineField[]
---@field public hl? string
local StructedLine = {}

---@param datetime_format string
---@param commit_time integer
---@return string
M.get_relative_date = function(datetime_format, commit_time)
	local current_time = vim.fn.strftime("%s")

	local commit_date = math.floor(commit_time / (24 * 60 * 60))
	local current_date = math.floor(current_time / (24 * 60 * 60))
	local delta = current_date - commit_date

	if delta == 0 then
		return "Today"
	end
	if delta == 1 then
		return "Yesterday"
	end
	return tostring(os.date(datetime_format, commit_time))
end

---@class blameColumn.StructurizerFn
---@param general_info blameColumn.GeneralInfo
---@param line_info blameColumn.LineInfo
---@return blameColumn.StructedLine
M.colorized_date_author = function(general_info, line_info)
	local datetime_format = require("blame-column.config").opts.datetime_format
	local commit_time = line_info.author_time

	local formatted_time = tostring(os.date(datetime_format, commit_time))
	if require("blame-column.config").opts.relative_dates then
		formatted_time = M.get_relative_date(datetime_format, commit_time)
	end

	if line_info.is_modified then
		return {
			fields = {
				{
					text = "Not Committed",
				},
			},
			format = " %s ",
			hl = "Comment",
		}
	end

	return {
		fields = {
			{
				text = formatted_time,
			},
			{
				text = line_info.author_surname,
			},
		},
		format = " %-10s %s"
			.. string.rep(" ", general_info.max_lens.author_surname - vim.fn.strdisplaywidth(line_info.author_surname))
			.. " ",
		hl = line_info.hash,
	}
end

return M
