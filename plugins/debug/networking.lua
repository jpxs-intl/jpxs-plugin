---@type JPXSPlugin
local plugin = ...

plugin:addHook("JPXSPing", function(ping)
	plugin:debug("Ping: " .. math.round(ping, 0) .. "ms")
end)
