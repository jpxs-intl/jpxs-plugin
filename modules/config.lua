---@type Core
local Core = ...

local json = require("main.json")

---@class JPXSConfigValue
---@field value any
---@field type string
---@field description string
---@field default any

---@class JPXSConfig
---@field values table<string, JPXSConfigValue>
local Config = {
	values = {},
}

---@param key string
---@param default any
---@param type string
---@param description string
---@return JPXSConfigValue
function Config:registerConfigValue(key, default, type, description)
	self.values[key] = {
		value = self.values[key] and self.values[key].value or default,
		default = default,
		type = type,
		description = description,
	}

	Core:debug("Registered config value " .. key)

	return self.values[key]
end

---@param key string
---@return any
function Config:get(key)
	if self.values[key] == nil then
		Core:debug("Config value " .. key .. " does not exist")
		return nil
	end

	return self.values[key].value
end

---@param key string
---@param value any
---@return any
function Config:set(key, value)
	if self.values[key] == nil then
		return false
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
		end
	end

	return true
end

function Config:init()
	-- fire hook to register config values
	hook.run("JPXSConfigInit", self)
	self:load()
	self:save()
	hook.run("JPXSConfigLoaded", self)
end

Core.config = Config

Config:init()

return Config
