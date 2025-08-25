---@type Core
local Core = ...

local storageMeta = {}
---@param self JPXSStorage
---@param key string
---@param value? (string | fun(success: boolean, value: string | nil))
---@param token?  (string | fun(success: boolean))
---@param cb? fun(success: boolean)
function storageMeta.__call(self, key, value, token, cb)
	if not cb and type(token) == "function" then
		cb = token
		token = nil
	end

	if not cb and type(value) == "function" then
		cb = value
		value = nil
	end

	if value == nil then
		---@cast cb fun(success: boolean, value: string | nil)
		return self.get(key, cb)
	else
		---@cast value string
		---@cast cb fun(success: boolean)
		return self.set(key, value, token, cb)
	end
end

---@class JPXSStorage
local storage = {}

setmetatable(storage, storageMeta)

---@param key string
---@param cb fun(success: boolean, value: string | nil): nil
function storage.get(key, cb)
	Core.client.request("storage", "get", { key = key }, function(msg)
		cb(msg.success, msg.value)
	end)
end

---@param key string
---@param value string
---@param token (string | fun(success: boolean): nil)?
---@param cb fun(success: boolean): nil
function storage.set(key, value, token, cb)
	if not cb and type(token) == "function" then
		cb = token
		token = nil
	end

	Core.client.request("storage", "set", { key = key, value = value, token = token }, function(msg)
		cb(msg.success)
	end)
end

function storage.delete(key, token, cb)
	Core.client.request("storage", "delete", { key = key, token = token }, function(msg)
		cb(msg.success)
	end)
end

return {
	export = storage,
}
