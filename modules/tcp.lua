---@type Core
local Core = ...

---@diagnostic disable: deprecated
---@diagnostic disable: assign-type-mismatch
---@class TCP
---@field host string
---@field port integer
---@field thread Worker
---@field active boolean
---@field connected boolean
---@field reconnectTimer integer
---@field messageHandler fun(message: string)
local TCP = {}

---@type TCP
local client

TCP.workerPath = Core.storagePath .. "tcp.worker.lua"
TCP.__index = TCP

---@param host string
---@param port integer
function TCP.connect(host, port)
	if client and client.thread then
		client.thread:sendMessage(("zsn"):pack("connect", host, port))
		return client
	else
		local self = setmetatable({
			host = host,
			port = port,
			connected = false,
			reconnectTimer = 0,
			thread = Worker.new(TCP.workerPath),
			active = true,
		}, TCP)

		self.thread:sendMessage(("zsn"):pack("connect", host, port))

		client = self
		return self
	end
end

---@param message string
function TCP:sendMessage(message)
	if not self.connected then
		Core:debug("TCP connection not established. (sendMessage)")
		return
	end
	self.thread:sendMessage(("zz"):pack("send", message))
end

---@param cb fun(message: string)
function TCP:onMessage(cb)
	self.messageHandler = cb
end

function TCP:close()
	client.connected = false
	client.active = false

	self.thread:stop()
	self.thread = nil
end

hook.add("Logic", "jpxs.tcp", function()
	if not client or not client.active or not client.thread then
		return
	end

	if client.reconnectTimer > 0 then
		client.reconnectTimer = client.reconnectTimer - 1
		if client.reconnectTimer == 0 then
			client.thread:sendMessage(("zsn"):pack("connect", client.host, client.port))
		end
	else
		if not client.thread then
			return
		end

		local message = client.thread:receiveMessage()
		if not message then
			return
		end

		---@type string, string
		local type = ("z"):unpack(message)

		if type == "message" and client.messageHandler then
			---@type string, string
			local _, msg = ("zz"):unpack(message)

			-- print("<-- " .. msg)

			if msg:len() == 0 then
				Core:debug("TCP connection closed. (empty message)")

				client:close()
				return
			end

			client.messageHandler(msg)
		elseif type == "connect" then
			client.connected = true
		elseif type == "close" then
			---@type string, string
			local _, err = ("zz"):unpack(message)
			Core:debug("TCP connection closed. (" .. err .. ")")

			client:close()
			return
		end
	end
end)

return TCP
