---@diagnostic disable: deprecated

---@type Core
local Core = ...

---@class JPXSHTTP : ConnectionInterface
local HTTP = {}

HTTP.workerPath = Core.storagePath .. "http.worker.lua"
HTTP.host = ""
HTTP.path = ""
HTTP.connected = false
---@type {incoming: {thread: Worker, pending: boolean}, outgoing: {thread: Worker, pending: integer}}
HTTP.workers = {}
---@type fun(message: string)
HTTP.messageHandler = function(message) end

HTTP.__index = HTTP

---@param WorkderLoader WorkerLoader
Core:getDependencies({ "workerLoader" }, function(WorkderLoader)
	WorkderLoader.loadWorkers(function()
		HTTP.workers = {
			incoming = {
				pending = false,
				thread = Worker.new(HTTP.workerPath),
			},
			outgoing = {
				pending = 0,
				thread = Worker.new(HTTP.workerPath),
			},
		}
	end)
end)

---@param incoming boolean
---@param message string
local function handleMessage(incoming, message)
	local callbackIndex, hasResponse, pos = ("ni1"):unpack(message)

	if hasResponse == 1 then
		---@type string
		local status, body
		status, body, pos = unpack({ ("nsn"):unpack(message, pos) })

		if incoming and HTTP.messageHandler then
			HTTP.messageHandler(body)
		end
	end

	if callbackIndex == -1 then
		return
	end
end

---Send an HTTP(S) GET request asynchronously.
local function get()
	local serialized = ("znss"):pack("GET", HTTP.host, HTTP.path)

	HTTP.workers.incoming.thread:sendMessage(serialized)
	HTTP.workers.incoming.pending = true
end

---Send an HTTP(S) POST request asynchronously.
---@param body string The request body.
local function post(body)
	local serialized = ("znssss"):pack("POST", HTTP.host, HTTP.path, body, "application/json")
	HTTP.workers.outgoing.thread:sendMessage(serialized)
end

---@param host string
---@param path string
function HTTP.connect(host, path)
	HTTP.host = host
	HTTP.path = path

	Core:debug(string.format("Connecting to %s%s...", host, path))

	get()
end

---@param message string
function HTTP:sendMessage(message)
	post(message)
end

---@param cb fun(message: string)
function HTTP:onMessage(cb)
	HTTP.messageHandler = cb
end

function HTTP:close()
	HTTP.workers.incoming.thread:stop()
	HTTP.workers.outgoing.thread:stop()
	HTTP.workers.incoming.thread = nil
	HTTP.workers.outgoing.thread = nil
end

Core.addHook("Logic", "http", function()
	if HTTP.workers.incoming and HTTP.workers.incoming.pending == true then
		local message = HTTP.workers.incoming.thread:receiveMessage()
		if message then
			HTTP.workers.incoming.pending = false
			handleMessage(true, message)

			if not HTTP.connected then
				HTTP.connected = true
			end

			get()
		end
	end

	if HTTP.workers.outgoing and HTTP.workers.outgoing.pending ~= 0 then
		while true do
			local message = HTTP.workers.outgoing.thread:receiveMessage()
			if not message then
				break
			end

			handleMessage(false, message)
			HTTP.workers.outgoing.pending = HTTP.workers.outgoing.pending - 1
		end
	end
end)

return HTTP
