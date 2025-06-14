---@type Core
local Core = ...

local json = require("main.json")

---@class JPXSConfigValue
---@field value any
---@field type string
---@field description string
---@field default any
---@field hidden? boolean -- whether the config value should be hidden from the config command

---@class JPXSConfig
---@field values table<string, JPXSConfigValue>
local Config = {
	values = {},
}

---@param key string
---@param default any
---@param type string
---@param description string
---@param hidden? boolean
---@return JPXSConfigValue
function Config:registerConfigValue(key, default, type, description, hidden)
	local keyAlreadyExists = self.values[key] ~= nil

	self.values[key] = {
		value = self.values[key] and self.values[key].value or default,
		default = default,
		type = type,
		description = description,
		hidden = hidden or false, -- default to false if not provided
	}

	Core:debug("Registered config value " .. key .. (keyAlreadyExists and " (prepopulated)" or ""))

	return self.values[key]
end

---@param key string
---@return any
function Config:get(key)
	if self.values[key] == nil then
		return nil
	end

	return self.values[key].value
end

---@param key string
---@param value any
---@return any
function Config:set(key, value)
	if self.values[key] == nil then
		self:registerConfigValue(key, value, "unknown", "Unknown or custom config value (are you missing a plugin?)")
		Core:debug("Config value " .. key .. " does not exist, creating a blank entry")
		self:save()
		return value
	end

	if self.values[key].type == "boolean" then
		value = value == "true" or value == "1" or value == true
	elseif self.values[key].type == "number" then
		value = tonumber(value)
	end

	self.values[key].value = value
	self:save()
	return value
end

---@param key string
---@return boolean
function Config:resetConfigValue(key)
	if not self.values[key] then
		return false
	end
	self.values[key].value = self.values[key].default
	return true
end

---@param key string
---@return boolean
function Config:deleteConfigValue(key)
	if not self.values[key] then
		return false
	end
	self.values[key] = nil
	return true
end

function Config:save()
	local file = io.open(Core.storagePath .. "config.json", "w")
	if not file then
		return false
	end

	local data = {}

	for key, value in pairs(self.values) do
		data[key] = value.value
	end

	file:write(json.encode(data))

	file:close()
	return true
end

function Config:load()
	local file = io.open(Core.storagePath .. "config.json", "r")
	if not file then
		return false -- no config file,
	end
	local data = file:read("*all")
	file:close()
	local values = json.decode(data)
	if not values then
		return false
	end

	for key, value in pairs(values) do
		if self.values[key] then
			self.values[key].value = value

			Core:debug("Loaded config value " .. key .. " with value " .. tostring(value))
		else
			Core:debug("Config value " .. key .. " does not exist, creating a blank entry")

			self.values[key] = {
				value = value,
				default = nil,
				type = "unknown",
				description = "Unknown or custom config value (are you missing a plugin?)",
			}
		end
	end

	return true
end

Core.config = Config

Core.addHook("JPXSLoaded", "config", function()
	-- fire hook to register config values
	Config:load()
	hook.run("JPXSConfigLoaded", Config)
	Core:debug("Config loaded")
end)

hook.run("JPXSConfigInit", Config)

Core.commands["config"] = {
	info = "View and modify config values",
	usage = "jpxs config [key] [value]",
	call = function(args)
		local key = args[2]
		local value = args[3] and table.concat(args, " ", 3) or nil

		---@type JPXSConfig
		local config = Core:getModule("config")

		if key then
			if value then
				local val = config.values[key]
				if val and val.hidden then
					print(string.format("Config value %s is hidden and cannot be modified", key))
					return
				end

				config:set(key, value)
				print(string.format("Set %s to %s", key, value))
			else
				local val = config.values[key]

				if not val or val.hidden then
					print(string.format("Config value %s not found", key))
					return
				end

				print(string.format("\x1b[36;1m%s", key))
				print(string.format("  \x1b[0m%s", val.description))
				print(string.format("  \x1b[36;1mType: \x1b[0m%s", val.type))
				print(string.format("  \x1b[36;1mValue: \x1b[0m%s", val.value))
				print(string.format("  \x1b[36;1mDefault: \x1b[0m%s", val.default))
			end
		else
			-- sort the config values by key
			local sortedKeys = {}

			for key in pairs(config.values) do
				table.insert(sortedKeys, key)
			end

			table.sort(sortedKeys)

			for _, key in ipairs(sortedKeys) do
				local val = config.values[key]
				if not val.hidden then
					print(string.format("\x1b[36;1m%s\x1b[0m - %s", key, val.description))
				end
			end
		end
	end,
}

Core.commands["purgeunusedconfig"] = {
	hidden = true,
	info = "Purge unused config values (mostly for development purposes)",
	usage = "jpxs purgeunusedconfig",
	call = function()
		local config = Core:getModule("config")
		local keysToDelete = {}

		for key, value in pairs(config.values) do
			if value.type == "unknown" then
				table.insert(keysToDelete, key)
			end
		end

		for _, key in ipairs(keysToDelete) do
			config:deleteConfigValue(key)
			print(string.format("Deleted unused config value: %s", key))
		end

		config:save()
	end,
}

return Config
