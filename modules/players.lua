---@type Core
local Core = ...

---@type {[integer]: boolean}
local awaitingPlayers = {}

---@param Client JPXSClient
Core:getDependencies({ "client" }, function(Client)
	hook.add("PostPlayerCreate", "jpxs.players", function(player)
		awaitingPlayers[player.index] = true
	end)

	hook.add("Logic", "jpxs.players", function()
		for index, _ in pairs(awaitingPlayers) do
			local ply = players[index]

			if ply.isBot or ply.connection == nil then
				awaitingPlayers[index] = nil
				return
			end

			Client.sendMessage("data", "player:join", {
				player = {
					name = ply.account.name,
					phoneNumber = ply.account.phoneNumber,
					steamID = ply.account.steamID,
					subRosaID = ply.account.subRosaID,
					address = ply.connection.address,
					gender = ply.gender,
					head = ply.head,
					skinColor = ply.skinColor,
					hair = ply.hair,
					hairColor = ply.hairColor,
					eyeColor = ply.eyeColor,
				},
			})

			awaitingPlayers[index] = nil
		end

		if server.ticksSinceReset % Core.config:get("updateInterval") == 0 then
			local playerListData = {}

			for _, player in pairs(players.getNonBots()) do
				table.insert(playerListData, {
					subRosaID = player.account.subRosaID,
					money = player.money,
					team = player.team,
					budget = player.budget,
					corp = player.corporateRating,
					crim = player.criminalRating,
				})
			end

			Client.sendMessage("data", "player:list", playerListData)
		end
	end)

	hook.add("PlayerDelete", "jpxs.players", function(player)
		Client.sendMessage("data", "player:leave", {
			subRosaID = player.account.subRosaID,
		})
	end)

	hook.add("PlayerChat", "jpxs.players", function(player, message)
		Client.sendMessage("data", "player:chat", {
			subRosaID = player.account.subRosaID,
			message = message,
			volume = player.voice.volumeLevel,
		})
	end)

	hook.add("PostEventUpdatePlayerFinance", "jpxs.players", function(player)
		Client.sendMessage("data", "player:finance", {
			subRosaID = player.account.subRosaID,
			money = player.money,
			corporateRating = player.corporateRating,
		})
	end)
end)
