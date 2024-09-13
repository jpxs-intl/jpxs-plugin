---@type Core
local Core = ...

local function cleanVarArgs(...)
	local args = table.pack(...)
	local out = ""

	for i = 1, args.n do
		out = out .. tostring(args[i]) .. " "
	end
end

---@param Client JPXSClient
Core:getDependencies({ "client" }, function(Client)
	hook.add("JPXSLogEvent", "jpxs.log", function(event)
		Client.sendMessage("data", "server:log", {
			message = event,
		})
	end)

	hook.add("JPXSAdminLogEvent", "jpxs.log", function(event)
		Client.sendMessage("data", "server:log", {
			message = event,
			admin = true,
		})
	end)

	-- override the default log functions so we can hook into them

	local oldLog = log

	---@diagnostic disable-next-line: lowercase-global
	function log(...)
		oldLog(...)
		hook.run("JPXSLogEvent", cleanVarArgs(...))
	end

	---@diagnostic disable-next-line: undefined-global
	local oldAdminLog = adminLog

	---@diagnostic disable-next-line: lowercase-global
	function adminLog(...)
		oldAdminLog(...)
		hook.run("JPXSAdminLogEvent", cleanVarArgs(...))
	end
end)
