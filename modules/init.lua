---@type Core
local Core = ...

--- Get the current mode information
---@return Plugin | nil
local function getModeInformation()
	for _, plugin in pairs(hook.plugins) do
		if string.lower(plugin.fileName) == string.lower(hook.persistentMode) then
			return plugin
		end
	end

	return nil
end

local function init()
	local mode = getModeInformation()
	---@type {name: string, subRosaId: string}[]
	local bans = {}

	for _, acc in ipairs(accounts.getAll()) do
		if acc.banTime > 0 then
			table.insert(bans, { name = acc.name, subRosaId = acc.subRosaID })
		end
	end

	Core.client.sendMessage("data", "server:init", {
		name = server.name,
		port = server.port,
		type = server.type,
		mode = mode and {
			name = mode.name,
			author = mode.author,
			description = mode.description,
		} or nil,
		bans = bans,
		config = {
			hidden = Core.config:get("hidden"),
			identifier = Core.config:get("identifier"),
			serverListIcon = Core.config:get("serverListIcon"),
			serverListDescription = Core.config:get("serverListDescription"),
			serverListUrl = Core.config:get("serverListUrl"),
			serverListTags = Core.config:get("serverListTags"),
		},
	})
end

Core.addHook("JPXSConfigInit", "init", function()
	Core.config:registerConfigValue("hidden", false, "boolean", "Whether the server is hidden from the server list")
	Core.config:registerConfigValue("serverListIcon", "<default>", "string", "Icon to display in the server list")
	Core.config:registerConfigValue(
		"serverListDescription",
		"<default>",
		"string",
		"Description to display in the server list"
	)
	Core.config:registerConfigValue("serverListUrl", "<default>", "string", "URL to display in the server list")
	Core.config:registerConfigValue("serverListTags", "<default>", "string", "Tags to display in the server list")
end)

Core.addHook("JPXSLoaded", "init", init)
Core.addHook("JPXSConnected", "init", init)
Core.addHook("PostResetGame", "init", init)
Core.addHook("Logic", "init", function()
	if server.ticksSinceReset % 18750 == 0 then
		init()
	end
end)
