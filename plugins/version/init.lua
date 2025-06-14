---@type JPXSPlugin
local plugin = ...

plugin.name = "Custom Version"
plugin.author = "Jpsh"
plugin.description = "Allows you to set a custom version number, meaning you need a modded client to connect"

local base = memory.getBaseAddress()

plugin:addEnableHandler(function()
	plugin.core.config:registerConfigValue(
		"customVersionNumber",
		100,
		"number",
		"Custom version number to use for modded clients"
	)

	---@type number
	local customVersion = plugin.core.config:get("customVersionNumber")

	memory.writeUByte(base + 0xd140e, 0x7d) -- Jump if greaterOrEqual
	memory.writeInt(base + 0x2e9f00, customVersion) -- Custom version number
end)

plugin:addDisableHandler(function()
	memory.writeUByte(base + 0xd140e, 0x74) -- Jump zero
	memory.writeInt(base + 0x2e9f00, 71) -- Original version number
end)

return {}
