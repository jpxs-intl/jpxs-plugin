---@type Core
local Core = ...

---@class JPXSAPI
local Api = {}
Api.__index = Api

---@private
---@param channel string
---@param event string
---@param data any
---@param cb fun(msg: any)
function Api:_request(channel, event, data, cb)
	---@param client JPXSClient
	Core:getOrDownloadModule("client", function(client)
		client.request(channel, event, data, cb)
	end)
end

---@param cb fun(ping: number)
function Api:getPing(cb)
	self:_request("ping", "ping", { sentAt = os.realClock() }, function(msg)
		cb(msg.data.sentAt and (os.realClock() - msg.data.sentAt) * 1000)
	end)
end

---@param identifier string
---@param cb fun(res: {success: boolean, error: string?, ip: string?, port: integer?, clientId: string?, name: string?})
function Api:getServerInfo(identifier, cb)
	self:_request("api", "server:transferinfo", { identifier = identifier }, function(msg)
		if msg.data.success then
			cb({
				success = true,
				ip = msg.data.ip,
				port = msg.data.port,
				clientId = msg.data.clientId,
				name = msg.data.name,
			})
		else
			cb({
				success = false,
				error = msg.data.error or "Unknown error",
			})
		end
	end)
end

return {
	export = Api,
}
