local M = {}

---@param line_info blameColumn.LineInfo
M.diffview = function(line_info)
	vim.cmd("DiffviewOpen " .. line_info.hash .. "^!")
end

return M
