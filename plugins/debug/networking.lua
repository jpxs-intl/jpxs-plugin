---@type JPXSPlugin
local plugin = ...

plugin:addHook("JPXSPing", function(ping)
	plugin:debug("Ping: " .. math.round(ping, 0) .. "ms")
end)

plugin:addHook("JPXSMessageReceived", function(msg)
	plugin:debug("Received message on channel " .. msg.channel .. ": " .. msg.event)
	plugin:debug("Data: \n" .. inspect(msg.data))
end)
