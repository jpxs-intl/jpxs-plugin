---@type Core
local Core = ...

---@param str string
---@param list string[]
local function autoComplete(str, list)
	for _, v in ipairs(list) do
		if v:startsWith(str) then
			return v
		end
	end
	return str
end

---@class JPXSCommand
---@field info string
---@field usage string
---@field autoComplete (fun(args: string[]): string[])?
---@field call fun(args: string[])
---@field callChat fun(player: Player, args: string[])? only for chat commands
---@field canCall (fun(player: Player): boolean)? only for chat commands

-- jpxs subcommands

Core.commands["help"] = {
	info = "Shows all available commands",
	usage = "jpxs help [page]",
	call = function(args)
		for name, command in pairs(Core.commands) do
			print(string.format("\x1b[36;1m%s\x1b[0m - %s", name, command.info))
		end
	end,
	callChat = function(player, args)
		local chatCommands = {}
		for name, command in pairs(Core.commands) do
			if command.callChat and (command.canCall and command.canCall(player) or true) then
				chatCommands[name] = command
			end
		end

		local page = tonumber(args[2]) or 1
		local pageSize = 4
		local totalPages = math.ceil(table.dictLength(chatCommands) / pageSize)

		if page < 1 or page > totalPages then
			messagePlayerWrap(player, "Invalid page number.")
			return
		end

		messagePlayerWrap(player, string.format("JXPS Help | Page %d of %d", page, totalPages))

		local sliceStart = (page - 1) * pageSize
		local sliceEnd = sliceStart + pageSize
		local i = 0

		for name, command in pairs(chatCommands) do
			i = i + 1
			if i >= sliceStart and i < sliceEnd then
				messagePlayerWrap(player, string.format("%s - %s", name, command.info))
			end
		end
	end,
}

Core.commands["loadmodule"] = {
	info = "Load a module by ID",
	usage = "loadmodule <module>",
	consoleOnly = true,
	call = function(args)
		assert(args[2], "usage")
		Core:downloadModule(args[2], function(name, module)
			print(string.format("Loaded module %s", name))
		end, true)
	end,
}

Core.commands["bin"] = {
	info = "Load a bin by ID",
	usage = "bin <id>",
	consoleOnly = true,
	call = function(args)
		assert(args[2], "usage")
		Core:loadGartBin(args[2], function(name, module)
			print(string.format("Loaded bin %s", name))
		end, true)
	end,
}

