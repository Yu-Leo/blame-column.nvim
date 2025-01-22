local utils = require("blame-column.utils")
local git = require("blame-column.git")
local config = require("blame-column.config")
local ci_window = require("blame-column.commit_info_window")

local api = vim.api

local M = {
	state = {
		source_bufnr = nil,
		source_winid = nil,
		source_buf_autocmd = nil,

		blame_bufnr = nil,
		blame_winid = nil,

		augroup = nil,

		file_info = nil,
	},
}

M.toggle = function()
	if M.state.blame_winid and api.nvim_win_is_valid(M.state.blame_winid) then
		M.close()
		return
	end

	if utils.is_blame_availible(config.opts) then
		git.async_get_git_blame(api.nvim_get_current_buf(), function(file_info)
			M.open(file_info)
		end)
	end
end

M.close = function()
	api.nvim_win_close(M.state.blame_winid, true)
	M.state.blame_winid = nil
	vim.wo[M.state.source_winid].scrollbind = false
	vim.wo[M.state.source_winid].cursorbind = false

	ci_window.close(false)
end

---@param file_info blameColumn.FileInfo
M.open = function(file_info)
	M.state.source_bufnr = api.nvim_get_current_buf()
	M.state.source_winid = api.nvim_get_current_win()

	M.setup_blame_window(file_info)

	vim.api.nvim_set_current_win(M.state.source_winid)

	-- Set up autocommands to disable scrollbind and clean up
	M.state.augroup = api.nvim_create_augroup("BlameColumnAuGroup", { clear = true })
	M.create_autocmds()

	M.create_keymaps()

	M.update_blame_buf(file_info)
	M.sync_bind()
	M.state.source_buf_autocmd = M.create_text_changed_autocmd()
end

---@param file_info blameColumn.FileInfo
M.setup_blame_window = function(file_info)
	M.state.blame_bufnr = api.nvim_create_buf(false, true)

	vim.bo[M.state.blame_bufnr].buftype = "nofile"
	vim.bo[M.state.blame_bufnr].bufhidden = "wipe"
	vim.bo[M.state.blame_bufnr].filetype = "blame"
	api.nvim_buf_set_name(M.state.blame_bufnr, "blame")

	-- Open a new window and set its buffer
	api.nvim_command(utils.get_open_split_cmd(config.opts.side))
	M.state.blame_winid = api.nvim_get_current_win()

	api.nvim_win_set_buf(M.state.blame_winid, M.state.blame_bufnr)

	vim.wo[M.state.blame_winid].wrap = config.opts.window_opts.wrap
	vim.wo[M.state.blame_winid].number = config.opts.window_opts.number
	vim.wo[M.state.blame_winid].relativenumber = config.opts.window_opts.relativenumber
	vim.wo[M.state.blame_winid].cursorline = config.opts.window_opts.cursorline
	vim.wo[M.state.blame_winid].signcolumn = config.opts.window_opts.signcolumn
	vim.wo[M.state.blame_winid].list = config.opts.window_opts.list

	local width = utils.calculate_max_width(file_info, config.opts)
	api.nvim_win_set_width(M.state.blame_winid, width)
end

M.create_autocmds = function()
	local bufenter_autocmd_id = api.nvim_create_autocmd({ "BufEnter" }, {
		group = M.state.augroup,
		pattern = "*",
		nested = true,
		callback = function()
			if utils.get_buff_for_win(M.state.source_winid) ~= api.nvim_get_current_buf() then
				return
			end
			if utils.get_buff_for_win(M.state.source_winid) == M.state.source_bufnr then
				return
			end

			if not utils.is_blame_availible(config.opts) then
				M.close()
				return
			end

			if M.state.source_buf_autocmd then
				pcall(api.nvim_del_autocmd, M.state.source_buf_autocmd)
			end

			-- Set up autocommand for buffer changes
			M.state.source_bufnr = api.nvim_get_current_buf()
			if M.state.source_bufnr then
				M.setup_for_source_bufnr()
			end
		end,
	})

	api.nvim_create_autocmd({ "WinClosed" }, {
		group = M.augroup,
		pattern = tostring(M.state.blame_winid),
		callback = function()
			api.nvim_del_autocmd(bufenter_autocmd_id)
			api.nvim_del_autocmd(M.state.source_buf_autocmd)
			M.state.blame_winid = nil
			if ci_window.is_open() then
				ci_window.close(false)
			end
		end,
	})

	api.nvim_create_autocmd({ "WinEnter" }, {
		group = M.augroup,
		buffer = M.state.source_bufnr,
		callback = function()
			if ci_window.is_open() then
				ci_window.close(false)
			end
		end,
	})

	api.nvim_create_autocmd({ "CursorMoved", "WinScrolled" }, {
		buffer = M.state.blame_bufnr,
		callback = function()
			if ci_window.is_open() then
				ci_window.close(false)
				if config.opts.commit_info.follow_cursor then
					M.open_commit_info()
				end
			end
		end,
	})
