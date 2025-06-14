---@type JPXSPlugin
local plugin = ...
plugin.name = "BanSync"
plugin.author = "max"
plugin.description = "Synchronizes bans across servers using JPXS Networking"

---@class JPXSBanSync
local JPXSBanSync = {}

plugin:addEnableHandler(function()
	---@type Util
	local util = plugin.core:getModule("util")

	plugin.core.config:registerConfigValue(
		"banSyncChannelId",
		"disabled",
		"string",
		"JPXS Networking channel ID for ban synchronization"
	)

	local banSyncChannelId = plugin.core.config:get("banSyncChannelId")

	if banSyncChannelId == "disabled" then
		plugin:print("\x1b[31;1mBanSync is enabled but no channel ID is set.")
		plugin:print("\x1b[31;1mPlease set a channel ID using this command:")
		plugin:print("\x1b[10;1mjpxs config banSyncChannelId [channelId]")
		plugin:print("\x1b[31;1mSet servers to the same channel to sync bans.")
		return
	end

	plugin.core.client.subscribe(banSyncChannelId)

	plugin.core.client.registerEventHandler("bansync:ban", function(msg)
		local target = tostring(msg.target)
		local reason = msg.reason
		local duration = msg.duration

		if not target or not reason or not duration then
			return
		end

		local targetAccount = findOneAccount(target)
		if not targetAccount then
			return
		end

		local timeFormatted = duration == 0 and "forever" or util.formatTime(duration)

		chat.tellAdminsWrap(string.format("BanSync banned %s for %s: %s", targetAccount.name, timeFormatted, reason))
		plugin:print(string.format("BanSync banned %s for %s: %s", targetAccount.name, timeFormatted, reason))

		targetAccount.banTime = duration == 0 and 2147483647 or duration
		accounts.save()
	end)

	---@param target string
	---@param reason string
	---@param duration number
	function JPXSBanSync:ban(target, reason, duration)
		plugin.core.client.sendMessage(banSyncChannelId, "bansync:ban", {
			target = target,
			reason = reason,
			duration = duration,
		})
	end

	plugin.core.commands["ban"] = {
		info = "Bans a player, and syncs it to other synced servers",
		usage = "ban <player> [time] [reason]",
		call = function(args)
			---@type Util

			local targetAccount = findOneAccount(args[2])
			local duration = args[3] and util.parseTime(args[3]) or 0
			local reason = args[4] or "No reason provided"

			targetAccount.banTime = duration
			accounts.save()

			JPXSBanSync:ban(tostring(targetAccount.phoneNumber), reason, duration)

			local timeFormatted = duration == 0 and "forever" or util.formatTime(duration)

			chat.tellAdminsWrap(
				string.format("Console banned %s for %s: %s", targetAccount.name, timeFormatted, reason)
			)
			plugin:print(string.format("Console banned %s for %s: %s", targetAccount.name, timeFormatted, reason))
		end,
		canCall = function(player)
			return player.isAdmin
		end,
		callChat = function(player, args)
			local targetAccount = findOneAccount(args[2])
			local duration = args[3] and util.parseTime(args[3]) or 0
			local reason = args[4] or "No reason provided"

			targetAccount.banTime = duration == 0 and 2147483647 or duration
			accounts.save()

			JPXSBanSync:ban(tostring(targetAccount.phoneNumber), reason, duration)

			local timeFormatted = duration == 0 and "forever" or util.formatTime(duration)

			chat.tellAdminsWrap(
				string.format("%s banned %s for %s: %s", player.name, targetAccount.name, timeFormatted, reason)
			)
			plugin:print(
				string.format("%s banned %s for %s: %s", player.name, targetAccount.name, timeFormatted, reason)
			)
		end,
	}
end)