Core.commands["info"] = {
	info = "Get server information",
	usage = "info",
	consoleOnly = true,
	call = function(args)
		print(
			string.format(
				"\x1b[32;1m%s\x1b[0m | \x1b[36m%s/%s\x1b[0m | \x1b[36m%.2f tps",
				server.name,
				#players.getNonBots(),
				server.maxPlayers,
				Core.moduleCache["performance"].tpsInfo.recent
			)
		)
		print(
			string.format(
				"\x1b[32;1mServer ID: \x1b[0m\x1b[36m%s \x1b[0m| \x1b[32;1mConnection ID: \x1b[0m\x1b[36m%s \x1b[0m| \x1b[32;1mHost: \x1b[0m\x1b[36m%s:%s",
				Core.client.serverId,
				Core.client.clientId,
				Core.client.address,
				server.port
			)
		)

		local rows = {
			{ "Accounts", accounts.getCount(), 32768 },
			{ "Players", players.getCount(), 256 },
			{ "Humans", humans.getCount(), 256 },
			{ "Items", items.getCount(), 1024 },
			{ "Vehicles", vehicles.getCount(), 512 },
			{ "RigidBodies", rigidBodies.getCount(), 8192 },
			{ "Bonds", bonds.getCount(), 16384 },
			{ "Events", events.getCount(), 65536 },
		}

		local maxNameLength = 0

		for _, row in ipairs(rows) do
			maxNameLength = math.max(maxNameLength, #row[1])
		end

		print("\n\x1b[32;1mLimits:\x1b[0m\n")

		for _, row in ipairs(rows) do
			local name = row[1] .. "\x1b[0m:" .. string.rep(" ", maxNameLength - #row[1])
			local count = row[2]
			local max = row[3]

			print(string.format("\x1b[36;1m%s %d / %d", name, count, max))
		end
	end,
}

Core.commands["ban"] = {
	info = "Bans a player, and syncs it to other synced servers",
	usage = "ban <player> [time] [reason]",
	call = function(args)
		---@type Util
		local util = Core:getModule("util")

		local targetAccount = findOneAccount(args[2])
		local duration = args[3] and util.parseTime(args[3]) or 0
		local reason = args[4] or "No reason provided"

		targetAccount.banTime = duration
		accounts.save()

		---@type JPXSBanSync
		local banSync = Core:getModule("banSync")
		banSync:ban(tostring(targetAccount.phoneNumber), reason, duration)

		local timeFormatted = duration == 0 and "forever" or util.formatTime(duration)

		chat.tellAdminsWrap(string.format("Console banned %s for %s: %s", targetAccount.name, timeFormatted, reason))
		Core:print(string.format("Console banned %s for %s: %s", targetAccount.name, timeFormatted, reason))
	end,
	canCall = function(player)
		return player.isAdmin
	end,
	callChat = function(player, args)
		---@type Util
		local util = Core:getModule("util")

		local targetAccount = findOneAccount(args[2])
		local duration = args[3] and util.parseTime(args[3]) or 0
		local reason = args[4] or "No reason provided"

		targetAccount.banTime = duration == 0 and 2147483647 or duration
		accounts.save()

		---@type JPXSBanSync
		local banSync = Core:getModule("banSync")
		banSync:ban(tostring(targetAccount.phoneNumber), reason, duration)

		local timeFormatted = duration == 0 and "forever" or util.formatTime(duration)

		chat.tellAdminsWrap(
			string.format("%s banned %s for %s: %s", player.name, targetAccount.name, timeFormatted, reason)
		)
		Core:print(string.format("%s banned %s for %s: %s", player.name, targetAccount.name, timeFormatted, reason))
	end,
}

-- actual command, handles processing input and calling the correct subcommand

Core.plugin.commands["/jpxs"] = {
	info = "JPXS commands",
	autoComplete = function(args)
		if #args == 1 then
			args[1] = autoComplete(args[1], table.keys(Core.commands))
		end
	end,
	---@param player string[] | Player
	---@param human Human
	---@param args string[]
	call = function(player, human, args)
		if player.class == "Player" then
			local command = Core.commands[args[1]]
			if command then
				if command.callChat then
					if (command.canCall and command.canCall(player)) or not command.canCall then
						local success, res = pcall(command.callChat, player, args)
						if not success then
							local errorString = tostring(res)
							local _, endPos = errorString:find(": ")
							local stripped = endPos and errorString:sub(endPos + 1) or errorString

							if stripped == "usage" then
								messagePlayerWrap(player, string.format("Usage: %s", command.usage))
							else
								messagePlayerWrap(player, "An error occurred while executing the command.")
								messagePlayerWrap(player, stripped)
							end
						end
					else
						messagePlayerWrap(player, "Command not available in game.")
					end
				else
					messagePlayerWrap(player, "You don't have permission to use this command.")
				end
			else
				messagePlayerWrap(player, "Command not found - use '/jpxs help' to see all available commands.")
			end
		else
			local command = Core.commands[args[1]]
			if command then
				local success, res = pcall(command.call, args)
				if not success then
					local errorString = tostring(res)
					local _, endPos = errorString:find(": ")
					local stripped = endPos and errorString:sub(endPos + 1) or errorString

					if stripped == "usage" then
						print(string.format("\x1b[31;1mUsage: %s\x1b[0m", command.usage))
					else
						print("An error occurred while executing the command.")
						print(stripped)
					end
				end
			else
				print("Command not found - use 'jpxs help' to see all available commands.")
			end
		end
	end,
}
