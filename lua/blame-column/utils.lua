local api = vim.api

local M = {}

---@class blameColumn.EnrichedLine
---@field public idx integer
---@field public format string
---@field public fields blameColumn.LineField[]
---@field public hl string
local EnrichedLine = {}

---@param side string
---@return string
M.get_open_split_cmd = function(side)
	if side == "right" then
		return "vsplit"
	end
	return "lefta vsplit"
end

---@param opts blameColumn.Opts
---@return boolean
M.is_blame_availible = function(opts)
	local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD"):gsub("\n", "")
	if branch:match("fatal") then
		return false
	end

	local bufnr = api.nvim_get_current_buf()

	local filetype = vim.fn.getbufvar(bufnr, "&filetype")
	for _, ignore in ipairs(opts.ignore_filetypes) do
		if filetype == ignore then
			return false
		end
	end

	local filename = vim.api.nvim_buf_get_name(bufnr):match("([^/\\]+)[/\\]*$") or ""
	for _, ignore in ipairs(opts.ignore_filenames) do
		if filename == ignore then
			return false
		end
	end

	return true
end

---@param file_info blameColumn.FileInfo
---@param opts blameColumn.Opts
M.calculate_max_width = function(file_info, opts)
	if not opts.auto_width and opts.max_width > 0 then
		return opts.max_width
	end

	local width = 0

	local enriched_lines = M.get_enriched_lines(file_info, opts.structurizer_fn)
	local formatted_lines = M.get_formatted_lines(enriched_lines)

	for _, f in ipairs(formatted_lines) do
		width = math.max(width, vim.fn.strdisplaywidth(f))
	end

	if opts.max_width ~= -1 then
		return math.min(width, opts.max_width)
	end

	return width
end

---@param file_info blameColumn.FileInfo
---@param structurizer_fn blameColumn.StructurizerFn
---@return blameColumn.EnrichedLine[]
M.get_enriched_lines = function(file_info, structurizer_fn)
	local enriched_lines = {}

	for idx, line_info in ipairs(file_info.lines) do
		local structed_line = structurizer_fn(file_info.general, line_info)
		enriched_lines[#enriched_lines + 1] = {
			idx = idx,
			fields = vim.deepcopy(structed_line.fields),
			format = structed_line.format,
			hl = structed_line.hl,
		}
	end

	return enriched_lines
end

---@param fields blameColumn.LineField[]
---@return string[]
local function collect_text_fields(fields)
	local text_fields = {}
	for _, field in ipairs(fields) do
		table.insert(text_fields, field.text)
	end
	return text_fields
end

---@param enriched_lines blameColumn.EnrichedLine[]
---@return string[]
M.get_formatted_lines = function(enriched_lines)
	local text_lines = {}

	for _, line in ipairs(enriched_lines) do
		table.insert(text_lines, string.format(line.format, unpack(collect_text_fields(line.fields))))
	end

	return text_lines
end

---@param winid integer
---@return integer
M.get_buff_for_win = function(winid)
	if vim.api.nvim_win_is_valid(winid) then
		local buf_id = vim.api.nvim_win_get_buf(winid)
		return buf_id
	else
		return -1
	end
end

---@param file_info blameColumn.FileInfo
---@param colorizer_fn blameColumn.ColorizerFn
M.create_hl_groups = function(file_info, colorizer_fn)
	for _, line_info in ipairs(file_info.lines) do
		if vim.fn.hlID(line_info.hash) == 0 and not line_info.is_modified then
			vim.api.nvim_set_hl(0, line_info.hash, colorizer_fn(file_info.general, line_info))
		end
	end
end

---@param blame_bufnr integer
---@param enriched_lines blameColumn.EnrichedLine[]
M.hl_blame_by_fields = function(blame_bufnr, enriched_lines)
	local lines = vim.api.nvim_buf_get_lines(blame_bufnr, 0, -1, false)

	for _, line in ipairs(enriched_lines) do
		local text_line = lines[line.idx]

		for _, field in ipairs(line.fields) do
			if not field.hl then
				goto continue
			end

			local startindex, endindex = string.find(text_line, field.text, nil, true)
			if startindex == nil or endindex == nil then
				goto continue
			end
			vim.api.nvim_buf_add_highlight(blame_bufnr, 0, field.hl, line.idx - 1, startindex - 1, endindex)
			::continue::
		end
	end
end

---@param blame_bufnr integer
---@param enriched_lines blameColumn.EnrichedLine[]
M.hl_blame_by_lines = function(blame_bufnr, enriched_lines)
	for _, line in ipairs(enriched_lines) do
		vim.api.nvim_buf_add_highlight(blame_bufnr, 0, line.hl, line.idx - 1, 0, -1)
	end
end

return M
