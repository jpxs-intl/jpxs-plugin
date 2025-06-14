---@type JPXSPlugin
local plugin = ...

plugin.name = "Transfer"
plugin.author = "max"
plugin.description = "Transfer players, vehicles, items, and data between servers."

---@class JPXSTransfer
---@field sendPlayer fun(player: Player, identifier: string, options: JPXSTransferPublicSendOptions?)
---@field sendVehicle fun(vehicle: Vehicle, identifier: string, options: JPXSTransferPublicSendOptions?)
local Transfer = {
	---@type string
	identifier = server.name,
}
Transfer.__index = Transfer

Transfer.transferring = {}

function Transfer.sendPlayer(ply, identifier, options)
	if not ply.isActive then
		return
	end

	Transfer._resolveServerIdentifier(identifier, function(res)
		if res.success then
			---@type string
			local ip = res.ip
			---@type integer
			local port = res.port

			plugin:debug(
				"Transferring player " .. ply.name .. " to " .. ip .. ":" .. port .. " (" .. res.clientId .. ")"
			)

			Transfer._transferPlayer(ply, ip, port)

			plugin.core.client.sendMessage("server:" .. res.clientId, "transfer:player", {
				identifier = Transfer.identifier,
				name = ply.name,
				ip = ip,
				port = port,
				data = options.data or {},
				playerData = Transfer.resolveData(ply, {
					include = options.include,
					exclude = options.exclude,
				}),
			})
		else
			if options.onError then
				options.onError(res.error)
			end
		end
	end)
end

function Transfer.sendVehicle(vehicle, identifier, options) end

---@param data any
---@param options {include: string[]?, exclude: string[]?}
---@return table
function Transfer.resolveData(data, options)
	local include = options.include or {}
	local exclude = options.exclude or {}

	--- include/exclude properties
	--- format of "property.property"

	local resolved = {}

	for _, prop in ipairs(include) do
		local value = data

		for _, key in ipairs(string.split(prop, ".")) do
			if value[key] == nil then
				break
			end

			value = value[key]
		end

		resolved[prop] = value
	end

	for _, prop in ipairs(exclude) do
		local value = data

		for _, key in ipairs(string.split(prop, ".")) do
			if value[key] == nil then
				break
			end

			value = value[key]
		end

		resolved[prop] = nil
	end

	return resolved
end

---@private
---@param identifier string
---@param callback fun(res: {success: boolean, error: string?, ip: string?, port: integer?, clientId: string?, name: string?})
function Transfer._resolveServerIdentifier(identifier, callback)
	plugin:getOrDownloadModule("api", function()
		jpxs.api:getServerInfo(identifier, function(res)
			if res.success then
				callback(res)
			else
				callback({
					success = false,
					error = res.error or "Unknown error",
				})
			end
		end)
	end)
end

---@private
---@param player Player
---@param ip string
---@param port integer
function Transfer._transferPlayer(player, ip, port)
	local ind = player.index
	local triggerevent = events.createExplosion(Vector())
	triggerevent.type = 32
	local event = player:updateFinance()
	event.type = 8
	event.a = ind
	event.c = port
	event.d = ipToBytes(ip)
	Transfer.transferring[ind] = {
		trigger = triggerevent,
		event = event,
		ip = ip,
		port = port,
	}
end

plugin.core.config:registerConfigValue(
	"identifier",
	server.name,
	"string",
	"The identifier of the server to connect to. This is used to identify the server in the JPXS network."
)

plugin:addHook("JPXSLoaded", function()
	---@type string
	Transfer.identifier = plugin.core.config:get("identifier") or server.name
end)

local invalidate = function(tab)
	tab.event.type = 48
	tab.trigger.type = 48
end

plugin:addHook("Logic", function()
	for ind, tab in pairs(Transfer.transferring) do
		local ply = players[ind]
		if ply.isActive then
			local con = ply.connection
			if con then
				if con:hasReceivedEvent(tab.trigger) and con:hasReceivedEvent(tab.event) then
					con.timeoutTime = 10080
					invalidate(tab)
					Transfer.transferring[ind] = nil
				end
			end
		else
			invalidate(tab)
		end
	end
end)

local lastCon
plugin:addHook("PacketBuilding", function(con)
	if lastCon == con then
		return
	end
	lastCon = con
	local ply = con.player
	if ply == nil then
		return
	end
	for ind, tab in pairs(Transfer.transferring) do
		if ind == ply.index then
			tab.event.type = 8
			tab.trigger.type = 32
		else
			invalidate(tab)
		end
	end
end)

return {
	exportName = "transfer",
	export = Transfer,
}
