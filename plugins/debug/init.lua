---@type JPXSPlugin
local plugin = ...

plugin.name = "Debug"
plugin.author = "max"
plugin.description = "Debugging tools for JPXS"

plugin:addEnableHandler(function()
	if not jpxs.debugEnabled then
		jpxs.debugEnabled = true

		-- create a debug.lock file to indicate that debugging is enabled
		local file = io.open(jpxs.storagePath .. "debug.lock", "w")
		if file then
			file:write(
				"This file indicates that debugging is enabled.\nTo disable debugging, run `jpxs plugin disable debug`\n"
			)
			file:close()
		else
			plugin:error("Failed to create debug.lock file. Debugging may not work as expected.")
		end
	end
end)

plugin:addDisableHandler(function()
	-- remove the debug.lock file
	local file = io.open(jpxs.storagePath .. "debug.lock", "r")

	if file then
		file:close()
		os.remove(jpxs.storagePath .. "debug.lock")
	end

	jpxs.debugEnabled = false
end)

-- plugin:getDependencies({ "networking" })
