--[[loader.lua]]
---@class Core
--- exports
---@field config JPXSConfig
---@field transfer JPXSTransfer
---
local Core = {}
Core.debugEnabled = false

Core.KEEP_OUT_MESSAGE = [[
-- ##############################################################
-- This file is part of JPXS
-- 
-- if you're seeing this, and you're looking to tinker with it,
-- please don't, it's literally months of work here and
-- I don't want it fucking with something on the server
-- thanks, gart
-- ##############################################################
]]

Core.credits = [[
gart            -  main dev, gateway
jpsh            -  exe mod and customVersion module, testing
checkraisefold  -  TCPClient rs module, TCPClient demo 
]]

---@type Plugin
Core.plugin = ...
Core.plugin.name = "jpxs"
Core.plugin.author = "gart + more (/jpxs credits)"
Core.plugin.description = "v 2.7 BETA | analytics, logging, moderation, tooling"

---@type {[string]: any}
Core.moduleCache = {}
Core.hasLoadedModules = false

---@type JPXSClient
Core.client = nil

---@type JPXSDevTools
Core.devTools = nil

Core.assetHost = {
	host = "https://assets.jpxs.io",
	path = "/plugins/jpxs/",
}

Core.bin = {
	host = "https://bin.gart.sh",
}

Core.storagePath = ".jpxs/"

---@type {string: JPXSCommand}
Core.commands = {}

---@type {[integer]: boolean}
Core.awaitingPlayers = {}

---@type {[string]: any}
Core.overrides = {}

--- modules to request
local modules = {
	"init",
	"players",
	"instructions",
	"log",
	"performance",
	"typeLoader",
	"readme",
	"commands",
	"banSync",
	"customVersion",
	"devTools",
	"transfer",
}

---@class JPXSPlugin
---@field id string
---@field name string
---@field author string
---@field description string
---@field path string
Core.JPXSPlugin = {}
Core.JPXSPlugin.__index = Core.JPXSPlugin

---@private
Core.JPXSPlugin.__call = function(self, id, path)
	local plugin = {
		id = id,
		name = self.name or "Unknown",
		author = self.author or "Unknown",
		description = self.description or "No description",
		path = path,
		core = Core,
	}

	setmetatable(plugin, Core.JPXSPlugin)

	return plugin
end

---@param self JPXSPlugin
---@param id string
---@param cb fun(name: string, module: any)?
function Core.JPXSPlugin:loadSubModule(id, cb)
	local path = self.path .. id .. ".lua"
	local fileId = "plugin." .. self.id .. "." .. id

	if Core.moduleCache[fileId] then
		return Core.moduleCache[fileId]
	end

	http.get(Core.assetHost.host, path, {}, function(response)
		if response and response.status == 200 then
			Core:loadModule(fileId, response.body, cb)
		else
			Core:print(
				string.format(
					"Failed to download plugin %s (%s)",
					fileId,
					response and response.status or "no response"
				)
			)
		end
	end)
end

---@param self JPXSPlugin
---@param ids string[]
---@param cb fun(name: string, module: any)?
function Core.JPXSPlugin:loadSubModules(ids, cb)
	local neededToLoad = {}
	for _, id in pairs(ids) do
		neededToLoad[id] = true
	end

	local function onLoad(id)
		neededToLoad[id] = nil

		if #table.keys(neededToLoad) == 0 then
			local deps = {}
			for _, moduleId in pairs(ids) do
				table.insert(deps, Core.moduleCache[moduleId])
			end

			if cb then
				cb(table.unpack(deps))
			end
		end
	end

	for id, _ in pairs(neededToLoad) do
		self:loadSubModule(id, onLoad)
	end
end

---@param text string print logs
function Core:print(text)
	print("\27[30;1m[" .. os.date("%X") .. "]\27[0m \27[38;5;202m[JPXS]\27[0m " .. text)
end

---@param text string print logs
function Core:debug(text)
	if Core.debugEnabled or (Core.config and Core.config.values and Core.config.values.debug == true) then
		print("\27[30;1m[" .. os.date("%X") .. "]\27[0m \27[38;5;202m[DEBUG][JPXS]\27[0m " .. text)
	end
end

---@param content string
---@param fileName string
---@return string
function Core.addFileHeader(content, fileName)
	return "--[[ " .. fileName .. ".lua ]]" .. (" "):rep(32) .. content
end

