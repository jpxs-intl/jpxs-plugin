--[[loader.lua]]
---@class Core
--- exports
---@field client JPXSClient
---@field config JPXSConfig
---@field plugins JPXSPluginLib
---@field transfer JPXSTransfer
---@field devTools JPXSDevTools
---@field patchset JPXSPatchSetLib
local Core = {}

Core.KEEP_OUT_MESSAGE = [[
-- ##############################################################
-- This file is part of JPXS
-- 
-- if you're seeing this, and you're looking to tinker with it,
-- please don't, it's literally months of work here and
-- I don't want it fucking with something on the server
-- thanks, max
-- ##############################################################
]]

Core.credits = [[
max             -  main dev, gateway
jpsh            -  lots of help, testing
checkraisefold  -  TCPClient rs module, TCPClient demo 
]]

---@type Plugin
Core.plugin = ...
Core.plugin.name = "jpxs"
Core.plugin.author = "max + more (/jpxs credits)"
Core.plugin.description = "v 2.8 BETA | analytics, logging, moderation, tooling"

Core.overrides = Core.overrides or {}

---@type {[string]: any}
Core.moduleCache = {}
Core.hasLoadedModules = false

Core.debugEnabled = Core.overrides.debugEnabled or false

Core.assetHost = Core.overrides.assetHost or {
	host = "https://assets.jpxs.io",
	path = "/plugins/jpxs/",
}

Core.bin = Core.overrides.bin or {
	host = "https://bin.gart.sh",
}

Core.storagePath = Core.overrides.storagePath or ".jpxs/"

---@type {string: JPXSCommand}
Core.commands = {}

---@type {[integer]: boolean}
Core.awaitingPlayers = {}

---@type {[string]: any}

--- modules to request
local modules = Core.overrides.modules
	or {
		"init",
		"players",
		"instructions",
		"log",
		"performance",
		"typeLoader",
		"readme",
		"commands",
		"devTools",
		"api",
		"patchset",
		"plugins",
	}

---Default plugins to load
Core.defaultPlugins = Core.overrides.defaultPlugins or {
	"autoupdater",
	"gmsg",
	"tt",
}

-- globals

---@type {[string]: {name: string, hookName: string}}
_G.jpxs_registeredHooks = _G.jpxs_registeredHooks or {}
---@type true | nil
_G.jpxs_modulesLoading = _G.jpxs_modulesLoading or nil

---@param text string print logs
function Core:print(text)
	print("\27[30;1m[" .. os.date("%X") .. "]\27[0m \27[38;5;202m[JPXS]\27[0m " .. text)
end

---@param text string print errors
function Core:error(text)
	print("\27[30;1m[" .. os.date("%X") .. "]\27[0m \27[38;5;196m[ERROR][JPXS]\27[0m " .. text)
end

---@param text string print logs
function Core:debug(text)
	if Core.debugEnabled then
		print("\27[30;1m[" .. os.date("%X") .. "]\27[0m \27[38;5;202m[DEBUG][JPXS]\27[0m " .. text)
	end
end

---@param content string
---@param fileName string
---@return string
function Core.addFileHeader(content, fileName)
	return "--[[ " .. fileName .. ".lua ]]" .. (" "):rep(32) .. content
end

---@param moduleName string
---@param hookName string
---@param callback fun(...: any)
function Core.addHook(hookName, moduleName, callback)
	local name = "jpxs | " .. moduleName
	table.insert(_G.jpxs_registeredHooks, {
		name = name,
		hookName = hookName,
	})

	hook.add(hookName, name, callback)

	Core:debug(string.format("\27[30;1m%s -> %s\27[0m", moduleName, hookName))
end

function Core.removeHooks()
	if not _G.jpxs_registeredHooks then
		return
	end

	Core:debug(string.format("Removing %s registered hooks...", table.dictLength(_G.jpxs_registeredHooks)))

	-- since jdb is a fucking idiot i cant loop through hooks (its a local table)
	-- there are so many issues with the stupid hook system
	-- this is so fucking stupid
	-- ts pmo

	for _, jpxsHook in pairs(_G.jpxs_registeredHooks) do
		hook.remove(jpxsHook.hookName, jpxsHook.name)
	end

	_G.jpxs_registeredHooks = {}
end

---@private
---@param id string
---@param body string
---@param pass any?
---@param cb fun(name: string, module: any)?
function Core:loadModule(id, body, pass, cb)
	local file = Core.addFileHeader(body, id)

	local result, err = loadstring(file)

	if not result then
		Core:print(string.format("Failed to load module %s: %s", id, err))
		return
	end

	Core.moduleCache[id] = result(pass or Core)
	Core:debug(string.format("Loaded module %s", id))

	-- allows direct access to the module via JPXS.<module>
	if Core.moduleCache[id] and Core.moduleCache[id].export then
		local exportName = Core.moduleCache[id].exportName or id
		Core:debug(string.format("Exporting module %s to Core (%s)", exportName, id))
		Core[exportName] = Core.moduleCache[id].export
	end

	if cb then
		cb(Core.moduleCache[id])
	end
end

