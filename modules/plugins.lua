---@type Core
local Core = ...

---@class JPXSPlugin
---@field enabled boolean
---@field core Core
---@field rsPlugin Plugin
---@field path string
---@field name string
---@field author string?
---@field description string?
---@field color integer
---@field debug fun(self: JPXSPlugin, message: string)
---@field onEnable fun(self: JPXSPlugin)[]
---@field onDisable fun(self: JPXSPlugin)[]
local JPXSPlugin = {}
JPXSPlugin.__index = JPXSPlugin

-- little bit of code stolen from the jdb plugin loader to handle getting logging colors
local acceptableColors = {}
do
	local i = 0
	for color = 17, 230 do
		if color % 6 < 4 then
			i = i + 1
			acceptableColors[i] = color
		end
	end
end

---@param name string
local function nameToColor(name)
	local sum = 0

	for i = 1, #name do
		sum = sum + name:byte(i) * 17
	end

	return acceptableColors[sum % #acceptableColors + 1]
end

-- plugin instance methods

---@param moduleName string
---@param callback fun(module: any)?
function JPXSPlugin:getOrDownloadModule(moduleName, callback)
	Core:getOrDownloadModuleAdv(self.path .. "/" .. moduleName, callback)
end

---@param dependencies string[]
---@param callback fun(...: any)?
function JPXSPlugin:getDependencies(dependencies, callback)
	Core:getDependencies(dependencies, callback, function(_, moduleName, modCallback)
		Core:getOrDownloadModuleAdv(self.path .. "/" .. moduleName, self, modCallback)
	end)
end

---@private
function JPXSPlugin:getPrefix()
	return "\27[38;5;" .. self.color .. "m[" .. self.name .. "]\27[0m "
end

function JPXSPlugin:print(message)
	Core:print(self:getPrefix() .. message)
end

function JPXSPlugin:warn(message)
	Core:print(self:getPrefix() .. "\27[38;5;214m" .. message .. "\27[0m")
end

function JPXSPlugin:error(message)
	Core:print(self:getPrefix() .. "\27[38;5;196m" .. message .. "\27[0m")
end

---@param message string
function JPXSPlugin:debug(message)
	Core:debug(self:getPrefix() .. message)
end

---@param name string
---@param callback fun(...: any)
function JPXSPlugin:addHook(name, callback)
	Core.addHook(name, self.path, function(...)
		if self.enabled then
			return callback(...)
		end
	end)
end

---@param callback fun(self: JPXSPlugin)
function JPXSPlugin:addEnableHandler(callback)
	table.insert(self.onEnable, callback)
end

---@param callback fun(self: JPXSPlugin)
function JPXSPlugin:addDisableHandler(callback)
	table.insert(self.onDisable, callback)
end

-- static plugin library methods

---@class JPXSPluginLib
local JPXSPluginLib = {
	---@type table<string, JPXSPlugin>
	loadedPlugins = {},
}

function JPXSPluginLib.createPlugin(path)
	local instance = setmetatable({}, JPXSPlugin)
	instance.enabled = true
	instance.path = path
	instance.core = Core
	instance.rsPlugin = Core.plugin
	instance.color = nameToColor(path)
	instance.name = path:match("plugins/(.+)") or "Unknown Plugin"
	instance.onEnable = {}
	instance.onDisable = {}

	JPXSPluginLib.loadedPlugins[instance.name] = instance

	return instance
end

---@param plugin string
---@param callback fun(module: any)?
function JPXSPluginLib.loadPlugin(plugin, callback)
	local pluginPath = "plugins/" .. plugin
	local pluginClass = JPXSPluginLib.createPlugin(pluginPath)
	Core:getOrDownloadModuleAdv(pluginPath .. "/init", pluginClass, function()
		if pluginClass.onEnable then
			for _, handler in ipairs(pluginClass.onEnable) do
				handler(pluginClass)
			end
		end
		if callback then
			callback(pluginClass)
		end
	end, true)
end

---@param plugin string
---@param callback? fun(success: boolean, message: string)
function JPXSPluginLib.enablePlugin(plugin, callback)
	if not jpxs.config then
		Core:debug("Config not loaded, cannot enable plugin: " .. plugin)

		if callback then
			callback(false, "Config not loaded")
		end
	end

	local plugins = jpxs.config:get("plugins")
	if not plugins or type(plugins) ~= "table" then
		plugins = {}
	end

	if not table.contains(plugins, plugin) then
		Core:httpGet("/plugins/jpxs/plugins/" .. plugin .. "/init.lua", function(data)
			if data then
				Core:debug("Plugin loaded: " .. plugin)
				JPXSPluginLib.loadPlugin(plugin, function(pluginInstance)
					if pluginInstance.onEnable then
						for _, handler in ipairs(pluginInstance.onEnable) do
							handler(pluginInstance)
						end
					end

					table.insert(plugins, plugin)
					jpxs.config:set("plugins", plugins)

					if callback then
						callback(true, "Plugin enabled")
					end
				end)
			else
				Core:debug("Failed to load plugin: " .. plugin)

				if callback then
					callback(false, "Failed to load plugin")
				end
			end
		end)
	else
		Core:debug("Plugin already enabled: " .. plugin)

		if callback then
			callback(false, "Plugin already enabled")
		end
	end
end

---@param plugin string
---@return boolean success
---@return string message
function JPXSPluginLib.disablePlugin(plugin)
	if not jpxs.config then
		Core:debug("Config not loaded, cannot disable plugin: " .. plugin)
		return false, "Config not loaded"
	end

	local plugins = jpxs.config:get("plugins")
	if not plugins or type(plugins) ~= "table" then
		Core:debug("No plugins to disable")
		return false, "No plugins to disable"
	end

	for i, p in ipairs(plugins) do
		if p == plugin then
			table.remove(plugins, i)
			jpxs.config:set("plugins", plugins)
			Core:debug("Plugin disabled: " .. plugin)

			local pluginInstance = JPXSPluginLib.loadedPlugins[plugin]

			-- Call onDisable handlers if they exist
			if pluginInstance and pluginInstance.onDisable then
				for _, handler in ipairs(pluginInstance.onDisable) do
					handler(pluginInstance)
				end
			end

			if pluginInstance then
				JPXSPluginLib.loadedPlugins[plugin].enabled = false
			end

			return true, "Plugin disabled"
		end
	end

	Core:debug("Plugin not found: " .. plugin)
	return false, "Plugin not found"
end

-- handle loading config and plugins on load

---@param Config JPXSConfig
Core:getDependencies({ "config" }, function(Config)
	Config:registerConfigValue("plugins", Core.defaultPlugins, "table", "List of plugins to load", true)
end)

Core.addHook("JPXSConfigLoaded", "plugins", function()
	Core:debug("Loading plugins")

	local plugins = Core.config:get("plugins")
	if not plugins or type(plugins) ~= "table" then
		Core:debug("No plugins to load")
		return
	end

	for _, plugin in ipairs(plugins) do
		if type(plugin) == "string" then
			Core:debug("Loading plugin: " .. plugin)
			JPXSPluginLib.loadPlugin(plugin)
		else
			Core:debug("Invalid plugin format for: " .. tostring(plugin))
		end
	end
end)

local pluginCommands = {
	["enable"] = function(pluginName)
		if not pluginName then
			print("Usage: jpxs plugin enable <plugin>")
			return
		end

		Core.plugins.enablePlugin(pluginName, function(success, message)
			if success then
				print(string.format("\x1b[32;1mPlugin %s enabled successfully.\x1b[0m", pluginName))
			else
				print(string.format("\x1b[31;1mFailed to enable plugin %s: %s\x1b[0m", pluginName, message))
			end
		end)
	end,
	["disable"] = function(pluginName)
		if not pluginName then
			print("Usage: jpxs plugin disable <plugin>")
			return
		end

		local success, message = Core.plugins.disablePlugin(pluginName)

		if success then
			print(string.format("\x1b[32;1mPlugin %s disabled successfully.\x1b[0m", pluginName))
		else
			print(string.format("\x1b[31;1mFailed to disable plugin %s: %s\x1b[0m", pluginName, message))
		end
	end,
	["list"] = function()
		local plugins = Core.plugins.loadedPlugins
		if not plugins or table.dictLength(plugins) == 0 then
			print("No plugins loaded.")
			return
		end

		print("\x1b[32;1mLoaded plugins:\x1b[0m")
		for name, plugin in pairs(plugins) do
			if plugin.enabled then
				print(
					string.format(
						"\x1b[36;1m%s\x1b[0m by \x1b[32;1m%s\x1b[0m - %s",
						name,
						plugin.author or "Unknown",
						plugin.description or "No description"
					)
				)
			end
		end
		print(string.format("\x1b[32;1mTotal: %d\x1b[0m", table.dictLength(plugins)))
	end,
	["reload"] = function(pluginName)
		if not pluginName then
			-- reload all plugins
			for name in pairs(Core.plugins.loadedPlugins) do
				Core.plugins.loadPlugin(name, function(module)
					print(string.format("\x1b[32;1mPlugin %s reloaded successfully.\x1b[0m", module.name))
				end)
			end

			return
		end

		local success, message = Core.plugins.loadPlugin(pluginName)

		if success then
			print(string.format("\x1b[32;1mPlugin %s reloaded successfully.\x1b[0m", pluginName))
		else
			print(string.format("\x1b[31;1mFailed to reload plugin %s: %s\x1b[0m", pluginName, message))
		end
	end,
}

Core.commands["plugin"] = {
	info = "Manage plugins",
	usage = "jpxs plugin <command> [args]",
	autoComplete = function(args)
		if #args == 2 then
			args[2] = filterTableStartsWith(args[2], table.keys(Core.plugin.commands))
		end
	end,
	call = function(args)
		local commandName = args[2]
		if not commandName then
			print("Usage: jpxs plugin <command> [args]")
			return
		end

		local command = pluginCommands[commandName]
		if command then
			command(table.unpack(args, 3))
		else
			print("Unknown plugin command: " .. commandName)
			print("Available commands: enable, disable, list")
		end
	end,
}

return {
	export = JPXSPluginLib,
}
