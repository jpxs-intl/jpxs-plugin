---@type Core
local Core = ...

---@type table<integer, {left: integer, cb: function}>
local timers = {}

---@class Util
local Util = {}

---@param ticks integer
---@param cb fun()
function Util.setTimeout(ticks, cb)
	local id = #timers + 1
	timers[id] = {
		left = ticks,
		cb = cb,
	}
end

--- Parses a short time string into minutes
--- e.g. "1h" -> 60, "30m" -> 30, "1d" -> 1440
--- If no unit is provided, minutes are assumed
--- e.g. "30" -> 30
--- supports s, m, h, d, w, mt, y
--- decimals are supported
--- e.g. "1.5h" -> 90
---@param time string short time string (e.g. "1h", "30m", "1d"), if no unit is provided, minutes are assumed
function Util.parseTime(time)
	local unit = time:sub(-1)
	local value = tonumber(time:sub(1, -2))
	if not value then
		value = tonumber(time)
		unit = "m"
	end

	if unit == "s" then
		return value / 60
	elseif unit == "m" then
		return value
	elseif unit == "h" then
		return value * 60
	elseif unit == "d" then
		return value * 60 * 24
	elseif unit == "w" then
		return value * 60 * 24 * 7
	elseif unit == "mt" then
		return value * 60 * 24 * 30
	elseif unit == "y" then
		return value * 60 * 24 * 365
	end

	return value
end

--- Returns a string representation of a time in minutes
--- e.g. 60 -> "1h", 30 -> "30m", 1440 -> "1d"
--- can also return split time
--- eg 90 -> "1h 30m"
--- supports s, m, h, d, w, mt, y
--- @param time integer time in minutes
--- @return string
function Util.formatTime(time)
	local years = math.floor(time / 60 / 24 / 365)
	time = time - years * 60 * 24 * 365
	local months = math.floor(time / 60 / 24 / 30)
	time = time - months * 60 * 24 * 30
	local weeks = math.floor(time / 60 / 24 / 7)
	time = time - weeks * 60 * 24 * 7
	local days = math.floor(time / 60 / 24)
	time = time - days * 60 * 24
	local hours = math.floor(time / 60)
	time = time - hours * 60
	local minutes = time

	local result = ""
	if years > 0 then
		result = result .. years .. "y "
	end
	if months > 0 then
		result = result .. months .. "mt "
	end
	if weeks > 0 then
		result = result .. weeks .. "w "
	end
	if days > 0 then
		result = result .. days .. "d "
	end
	if hours > 0 then
		result = result .. hours .. "h "
	end
	if minutes > 0 then
		result = result .. minutes .. "m"
	end

	return result
end

Core.addHook("Logic", "util", function()
	local i = 0
	for _, timer in pairs(timers) do
		i = i + 1
		timer.left = timer.left - 1
		if timer.left <= 0 then
			timer.cb()
			table.remove(timers, i)
		end
	end
end)

return Util
