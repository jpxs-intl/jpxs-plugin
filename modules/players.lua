---@type Core
local Core = ...

-- provided by jpsh

local base = memory.getBaseAddress()
local function getTeamBonus(team)
	return math.floor(memory.readFloat(base + 0x5a80bc04 + (0x18 * team)))
end

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

			if not hook.run("JPXSPlayerJoin", player) then
				Client.sendMessage("data", "player:join", {
					player = player.account and {
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
					} or {
						name = player.name,
						phoneNumber = player.phoneNumber,
						steamID = "undefined",
						subRosaID = player.subRosaID,
						address = player.connection.address,
						gender = player.gender,
						head = player.head,
						skinColor = player.skinColor,
						hair = player.hair,
						hairColor = player.hairColor,
						eyeColor = player.eyeColor,
					},
				})
			end

			Core.awaitingPlayers[index] = nil
		end

		if server.ticksSinceReset % 950 == 0 then
			local playerListData = {}

			for _, player in pairs(players.getNonBots()) do
				if
					player.account == nil
					or (player.data.jpxs and player.data.jpxs.isHidden)
					---@diagnostic disable-next-line: undefined-global
					or (isHiddenModerator and isHiddenModerator(player))
				then
					goto continue
				end

				local isManager = nil
				if corporations and player.team > -1 and player.team < #corporations then
					if corporations[player.team] and corporations[player.team].managerPlayerID == player.index then
						isManager = true
					end
				end

				local corp = server.type == TYPE_ROUND and (getTeamBonus(player.team) * player.stocks)
					or player.corporateRating
				if not hook.run("JPXSPlayerListAdd", player) then
					table.insert(playerListData, {
						subRosaID = player.account.subRosaID,
						money = player.money,
						team = player.team,
						budget = player.budget,
						corp = corp,
						crim = player.criminalRating,
						isManager = isManager,
					})
				end
				::continue::
			end

			hook.run("JPXSPlayerListUpdate", playerListData)

			Client.sendMessage("data", "player:list", {
				sunTime = server.sunTime,
				time = server.time / server.TPS,
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
			volume = player.voice and player.voice.volumeLevel,
		})
	end)
end)
