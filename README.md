# blame-column.nvim

Neovim plugin for displaying [git blame](https://git-scm.com/docs/git-blame) information.

TODO: image 1, image 2

## ✨ Features

- ⚡ Real-time updates of blame information as you edit 
- 📜 Synchronized scrolling of the source buffer and the blame buffer
- 📐 Configurable window options
- 🎨 Highly customizable line format and coloring
- 🔥 Built-in line coloring based on the commit age. As in the JB IDEs

## 📦 Installation

Install the plugin with your preferred package manager:

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
	"Yu-Leo/blame-column.nvim",
	opts = {}, -- for default options. Refer to the configuration section for custom setup.
	cmd = "BlameColumnToggle",
}
```

## ⚙️ Configuration

### Setup

<details><summary>Default Settings</summary>

<!-- config:start -->

```lua
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
```

<!-- config:end -->

</details>

#### Structurizer func

Defines the string structure. What fields will the string consist of, in what format will they be output, with which hl groups

```lua
---@class blameColumn.StructurizerFn
---@param general_info blameColumn.GeneralInfo
---@param line_info blameColumn.LineInfo
---@return blameColumn.StructedLine
local function structurizer_func(general_info, line_info)
	-- Your code
end
```

<details><summary>Types</summary>

<!-- types:start -->

```lua
---@class blameColumn.GeneralInfo
---@field public total_commits integer
---@field public max_lens table<string, integer>
local GeneralInfo = {}

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

---@class blameColumn.StructedLine
---@field public format string
---@field public fields blameColumn.LineField[]
---@field public hl? string
local StructedLine = {}
```

<!-- types:end -->

</details>


**Built-in**:

- [`require("blame-column.structurizers").colorized_date_author`](TODO: link)

#### Colorizer func

Defines a hl group of the form `a1b2c3d`, where `a1b2c3d` is the hash of the commit.

```lua
---@class blameColumn.ColorizerFn
---@param general_info blameColumn.GeneralInfo
---@param line_info blameColumn.LineInfo
---@return vim.api.keyset.highlight
local function colorizer_func(general_info, line_info)
	-- Your code
end
```

<details><summary>Types</summary>

<!-- types:start -->

```lua
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
```

<!-- types:end -->

</details>


**Built-in**:

- [`require("blame-column.colorizers").random_fg`](TODO: link)
- [`require("blame-column.colorizers").time_based_bg`](TODO: link)

## 🚀 Usage

### Commands

- `:BlameColumnToggle` - toggle git-blame window

### API

```lua
-- Toggle git-blame window
require("Yu-Leo/blame-column.nvim").toggle()
```

### Example

```lua
vim.keymap.set("n", "<leader>gl", function()
  require("blame-column").toggle()
end, { desc = "Git: toggle blame" })
```

See [my neovim configuration](https://github.com/Yu-Leo/nvim).

## 🤝 Contributing

PRs and Issues are always welcome.

Author: [@Yu-Leo](https://github.com/Yu-Leo)

## 🫶 Alternatives and sources of inspiration

### Git blame in JB IDEs

I really like how gif blame is displayed in JB IDEs.

Key features that I tried to replicate in this plugin:

- Display in the column to the left of the source buffer.
- The background color of the commit depends on the age of the commit. The older the commit, the darker the background.
- Displaying only the author's last name if the "commit author" field consists of two words
- Displays relative dates. "Today" and "Yesterday"

### [psjay/blamer.nvim](https://github.com/psjay/blamer.nvim)

It's a good plugin, but it's not functional enough for me. It was taken as the basis of my plugin. I express my gratitude to [@psjay](https://github.com/psjay)

**Key features:**
- Real-time updates of blame information as you edit
- Synchronized scrolling of the source buffer and the blame buffer

**Features that I was missing:**
- More customizable blame window options:
    - The ability to display a window to the left of the source buffer
    - Automatic calculation of the window width depending on the content
- More options for customizing the string format and coloring
- Line coloring based on the commit age

### [FabijanZulj/blame.nvim](https://github.com/FabijanZulj/blame.nvim)

It's a really functional plugin, but it doesn't fully satisfy my needs. Served as a source of inspiration for expanding the capabilities of my plugin. I express my gratitude to [@FabijanZulj](https://github.com/FabijanZulj) and all the contributors.

**Key features:**
- Highly customizable line format and coloring
- Displaying commit information in a pop-up window
- Displaying full commit information in a separate window
- Blame stack. You can see the status of the file before the selected commit

**Features that I was missing:**
- Real-time updates of blame information as you edit
- Synchronized scrolling of the source buffer and the blame buffer
- Line coloring based on the commit age
