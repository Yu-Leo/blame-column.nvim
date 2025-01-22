local api = vim.api

local M = {
	state = {
		commit_info_winid = nil,
		commit_info_bufnr = nil,
	},
}

---@param content table<string>
---@param max_width integer
---@return integer
local function get_window_width(content, max_width)
	local width = 0

	for _, line in ipairs(content) do
		width = math.max(width, vim.fn.strdisplaywidth(line))
	end

	width = width + 1

	if max_width ~= -1 then
		width = math.min(width, max_width)
	end

	return width
end

---@param content table<string>
---@return integer
local function get_window_height(content)
	return #content
end

---@param line_info blameColumn.LineInfo
---@param opts blameColumn.OptsCommitInfo
---@param mappings table<string, string>
M.open = function(line_info, opts, mappings)
	if M.state.commit_info_winid then
		vim.api.nvim_set_current_win(M.state.commit_info_winid)
		return
	end

	local content = opts.formatter_fn(line_info, opts)

	M.state.commit_info_bufnr = vim.api.nvim_create_buf(false, true)

	M.state.commit_info_winid = vim.api.nvim_open_win(M.state.commit_info_bufnr, false, {
		relative = "cursor",
		col = 0,
		row = 1,
		width = get_window_width(content, opts.max_width),
		height = get_window_height(content),
		border = opts.window_opts.border,
	})

	vim.wo[M.state.commit_info_winid].wrap = opts.window_opts.wrap
	vim.wo[M.state.commit_info_winid].number = opts.window_opts.number
	vim.wo[M.state.commit_info_winid].relativenumber = opts.window_opts.relativenumber
	vim.wo[M.state.commit_info_winid].cursorline = opts.window_opts.cursorline
	vim.wo[M.state.commit_info_winid].signcolumn = opts.window_opts.signcolumn
	vim.wo[M.state.commit_info_winid].list = opts.window_opts.list

	vim.wo[M.state.commit_info_winid].scrollbind = false
	vim.wo[M.state.commit_info_winid].cursorbind = false

	vim.api.nvim_buf_set_lines(M.state.commit_info_bufnr, 0, -1, false, content)

	opts.colorizer_fn(M.state.commit_info_bufnr)

	vim.api.nvim_create_autocmd({ "BufHidden", "BufUnload" }, {
		callback = function()
			M.close(true)
		end,
		buffer = M.state.commit_info_bufnr,
		group = vim.api.nvim_create_augroup("BlameColumnAuGroup", { clear = false }),
		desc = "Clean up info window on buf close",
	})

	api.nvim_buf_set_keymap(M.state.commit_info_bufnr, "n", mappings.close_commit_info, "", {
		callback = function()
			M.close(false)
		end,
	})
end

---@param cleanup boolean
M.close = function(cleanup)
	if cleanup == false and M.state.commit_info_winid and vim.api.nvim_win_is_valid(M.state.commit_info_winid) then
		vim.api.nvim_win_close(M.state.commit_info_winid, true)
	end
	M.state.commit_info_winid = nil
	M.state.commit_info_bufnr = nil
end

---@return boolean
M.is_open = function()
	return M.state.commit_info_winid ~= nil
end

return M
