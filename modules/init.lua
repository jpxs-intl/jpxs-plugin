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

---@param Client JPXSClient
---@param Config JPXSConfig
Core:getDependencies({ "client", "config" }, function(Client, Config)
	Config:registerConfigValue("serverListIcon", "<default>", "string", "Icon to display in the server list")
	Config:registerConfigValue(
		"serverListDescription",
		"<default>",
		"string",
		"Description to display in the server list"
	)
	Config:registerConfigValue("serverListUrl", "<default>", "string", "URL to display in the server list")
	Config:registerConfigValue("serverListTags", "<default>", "string", "Tags to display in the server list")

	local mode = getModeInformation()
	---@type {name: string, subRosaId: string}[]
	local bans = {}

	for _, acc in ipairs(accounts.getAll()) do
		if acc.banTime > 0 then
			table.insert(bans, { name = acc.name, subRosaId = acc.subRosaID })
		end
	end

	local function init()
		Client.sendMessage("data", "server:init", {
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
				identifier = Config:get("identifier"),
				serverListIcon = Core.config:get("serverListIcon"),
				serverListDescription = Core.config:get("serverListDescription"),
				serverListUrl = Core.config:get("serverListUrl"),
				serverListTags = Core.config:get("serverListTags"),
			},
		})
	end

	Client.registerEventHandler("auth:success", init)

	init()
end)