---@private
---@param id string
---@param body string
---@param cb fun(name: string, module: any)?
function Core:loadModule(id, body, cb)
	local file = Core.addFileHeader(body, id)

	local result, err = loadstring(file)

	if not result then
		Core:print(string.format("Failed to load module %s: %s", id, err))
		return
	end

	Core.moduleCache[id] = result(Core)
	Core:debug(string.format("Loaded module %s", id))

	-- allows direct access to the module via JPXS.<module>
	if Core.moduleCache[id] and Core.moduleCache[id].export and not Core[id] then
		Core[id] = Core.moduleCache[id].export
	end

	if cb then
		cb(id, Core.moduleCache[id])
	end
end

---@param id string
---@param cb fun(name: string, module: any)?
---@param showError? boolean
function Core:downloadModule(id, cb, showError)
	http.get(Core.assetHost.host, Core.assetHost.path .. "modules/" .. id .. ".lua", {}, function(response)
		if response and response.status == 200 then
			Core:loadModule(id, response.body, cb)
		else
			(showError and Core.print or Core.debug)(
				Core,
				string.format("Failed to download module %s (%s)", id, response and response.status or "no response")
			)
		end
	end)
end

---@param id string
---@param cb fun(name: string, module: any)?
---@param showError? boolean
function Core:downloadPlugin(id, cb, showError)
	http.get(Core.assetHost.host, Core.assetHost.path .. "plugins/" .. id .. "/init.lua", {}, function(response)
		if response and response.status == 200 then
			local plugin = Core.JPXSPlugin(id, Core.assetHost.path .. "plugins/" .. id .. "/")
		end
	end)
end

---@param id string
---@param cb fun(name: string, module: any)?
---@param showError? boolean
function Core:loadGartbin(id, cb, showError)
	http.get(Core.bin.host, "/" .. id .. "/raw", {}, function(response)
		if response and response.status == 200 then
			Core:loadModule(id, response.body, cb)
		else
			(showError and Core.print or Core.debug)(
				Core,
				string.format("Failed to download bin %s (%s)", id, response and response.status or "no response")
			)
		end
	end)
end

---@param id string
---@param cb fun(name: string, module: any)?
function Core:getOrDownloadModule(id, cb)
	if Core.moduleCache[id] then
		if cb then
			cb(id, Core.moduleCache[id])
		end
	else
		Core:downloadModule(id, cb)
	end
end

---@param id string
---@return any
function Core:getModule(id)
	return Core.moduleCache[id]
end

---@param modules string[]
---@param cb fun(...: any[])?
function Core:getDependencies(modules, cb)
	local neededToLoad = {}
	for _, id in pairs(modules) do
		neededToLoad[id] = true
	end

	local function onLoad(id)
		neededToLoad[id] = nil

		if #table.keys(neededToLoad) == 0 then
			local deps = {}
			for _, moduleId in pairs(modules) do
				table.insert(deps, Core.moduleCache[moduleId])
			end

			if cb then
				cb(table.unpack(deps))
			end
		end
	end

	for id, _ in pairs(neededToLoad) do
		Core:getOrDownloadModule(id, onLoad)
	end
end

function Core:load()
	if _G["JPXS_🍆"] then
		Core:print("Modules are already loading! Please wait.")
		return
	end

	_G["JPXS_🍆"] = true

	local function postLoad()
		Core:getOrDownloadModule("client", function(_, Client)
			Client.connect()
			Client.onConnect = function()
				if not Core.hasLoadedModules then
					Core:getDependencies(modules, function()
						Core.hasLoadedModules = true
						_G["JPXS_🍆"] = nil

						Core:print("Loaded!")
						hook.run("JPXSLoaded")
					end)
				end
			end
		end)
	end

	-- check for polyfill (minimum version 2)
	if _G.polyfill and _G.polyfill.version >= 2 then
		postLoad()
	else
		http.get(Core.assetHost.host, "/plugins/lib/polyfill.lua", {}, function(response)
			if response and response.status == 200 then
				loadstring(response.body)()
				Core:debug("Polyfill loaded")

				postLoad()
			else
				Core:print("Failed to download polyfill")
			end
		end)
	end
end

--- Config values
---@param Config JPXSConfig
hook.add("JPXSConfigInit", "jpxs.configLoader", function(Config)
	Core:debug("Registering config values")

	Config:registerConfigValue("debug", false, "boolean", "Enable debug mode")
	Config:registerConfigValue("updateInterval", 60 * 15, "integer", "Data update interval, in ticks")
	Config:registerConfigValue("connectionMethod", "http", "string", "Connection method (http, tcp)")
end)

Core:load()

_G.JPXS = Core
_G.jpxs = Core

return Core
