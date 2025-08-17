---@diagnostic disable
---@type TCPClient
local tcpClient = nil
local hasConnected = false

local function handleMessage(message)
	local method = ("z"):unpack(message)

	if method == "connect" then
		local _, host, port = ("zsn"):unpack(message)
		tcpClient = TCPClient.new(host, port)
		return
	elseif method == "send" then
		if tcpClient and tcpClient.isOpen then
			local _, message = ("zz"):unpack(message)
			tcpClient:send(message)
		else
			hasConnected = false
			sendMessage(("z"):pack("close"))
		end
		return
	end
end

while true do
	while true do
		local message = receiveMessage()
		if not message then
			break
		end

		handleMessage(message)
	end

	if tcpClient and tcpClient.isOpen then
		if not hasConnected then
			sendMessage(("z"):pack("connect"))
			hasConnected = true
		end

		local success, err = pcall(function()
			local message = tcpClient:receive(16384)
			if message then
				sendMessage(("zz"):pack("message", message))
			end
		end)

		if not success then
			tcpClient:close()
			-- tcpClient = nil
			hasConnected = false
			
			if err and type(err) == "string" then
				sendMessage(("zz"):pack("close", err))
			else
				sendMessage(("zz"):pack("close", "Failed to receive message."))
			end
		end
	end

	if sleep(8) then
		tcpClient = nil
		break
	end
end
