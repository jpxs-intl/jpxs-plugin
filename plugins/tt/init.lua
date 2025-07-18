---@type JPXSPlugin
local plugin = ...

local function isTuesday()
	local currentTime = os.date("*t")
	return currentTime.wday == 3 -- 3 corresponds to Tuesday in Lua's os.date
end

plugin.name = "Tracerless Tuesday"
plugin.author = "Jpsh"
plugin.description = isTuesday() and "It's Tracerless Tuesday!" or "It's not Tracerless Tuesday."

local isTracerless = isTuesday()
local zeroVector = Vector()

plugin:addHook("ResetGame", function()
	isTracerless = isTuesday()
end)

plugin:addHook("PostEventBullet", function()
	if not isTracerless then
		return
	end
	local event = events[#events - 1]
	event.vectorA:set(zeroVector)
	event.vectorB:set(zeroVector)
end)
