---@type Core
local Core = ...

---@param Config JPXSConfig
hook.add("JPXSConfigInit", "jpxs.bansync", function(Config)
	Config:registerConfigValue("banSyncEnabled", false, "boolean", "Enable ban synchronization")
	Config:registerConfigValue(
		"banSyncChannelId",
		"bansync_jpxs",
		"string",
		"JPXS Networking channel ID for ban synchronization"
	)
end)

---@class JPXSBanSync
local JPXSBanSync = {}

---@param Client JPXSClient
---@param Util Util
---@param Config JPXSConfig
Core:getDependencies({ "client", "util", "config" }, function(Client, Util, Config)
	local banSyncEnabled = Config:get("banSyncEnabled")
	local banSyncChannelId = Config:get("banSyncChannelId")

	if not banSyncEnabled then
		return
	end

	Client.subscribe(banSyncChannelId)

	Client.registerEventHandler("bansync:ban", function(msg)
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

		local timeFormatted = duration == 0 and "forever" or Util.formatTime(duration)

		chat.tellAdminsWrap(string.format("BanSync banned %s for %s: %s", targetAccount.name, timeFormatted, reason))
		Core:print(string.format("BanSync banned %s for %s: %s", targetAccount.name, timeFormatted, reason))

		targetAccount.banTime = duration == 0 and 2147483647 or duration
		accounts.save()
	end)

	---@param target string
	---@param reason string
	---@param duration number
	function JPXSBanSync:ban(target, reason, duration)
		Client.sendMessage(banSyncChannelId, "bansync:ban", {
			target = target,
			reason = reason,
			duration = duration,
		})
	end
end)

return JPXSBanSync
