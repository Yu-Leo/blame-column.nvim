-- Copied from https://github.com/ziontee113/color-picker.nvim/blob/master/lua/color-picker/utils/init.lua

local M = {}

M.hex_to_rgb = function(hex)
	hex = hex:gsub("#", "")
	return { tonumber("0x" .. hex:sub(1, 2)), tonumber("0x" .. hex:sub(3, 4)), tonumber("0x" .. hex:sub(5, 6)) }
end

M.rgb_to_hex = function(r, g, b)
	return string.format("#%02x%02x%02x", r, g, b)
end

M.round = function(num, numDecimalPlaces)
	return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

M.hsl_to_rgb = function(h, s, l)
	h = h / 360
	s = s / 100
	l = l / 100

	local function to(p, q, t)
		if t < 0 then
			t = t + 1
		end
		if t > 1 then
			t = t - 1
		end
		if t < 0.16667 then
			return p + (q - p) * 6 * t
		end
		if t < 0.5 then
			return q
		end
		if t < 0.66667 then
			return p + (q - p) * (0.66667 - t) * 6
		end
		return p
	end

	local q = l < 0.5 and l * (1 + s) or l + s - l * s
	local p = 2 * l - q

	return { M.round(to(p, q, h + 0.33334) * 255), M.round(to(p, q, h) * 255), M.round(to(p, q, h - 0.33334) * 255) }
end

M.rbg_to_hsl = function(r, g, b)
	-- Make r, g, and b fractions of 1
	r = r / 255
	g = g / 255
	b = b / 255

	local max = math.max(r, g, b)
	local min = math.min(r, g, b)

	local h = (max + min) / 2
	local s = (max + min) / 2
	local l = (max + min) / 2

	if max == min then -- acromatic
		h = 0
		s = 0
	else
		local d = max - min

		if l > 0.5 then
			s = d / (2 - max - min)
		else
			s = d / (max + min)
		end

		local x = nil
		if max == r then
			if g < b then
				x = 6
			else
				x = 0
			end
			h = (g - b) / d + x
		elseif max == g then
			h = (b - r) / d + 2
		elseif max == b then
			h = (r - g) / d + 4
		end

		h = M.round(h / 6 * 360)
	end

	return { h, M.round(s * 100, 0), M.round(l * 100, 0) }
end

M.hsl_to_hex = function(h, s, l)
	local rgb = M.hsl_to_rgb(h, s, l)
	return M.rgb_to_hex(rgb[1], rgb[2], rgb[3])
end

return M