---@param path string
---@param cb fun(response: string | nil, error?: string)
function Core:httpGet(path, cb)
	http.get(Core.assetHost.host, path, {}, function(response)
		if Core.debugEnabled then
			Core:debug(
				string.format(
					"\27[30;1mGET %s%s -> %s\27[0m",
					Core.assetHost.host,
					path,
					response and response.status or "no response"
				)
			)
		end
		if response and response.status == 200 then
			cb(response.body)
		else
			cb(
				nil,
				string.format(
					"Failed to get %s%s (%s)",
					Core.assetHost,
					path,
					response and response.status or "no response"
				)
			)
		end
	end)
end

---@param id string
---@param cb fun(name: string, module: any)?
---@param showError? boolean
function Core:downloadModule(id, cb, showError)
	Core:httpGet(Core.assetHost.path .. "modules/" .. id .. ".lua", function(response)
		if response then
			Core:loadModule(id, response, Core, cb)
		else
			(showError and Core.error or Core.debug)(
				Core,
				string.format("Failed to download module %s (%s)", id, response and response.status or "no response")
			)
		end
	end)
end

---@param path string
---@param pass any?
---@param cb fun(name: string, module: any)?
---@param showError? boolean
function Core:downloadModuleAdv(path, pass, cb, showError)
	local id = path:gsub("/", "."):gsub("%.lua$", "")
	Core:httpGet(Core.assetHost.path .. path .. ".lua", function(response)
		if response then
			Core:loadModule(id, response, pass or Core, cb)
		else
			(showError and Core.error or Core.debug)(
				Core,
				string.format("Failed to download module %s (%s)", id, response and response.status or "no response")
			)
		end
	end)
end

---@param id string
---@param cb fun(name: string, module: any)?
---@param showError? boolean
function Core:loadGartbin(id, cb, showError)
	local path = Core.bin.host .. "/" .. id .. "/raw"
	http.get(Core.bin.host, path, {}, function(response)
		if Core.debugEnabled then
			Core:debug(
				string.format(
					"GET %s%s -> %s",
					Core.assetHost.host,
					path,
					response and response.status or "no response"
				)
			)
		end
		if response and response.status == 200 then
			Core:loadModule(id, response.body, Core, cb)
		else
			(showError and Core.error or Core.debug)(
				Core,
				string.format("Failed to download bin %s (%s)", id, response and response.status or "no response")
			)
		end
	end)
end

---@param id string
---@param cb fun(module: any)?
function Core:getOrDownloadModule(id, cb)
	if Core.moduleCache[id] then
		if cb then
			cb(Core.moduleCache[id])
		end
	else
		Core:downloadModule(id, cb)
	end
end

---@param path string
---@param pass any?
---@param cb fun(module: any)?
---@param showError? boolean
function Core:getOrDownloadModuleAdv(path, pass, cb, showError)
	local id = path:gsub("/", "."):gsub("%.lua$", "")
	if Core.moduleCache[id] then
		if cb then
			cb(Core.moduleCache[id])
		end
	else
		Core:downloadModuleAdv(path, pass, cb, showError)
	end
end

---@param id string
---@return any
function Core:getModule(id)
	return Core.moduleCache[id]
end

---@param modules string[]
---@param cb fun(...: any[])?
---@param loadMethod? fun(Core: Core, id: string, callback: fun(module: any)?)
function Core:getDependencies(modules, cb, loadMethod)
	loadMethod = loadMethod or Core.getOrDownloadModule
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
		loadMethod(Core, id, function(module)
			onLoad(id)
		end)
	end
end

function Core:load()
	if _G.jpxs_modulesLoading then
		Core:print("Modules are already loading! Please wait.")
		return
	end

	_G.jpxs_modulesLoading = true

	-- check for existing debug.lock file
	local debugLockFile = Core.storagePath .. "debug.lock"
	if io.open(debugLockFile, "r") then
		Core.debugEnabled = true
		Core:debug("Debugging is enabled (debug.lock file found)")
	end

	local function postLoad()
		Core.removeHooks() -- remove hooks in case of jpxs reload

		Core:getOrDownloadModule("client", function(Client)
			Client.connect()
			Client.onConnect = function()
				if not Core.hasLoadedModules then
					Core:getDependencies(modules, function()
						Core.hasLoadedModules = true
						_G.jpxs_modulesLoading = nil

						Core:debug("Initial load complete, running post-load hooks...")
						hook.run("JPXSLoaded")
					end)
				end
			end
		end)
	end

	-- check for polyfill (minimum version 3)
	if _G.polyfill and _G.polyfill.version >= 3 then
		postLoad()
	else
		Core:httpGet("/plugins/lib/polyfill.lua", function(response)
			if response then
				loadstring(response)()
				Core:debug("Polyfill loaded")

				postLoad()
			else
				Core:print("Failed to download polyfill")
			end
		end)
	end

	-- load inspect
	if not _G.inspect then
		Core:httpGet("/plugins/lib/inspect.lua", function(response)
			if response then
				_G.inspect = loadstring(response)()
				Core:debug("Inspect loaded")
			else
				Core:print("Failed to download inspect")
			end
		end)
	else
		Core:debug("Inspect already loaded")
	end
end

--- Config values
Core.addHook("JPXSConfigInit", "configLoader", function()
	Core:debug("Registering config values")

	Core.config:registerConfigValue("updateInterval", 60 * 15, "integer", "Data update interval, in ticks")
	-- Config:registerConfigValue("connectionMethod", "http", "string", "Connection method (http, tcp)")
end)

Core:load()

_G.JPXS = Core
_G.jpxs = Core

return Core
