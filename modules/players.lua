---@type Core
local Core = ...

---@param Client JPXSClient
Core:getDependencies({ "client" }, function(Client)
	Core.addHook("PostPlayerCreate", "players", function(player)
		Core.awaitingPlayers[player.index] = true
	end)

	Core.addHook("Logic", "players", function()
		for index, _ in pairs(Core.awaitingPlayers) do
			local player = players[index]

			if player.isBot or player.connection == nil then
				Core.awaitingPlayers[index] = nil
				return
			end

			hook.run("JPXSPlayerJoin", player)

			Client.sendMessage("data", "player:join", {
				player = {
					name = player.account.name,
					phoneNumber = player.account.phoneNumber,
					steamID = player.account.steamID,
					subRosaID = player.account.subRosaID,
					address = player.connection.address,
					gender = player.gender,
					head = player.head,
					skinColor = player.skinColor,
					hair = player.hair,
					hairColor = player.hairColor,
					eyeColor = player.eyeColor,
				},
			})

			Core.awaitingPlayers[index] = nil
		end

		if server.ticksSinceReset % 950 == 0 then
			local playerListData = {}

			for _, player in pairs(players.getNonBots()) do
				if player.account == nil then
					goto continue
				end

				local isManger = nil
				if player.team > -1 and player.team < #corporations then
					if corporations[player.team] and corporations[player.team].managerPlayerID == player.index then
						isManger = true
					end
				end

				table.insert(playerListData, {
					subRosaID = player.account.subRosaID,
					money = player.money,
					team = player.team,
					budget = player.budget,
					corp = player.corporateRating,
					crim = player.criminalRating,
					isManager = isManger,
				})

				::continue::
			end

			hook.run("JPXSPlayerListUpdate", playerListData)

			Client.sendMessage("data", "player:list", {
				players = playerListData,
			})
		end
	end)

	Core.addHook("PlayerDelete", "players", function(player)
		if player.account == nil or player.isBot then
			return
		end

		hook.run("JPXSPlayerLeave", player)

		Client.sendMessage("data", "player:leave", {
			subRosaID = player.account.subRosaID,
		})
	end)

	Core.addHook("PlayerChat", "players", function(player, message)
		if player.account == nil or player.isBot then
			return
		end

		hook.run("JPXSPlayerChat", player, message)

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

		hook.run("JPXSPlayerFinanceUpdate", player)

		Client.sendMessage("data", "player:finance", {
			subRosaID = player.account.subRosaID,
			money = player.money,
			corporateRating = player.corporateRating,
		})
	end)
end)
