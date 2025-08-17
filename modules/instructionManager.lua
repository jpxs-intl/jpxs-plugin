---@type Core
local Core = ...

---@class InstructionManager
local InstructionManager = {
	---@type {[string]: boolean}
	disabledHandlers = {},
}

---@class Instruction
---@field type string
---@field id string
---@field cb fun(success: boolean, res: string)

---@type {[string]: fun(data: any, cb: fun(success: boolean, res: string))}
InstructionManager.handlers = {}

---@param type string
---@param handler fun(data: any, cb: fun(success: boolean, res: string))
function InstructionManager.registerHandler(type, handler)
	Core:debug("Registering instruction handler for type: " .. type)
	InstructionManager.handlers[type] = handler
end

---@param Client JPXSClient
Core:getDependencies({ "client" }, function(Client)
	Client.registerEventHandler("instruction:execute", function(msg)
		local type = msg.type
		local id = msg.id
		local data = msg.data

		if InstructionManager.disabledHandlers[type] then
			Client.sendMessage("instructionResponse", "instruction:response", {
				id = id,
				success = false,
				res = "Handler for instruction type " .. type .. " is disabled.",
			})
			return
		end

		local handler = InstructionManager.handlers[type]
		if not handler then
			Client.sendMessage("instructionResponse", "instruction:response", {
				id = id,
				success = false,
				res = "No handler for instruction type: " .. type,
			})
			return
		end

		handler(data, function(success, res)
			Client.sendMessage("instructionResponse", "instruction:response", {
				id = id,
				success = success,
				res = res,
			})
		end)
	end)
end)

return InstructionManager
