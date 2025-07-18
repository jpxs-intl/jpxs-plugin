---@type JPXSPlugin
local plugin = ...

plugin.name = "Eval"
plugin.author = "max"
plugin.description = "Overrides the `eval` command because i hate it"

plugin.rsPlugin.commands["eval"] = {
	info = "Evaluate a Lua string.",
	usage = "[code]",
	---@param args string[]
	call = function(args)
		local str = table.concat(args, " ")

		-- check if the string is a single expression (no semicolons or newlines)
		if not str:find("[\n;]") then
			str = "return " .. str
		end

		local f, msg = loadstring(str)

		if not f then
			error(msg)
			return
		end

		local res = f()
		if res ~= nil then
			if type(res) == "table" and _G.inspect then
				res = _G.inspect(res)
			end

			print(res)
		end
	end,
}

plugin:addEnableHandler(function()
	for _, consoleCommands in pairs(hook.plugins) do
		if
			consoleCommands.isEnabled
			and consoleCommands.name == "Console Commands"
			and consoleCommands.commands["eval"]
		then
			consoleCommands.commands["eeval"] = table.clone(consoleCommands.commands["eval"])
			consoleCommands.commands["eval"] = nil
		end
	end
end)

plugin:addDisableHandler(function()
	for _, consoleCommands in pairs(hook.plugins) do
		if
			consoleCommands.isEnabled
			and consoleCommands.name == "Console Commands"
			and consoleCommands.commands["eeval"]
		then
			consoleCommands.commands["eval"] = table.clone(consoleCommands.commands["eeval"])
			consoleCommands.commands["eeval"] = nil
			plugin.rsPlugin.commands["eval"] = nil
		end
	end
end)
