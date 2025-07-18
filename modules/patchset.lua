---@type Core
local Core = ...

---@class JPXSPatchSet
---@field public name string
---@field public patches table<number, JPXSPatch>
local PatchSet = {
	---@type table<string, JPXSPatchSet>
	patches = {},
}
PatchSet.__index = PatchSet

---@class JPXSPatch
---@field addr number
---@field oldValue number
---@field newValue number
---@field public description string

function PatchSet.create(name)
	local instance = setmetatable({}, PatchSet)
	instance.name = name
	instance.patches = {}

	if not PatchSet.patches then
		PatchSet.patches = {}
	end

	PatchSet.patches[name] = instance

	return instance
end

---@param addr number
---@param value number
---@param description string?
function PatchSet:writeByte(addr, value, description)
	local base = memory.getBaseAddress()
	local shiftedAddr = addr < base and addr + base or addr

	local desc = description or ("Patch at " .. string.format("0x%08X", addr))

	local patch = {
		addr = shiftedAddr,
		oldValue = memory.readUByte(shiftedAddr),
		newValue = value,
		description = desc,
	}

	self.patches[shiftedAddr] = patch

	memory.writeUByte(shiftedAddr, value)
end

---@param addr number
---@param values table<number>
---@param description string?
function PatchSet:writeBytes(addr, values, description)
	if type(values) ~= "table" then
		return
	end
	for byte = 1, #values do
		local value = values[byte]
		if type(value) ~= "number" then
			error(
				"Entered value is not a number | patchSet "
					.. self.name
					.. " / "
					.. description
					.. ": "
					.. tostring(value),
				2
			)
			break
		end

		self:writeByte(addr + byte - 1, value, description)
	end
end

---@param set JPXSPatchSet | string
function PatchSet.revert(set)
	if type(set) == "string" then
		local patchSet = PatchSet.get(set)
		if not patchSet then
			error("PatchSet '" .. set .. "' does not exist.", 2)
			return
		end
		---@cast patchSet
		set = patchSet
	end

	for _, patch in pairs(self.patches) do
		if patch.oldValue ~= nil then
			memory.writeUByte(patch.addr, patch.oldValue)
		end
	end
	PatchSet.patches = {}
end

function PatchSet.get(name)
	if not PatchSet.patches then
		return nil
	end

	return PatchSet.patches[name]
end

function PatchSet.revertAll()
	if not PatchSet.patches then
		return
	end

	for _, patchSet in pairs(PatchSet.patches) do
		patchSet.revert()
	end
end

return {
	export = PatchSet,
}
