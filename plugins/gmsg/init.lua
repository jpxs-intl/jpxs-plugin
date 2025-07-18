---@type JPXSPlugin
local plugin = ...
plugin.name = "Global Message"
plugin.author = "max"
plugin.description = "Send a message to a friend on another server"

---@class GlobalMessageData
---@field message string
---@field sender integer
---@field senderName string
---@field serverName string
---@field recipient integer

---@param message GlobalMessageData
local function handleGlobalMessageResponse(message)
	local recipient = findOnePlayer(tostring(message.recipient))

	if not recipient then
		return
	end
	messagePlayerWrap(recipient, string.format("Global message from %s", message.serverName))
	messagePlayerWrap(
		recipient,
		string.format("%s (%s): %s", message.senderName, dashPhoneNumber(message.sender), message.message)
	)
end

--- try to keep this unique to avoid conflicts
jpxs.client.registerEventHandler("globalmessage:message", handleGlobalMessageResponse)

jpxs.client.subscribe("globalmessage")

plugin.rsPlugin.commands["/gmsg"] = {
	info = "Send a global message",
	usage = "<message>",
	call = function(player, human, args)
		local recipient = tonumber(args[1]) or findOneAccount(args[1]).phoneNumber
		table.remove(args, 1)

		assert(recipient, "Invalid recipient")

		jpxs.client.sendMessage("globalmessage", "globalmessage:message", {
			message = table.concat(args, " "),
			sender = player.isConsole and "000-0000" or player.phoneNumber,
			senderName = player.isConsole and "Console" or player.account.name,
			serverName = server.name,
			recipient = recipient,
		})

		messagePlayerWrap(player, "Message sent!")
	end,
}
