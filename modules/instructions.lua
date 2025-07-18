---@type Core
local Core = ...

---@param InstructionManager InstructionManager
Core:getDependencies({ "instructionManager" }, function(InstructionManager)
	InstructionManager.registerHandler("test", function(data, cb)
		cb(true, "Test instruction received")
	end)

	InstructionManager.registerHandler("reload", function(data, cb)
		Core:print("Remote reload requested...")
		cb(true, "Reloading jpxs")
		---@diagnostic disable-next-line: undefined-field
		Core.plugin:reload()
	end)

	InstructionManager.registerHandler("rejoin", function(data, cb)
		local count = 0
		for index, _ in pairs(players.getNonBots()) do
			Core.awaitingPlayers[index] = true
			count = count + 1
		end

		if count == 0 then
			cb(false, "No players to rejoin")
		else
			cb(true, "Rejoining " .. count .. " players")
		end
	end)

	InstructionManager.registerHandler("announce", function(data, cb)
		chat.announceWrap(data.message)
		Core:print("[Announcement] " .. data.message)
		cb(true, "Announcement sent")
	end)
end)
