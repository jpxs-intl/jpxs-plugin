---@type Core
local Core = ...

local json = require("main.json")

---@class JPXSClient
local Client = {}

Client.host = "gateway.jpxs.io"
Client.path = "/events"
Client.port = 4000
Client.reconnectTimer = 1200

---@type TCP
Client.tcp = nil
---@type string
Client.tag = nil
---@type string
Client.clientId = nil
Client.hasInit = false
Client.isInvalid = false
---@type string
Client.serverId = nil
---@type string
Client.address = nil

---@type fun()
Client.onConnect = nil

---@type number
Client.ping = 0

---@type {[number]: function}
Client.callbacks = {}

Client.seperator = "//"

-- force overrides so we can connect to alt servers
if Core.overrides then
	Client.host = Core.overrides.gatewayHost or Client.host
	Client.port = Core.overrides.gatewayPort or Client.port
end

---@type {[string]: fun(msg: {sender: string, timestamp: number, [string]: any})}
Client.eventHandlers = {
	["auth:init"] = function(msg)
		if not Client.hasInit then
			local authFile = io.open(Core.storagePath .. ".tag", "r")
			if authFile then
				Client.tag = authFile:read("*all")
				authFile:close()
			else
				Client.tag = ""
			end

			Client._createEvent("auth", "auth:login", {
				type = "server",
				port = server.port,
				tag = Client.tag,
			})

			Client.clientId = msg.clientId
			Client.hasInit = true

			Core:debug("Initiated connection with the JPXS gateway. Client ID: " .. msg.clientId)
		end
	end,
	["auth:delay"] = function(msg)
		Core:print("[gateway] " .. msg.message)
	end,
	["auth:invalidate"] = function(msg)
		if Client.isInvalid then
			return
		end

		Client.isInvalid = true
		Core:print("[gateway]: re-authenticating with id: " .. msg.clientId)
		Client._createEvent("auth", "auth:login", {
			type = "server",
			port = server.port,
			tag = Client.tag,
		})
	end,
	["auth:tag"] = function(msg)
		local tag = msg.tag

		local authFile = io.open(Core.storagePath .. ".tag", "w")
		assert(authFile, "Failed to open .tag file.")
		authFile:write(tag)
		authFile:close()

		Client.tag = tag
	end,
	["auth:success"] = function(msg)
		Core:print("Successfully authenticated with the JPXS gateway.")
		Core:print("Connection ID: " .. msg.clientId .. " | Server ID: " .. msg.serverId)

		if Client.onConnect then
			Client.onConnect()
		end

		hook.run("JPXSConnected", Client)

		Client.clientId = msg.clientId
		Client.serverId = msg.serverId
		Client.address = msg.address

		Client.isInvalid = false

		Client.subscribe("server:" .. Client.serverId)
		Client.subscribe("api")
	end,
	["auth:fail"] = function(msg)
		Core:print("Failed to authenticate with JPXS gateway: " .. msg.message)
	end,
}

---@private
---@param interface TCP
function Client._handleConnection(interface)
	Core:debug("Connecting to JPXS gateway...")
	Client.tcp = interface.connect(Client.host, Client.port)

	Client.tcp:onMessage(function(message)
		local parts = message:split(Client.seperator)
		for _, part in pairs(parts) do
			local length, encoded = part:match("^(%d+):(.+)$")
			if encoded then
				local success = pcall(function()
					local msg = json.decode(encoded)
					if not msg or not msg.data then
						return
					end

					if msg.data.requestId then
						local callback = Client.callbacks[msg.data.requestId]
						if callback then
							callback(msg.data)
							Client.callbacks[msg.data.requestId] = nil
						end
					end

					local handler = Client.eventHandlers[msg.event]
					if handler then
						handler(msg.data)
					end
				end)

				if not success then
					Core:debug("Failed to decode message: " .. encoded)
				end
			else
				Core:debug("Invalid message: " .. part)
			end
		end
	end)

	-- Util.setTimeout(60, function()
	-- 	Client.sendMessage("auth", "auth:request", {})
	-- end)
end

function Client.connect()
	if not TCPClient then
		Core:print("\x1b[31;1mWARNING: ")
		Core:print("\x1b[31;1mYour server is extremely out of date and does not support TCP.")
		Core:print("\x1b[31;1mPlease update your server to the latest version.")
		return
	end

	---@param TCP TCP
	---@param WorkerLoader WorkerLoader
	---@param Util Util
	Core:getDependencies({ "tcp", "workerLoader", "util", "config" }, function(TCP, WorkerLoader, Util)
		WorkerLoader.loadWorkers(function()
			Client._handleConnection(TCP)
		end)
	end)
end

---@private
function Client._createEvent(channel, event, data)
	local msg = json.encode({
		channel = channel,
		event = event,
		data = data,
	})

	if not Client.tcp then
		Core:debug("Client is not connected to the gateway.")
		return
	end

	Client.tcp:sendMessage(string.format("%s" .. Client.seperator, msg))
end

--- send a request to the server, expects a response
---@param channelId string channel id
---@param event string event name
---@param data any data to send
---@param cb fun(msg: {sender: string, timestamp: number, [string]: any}) callback function
function Client.request(channelId, event, data, cb)
	local requestId = math.random(1, 1000000)

	if data.requestId then
		Core:print("!! WARNING !! requestId is a reserved field and will be overridden.")
	end

	data.requestId = requestId

	Client._createEvent(channelId, event, data)
	Client.callbacks[requestId] = cb
end

--- Subscribe to a channel. Will create the channel if it doesn't exist.
---@param channelId string channel id
---@param key? string channel key (needed for private channels)
function Client.subscribe(channelId, key)
	Client._createEvent("subscriber", "channel:subscribe", {
		channel = channelId,
		key = key,
	})
end

--- Unsubscribe from a channel.
---@param channelId string
function Client.unsubscribe(channelId)
	Client._createEvent("subscriber", "channel:unsubscribe", {
		channel = channelId,
	})
end

--- Register a handler for a message type
---@param event string
---@param handler fun(msg: {sender: string, timestamp: number, [string]: any})
function Client.registerEventHandler(event, handler)
	Client.eventHandlers[event] = handler
end

--- Send a message to a channel
---@param channelId string
---@param event string
---@param data table
function Client.sendMessage(channelId, event, data)
	Client._createEvent(channelId, event, data)
end

Core.addHook("Logic", "keepalive", function()
	if server.ticksSinceReset % Client.reconnectTimer == 0 then
		if not Client.tcp then
			Client.connect()
		else
			if Client.tcp.connected then
				Client.request("ping", "ping", { sentAt = os.realClock() }, function(msg)
					Client.ping = (os.realClock() - msg.data.sentAt) * 1000
					hook.run("JPXSPing", Client.ping)
				end)
			else
				Core:debug("Lost connection to the JPXS gateway, attempting to reconnect...")
				Client.hasInit = false

				Core:getModule("util").setTimeout(60, function()
					Client._handleConnection(Core:getModule("tcp"))
				end)
			end
		end
	end
end)

Core.client = Client

return Client