end

M.create_keymaps = function()
	api.nvim_buf_set_keymap(M.state.blame_bufnr, "n", config.opts.mappings.close_commit_info_from_blame, "", {
		callback = function()
			if ci_window.is_open() then
				ci_window.close(false)
				return
			end
			api.nvim_win_close(M.state.blame_winid, true)
		end,
		noremap = true,
		silent = true,
	})

	if config.opts.commit_info.enabled_from_blame then
		api.nvim_buf_set_keymap(M.state.blame_bufnr, "n", config.opts.mappings.open_commit_info_from_blame, "", {
			callback = function()
				M.open_commit_info()
			end,
			noremap = true,
			silent = true,
		})
	end

	if config.opts.full_commit_info.enabled_from_blame then
		api.nvim_buf_set_keymap(M.state.blame_bufnr, "n", config.opts.mappings.open_full_commit_info_from_blame, "", {
			callback = function()
				M.open_full_commit_info()
			end,
			noremap = true,
			silent = true,
		})
	end
end

M.open_commit_info = function()
	local row, _ = unpack(vim.api.nvim_win_get_cursor(M.state.blame_winid))
	local line_info = M.state.file_info.lines[row]

	if line_info.is_modified then
		return
	end

	ci_window.open(line_info, config.opts.commit_info, config.opts.mappings)
end

M.open_full_commit_info = function()
	local row, _ = unpack(vim.api.nvim_win_get_cursor(M.state.blame_winid))
	local line_info = M.state.file_info.lines[row]

	if line_info.is_modified then
		return
	end

	config.opts.full_commit_info.opener_fn(line_info)
end

M.create_text_changed_autocmd = function()
	return api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		group = M.state.augroup,
		buffer = M.state.source_bufnr,
		callback = function()
			git.async_get_git_blame(M.state.source_bufnr, function(file_info_local)
				M.update_blame_buf(file_info_local)
			end)
		end,
	})
end

M.sync_bind = function()
	vim.wo[M.state.blame_winid].scrollbind = true
	vim.wo[M.state.blame_winid].cursorbind = true
	vim.wo[M.state.source_winid].scrollbind = true
	vim.wo[M.state.source_winid].cursorbind = true
	api.nvim_command("syncbind")
end

---@param file_info blameColumn.FileInfo
M.update_blame_buf = function(file_info)
	M.state.file_info = file_info

	if not api.nvim_buf_is_valid(M.state.blame_bufnr) then
		return
	end

	local enriched_lines = utils.get_enriched_lines(file_info, config.opts.structurizer_fn)
	local formatted_lines = utils.get_formatted_lines(enriched_lines)

	utils.create_hl_groups(file_info, config.opts.colorizer_fn)

	vim.bo[M.state.blame_bufnr].modifiable = true
	api.nvim_buf_set_lines(M.state.blame_bufnr, 0, -1, false, formatted_lines)
	vim.bo[M.state.blame_bufnr].modifiable = false

	if config.opts.hl_by_fields then
		utils.hl_blame_by_fields(M.state.blame_bufnr, enriched_lines)
	else
		utils.hl_blame_by_lines(M.state.blame_bufnr, enriched_lines)
	end
end

M.setup_for_source_bufnr = function()
	git.async_get_git_blame(M.state.source_bufnr, function(file_info)
		M.update_blame_buf(file_info)
		M.sync_bind()

		if config.opts.dynamic_width then
			local width = utils.calculate_max_width(file_info, config.opts)
			api.nvim_win_set_width(M.state.blame_winid, width)
		end
	end)

	M.state.source_buf_autocmd = M.create_text_changed_autocmd()
end

return M
