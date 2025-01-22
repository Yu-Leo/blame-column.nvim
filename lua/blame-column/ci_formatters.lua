local M = {}

---@param line_info blameColumn.LineInfo
---@param datetime_format string
---@param person string
---@return string
local function format_time_tz(line_info, datetime_format, person)
	return tostring(os.date(datetime_format, line_info[person .. "_time"])) .. " (" .. line_info[person .. "_tz"] .. ")"
end

---@param line_info blameColumn.LineInfo
---@param person string
---@return string
local function format_name_with_mail(line_info, person)
	return line_info[person] .. " " .. line_info[person .. "_mail"]
end

---@param line_info blameColumn.LineInfo
---@param opts blameColumn.OptsCommitInfo
---@return table<string>
M.default_formatter = function(line_info, opts)
	local content = {}

	table.insert(content, line_info.summary)
	table.insert(content, line_info.hash)
	table.insert(content, format_name_with_mail(line_info, "author"))
	table.insert(content, format_time_tz(line_info, opts.datetime_format, "author"))

	return content
end

---@param bufnr integer
M.default_colorizer = function(bufnr)
	vim.api.nvim_buf_add_highlight(bufnr, 0, "BlameColumnSummary", 0, 0, -1)
	vim.api.nvim_buf_add_highlight(bufnr, 0, "BlameColumnHash", 1, 0, 7)
	vim.api.nvim_buf_add_highlight(bufnr, 0, "BlameColumnAuthor", 2, 0, -1)
	vim.api.nvim_buf_add_highlight(bufnr, 0, "BlameColumnTime", 3, 0, -1)
end

return M
