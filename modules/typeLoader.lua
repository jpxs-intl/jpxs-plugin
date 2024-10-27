---@type Core
local Core = ...

http.get(Core.assetHost.host, Core.assetHost.path .. "types.lua", {}, function(response)
	if response and response.status == 200 then
		local content = Core.addFileHeader(response.body, "jpxs.types")
		local path = ".meta/template/"
		os.createDirectory(path)
		local file = io.open(path .. "jpxs.types.lua", "w")
		if not file then
			Core:debug("Failed to write types")
			return
		end

		file:write(content)
	else
		Core:debug(string.format("Failed to download types (%s)", response and response.status or "no response"))
	end
end)
