-- jpxs types for your convience!
-- loaded by jpxs.lua

-- idk why you would, but don't edit this file
-- it will be overwritten by the loader next
-- time jpxs is loaded

---@class JPXSClient
---@field host string
---@field port integer
---@field address string
---@field subscribe fun(event: string, key?: string)
---@field unsubscribe fun(event: string)
---@field sendMessage fun(channelId: string, event: string, data: any)
---@field registerEventHandler fun(event: string, handler: fun(msg: {sender: string, timestamp: number, [string]: any}))

---@class JPXSCorePublic
---@field debug fun(msg: string)
---@field print fun(msg: string)
---@field getDependencies fun(deps: string[], cb: fun(...: any))
---@field client JPXSClient ⚠️⚠️ DANGER ⚠️⚠️ ONLY use this if you know its loaded, otherwise use `Core.getDependencies`
---@field transfer JPXSTransferPublic
---@field api JPXSAPIPublic

---@class JPXSTransferPublic
---@field identifier string
---@field sendPlayer fun(player: Player, identifier: string, options: JPXSTransferPublicSendOptions?)
---@field sendVehicle fun(vehicle: Vehicle, identifier: string, options: JPXSTransferPublicSendOptions?)

---@class JPXSTransferPublicSendOptions
---@field include string[]? List of properties to include in the transfer, see the documentation for more info
---@field exclude string[]? List of properties to exclude from the transfer
---@field data any? Extra data to send with the transfer (available as `data` in the receiving function)
---@field callback fun(data: any)? Callback function to run when the transfer is finished
---@field onError fun(err: string)? Callback function to run when the transfer fails

---@class JPXSAPIPublic
---@field getPing fun(self: JPXSAPIPublic, cb: fun(ping: number))
---@field getServerInfo fun(self: JPXSAPIPublic, identifier: string, cb: fun(res: {success: boolean, error: string?, ip: string?, port: integer?, clientId: string?, name: string?}))

do
	---@type JPXSCorePublic
	---@diagnostic disable-next-line
	jpxs = {}

	---@type JPXSCorePublic
	---@diagnostic disable-next-line
	JPXS = {}
end
