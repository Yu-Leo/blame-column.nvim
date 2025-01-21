local M = {}

local api = vim.api
local fn = vim.fn

---@class blameColumn.LineInfo
---@field public full_hash string
---@field public hash string
---@field public is_modified boolean
---@field public orig_line integer
---@field public final_line integer
---@field public group_lines integer
---@field public line_number integer
---@field public filename string
---@field public summary string
---@field public author string
---@field public author_surname string
---@field public author_time integer
---@field public author_tz string
---@field public author_mail string
---@field public committer string
---@field public committer_surname string
---@field public committer_time integer
---@field public committer_tz string
---@field public committer_mail string
---@field public time_order integer
local LineInfo = {}

---@class blameColumn.GeneralInfo
---@field public total_commits integer
---@field public max_lens table<string, integer>
local GeneralInfo = {}

---@class blameColumn.FileInfo
---@field public lines blameColumn.LineInfo[]
---@field public general blameColumn.GeneralInfo
local FileInfo = {}

local function get_last_word(str)
	local words = {}

	for word in str:gmatch("%S+") do
		table.insert(words, word)
	end

	if #words == 1 then
		return str
	end

	return words[#words]
end

local function get_ordered_times(times_dict)
	local times = {}

	for k, _ in pairs(times_dict) do
		times[#times + 1] = k
	end

	table.sort(times, function(a, b)
		return a < b
	end)

	return times
end

-- parse raw git blame output
---@param raw_blame string[]
---@return blameColumn.FileInfo
local function parse_blame_output(raw_blame)
	local parsed_lines = {}
	local commits_cache = {}
	local line_number = 0
	local total_commits = 0
	local times_dict = {}

	local max_lens = {
		author = 0,
		author_surname = 0,
	}

	local i = 1
	while i <= #raw_blame do
		local line = raw_blame[i]
		if not line then
			break
		end

		if line:match("^%x+") then
			line_number = line_number + 1
			local full_hash, orig_line, final_line, group_lines = line:match("^(%x+)%s+(%d+)%s+(%d+)%s*(%d*)")

			local current_commit
			if commits_cache[full_hash] then
				current_commit = vim.deepcopy(commits_cache[full_hash])
			else
				current_commit = {
					full_hash = full_hash,
					hash = full_hash:sub(1, 7),
					is_modified = full_hash:match("^0+$") ~= nil,

					orig_line = tonumber(orig_line),
					final_line = tonumber(final_line),
					group_lines = tonumber(group_lines) or 1,
				}
				total_commits = total_commits + 1
			end

			current_commit.line_number = line_number

			local add_info = nil
			while i <= #raw_blame do
				i = i + 1
				local info_line = raw_blame[i]
				if info_line:match("^\t") then
					break
				end -- Content line starts

				local key, value = info_line:match("^([%w-]+)%s(.+)")
				if key and value then
					if not add_info then
						add_info = {}
					end
					add_info[key] = value
				end
			end

			if add_info then
				current_commit.filename = add_info.filename
				current_commit.summary = add_info.symmary

				current_commit.author = ""
				current_commit.author_surname = ""
				current_commit.author_mail = ""

				current_commit.committer = ""
				current_commit.committer_surname = ""
				current_commit.committer_mail = ""

				if not current_commit.is_modified then
					current_commit.author = add_info.author
					current_commit.author_surname = get_last_word(current_commit.author)
					current_commit.author_mail = add_info["author-mail"]

					current_commit.committer = add_info.committer
					current_commit.committer_surname = get_last_word(add_info.committer)
					current_commit.committer_mail = add_info["committer-mail"]
				end

				current_commit.author_time = add_info["author-time"] and tonumber(add_info["author-time"])
				current_commit.author_tz = add_info["author-tz"]

				current_commit.committer_time = add_info["committer-time"] and tonumber(add_info["committer-time"])
				current_commit.committer_tz = add_info["committer-tz"]

				max_lens.author = math.max(max_lens.author, vim.fn.strdisplaywidth(current_commit.author))
				max_lens.author_surname =
					math.max(max_lens.author_surname, vim.fn.strdisplaywidth(current_commit.author_surname))
			end
			commits_cache[full_hash] = vim.deepcopy(current_commit)
			if current_commit.author_time then
				times_dict[tonumber(current_commit.author_time)] = current_commit.full_hash
			end

			table.insert(parsed_lines, current_commit)
		end

		i = i + 1
	end

	local times = get_ordered_times(times_dict)

	for k, v in ipairs(times) do
		commits_cache[times_dict[v]].time_order = k - 1
	end

	for j = 1, #parsed_lines do
		parsed_lines[j].time_order = commits_cache[parsed_lines[j].full_hash].time_order
	end

	return {
		general = {
			total_commits = total_commits,
			max_lens = max_lens,
		},
		lines = parsed_lines,
	}
end

---@param bufnr integer
---@param filepath string
local function write_buffer_binary(bufnr, filepath)
	-- Get buffer line count
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local content = table.concat(lines, "\n")
	if vim.bo[bufnr].eol then
		content = content .. "\n"
	end

	-- Write content to file
	local file = io.open(filepath, "wb") -- Open in binary mode
	if file then
		file:write(content)
		file:close()
	else
		vim.notify("Error: Unable to open file for writing: " .. filepath, vim.log.levels.ERROR)
	end
end

---@param bufnr integer
---@param callback function
M.async_get_git_blame = function(bufnr, callback)
	local filepath = api.nvim_buf_get_name(bufnr)
	local tempfile = fn.tempname()
	-- Write buffer contents to temp file
	write_buffer_binary(bufnr, tempfile)

	-- Find git root directory
	local git_root_cmd =
		string.format("git -C %s rev-parse --show-toplevel 2>/dev/null", fn.shellescape(fn.fnamemodify(filepath, ":h")))
	local git_root = fn.trim(fn.system(git_root_cmd))

	if git_root == "" then
		-- Not in a git repository
		callback(nil)
		fn.delete(tempfile)
		return
	end

	-- Get relative path from git root
	local relative_path = fn.fnamemodify(filepath, ":.")
	if fn.isdirectory(git_root) == 1 then
		relative_path = fn.fnamemodify(filepath, ":s?" .. git_root .. "/?")
	end

	-- Prepare git blame command
	local blame_cmd = string.format(
		"git -C %s blame --porcelain %s --contents %s",
		fn.shellescape(git_root),
		fn.shellescape(relative_path),
		fn.shellescape(tempfile)
	)

	-- Run git blame asynchronously
	fn.jobstart(blame_cmd, {
		stdout_buffered = true,
		on_stdout = function(_, data)
			if data then
				local parsed_blame = parse_blame_output(data)
				callback(parsed_blame)
			end
		end,
		on_exit = function()
			-- Clean up temp file
			fn.delete(tempfile)
		end,
	})
end

return M
