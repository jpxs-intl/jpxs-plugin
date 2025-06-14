---@type Core
local Core = ...

---@param Client JPXSClient
Core:getDependencies({ "client" }, function(Client)
	Core.addHook("PostPlayerCreate", "players", function(player)
		Core.awaitingPlayers[player.index] = true
	end)

	Core.addHook("Logic", "players", function()
		for index, _ in pairs(Core.awaitingPlayers) do
			local ply = players[index]

			if ply.isBot or ply.connection == nil then
				Core.awaitingPlayers[index] = nil
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

			Core.awaitingPlayers[index] = nil
		end

		if server.ticksSinceReset % (Core.config:get("updateInterval") or 300) == 0 then
			local playerListData = {}

			for _, player in pairs(players.getNonBots()) do
				if player.account == nil then
					goto continue
				end

				table.insert(playerListData, {
					subRosaID = player.account.subRosaID,
					money = player.money,
					team = player.team,
					budget = player.budget,
					corp = player.corporateRating,
					crim = player.criminalRating,
				})

				::continue::
			end

			Client.sendMessage("data", "player:list", {
				players = playerListData,
			})
		end
	end)

	Core.addHook("PlayerDelete", "players", function(player)
		if player.account == nil or player.isBot then
			return
		end

		Client.sendMessage("data", "player:leave", {
			subRosaID = player.account.subRosaID,
		})
	end)

	Core.addHook("PlayerChat", "players", function(player, message)
		if player.account == nil or player.isBot then
			return
		end

		Client.sendMessage("data", "player:chat", {
			subRosaID = player.account.subRosaID,
			message = message,
			volume = player.voice.volumeLevel,
		})
	end)

	Core.addHook("PostEventUpdatePlayerFinance", "players", function(player)
		if player.account == nil or player.isBot then
			return
		end

		Client.sendMessage("data", "player:finance", {
			subRosaID = player.account.subRosaID,
			money = player.money,
			corporateRating = player.corporateRating,
		})
	end)
end)
