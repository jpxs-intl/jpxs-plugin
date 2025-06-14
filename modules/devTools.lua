---@type Core
local Core = ...

---@class JPXSDevTools
local DevTools = {}

-- list of jpxs staff members that are allowed do do stuff like view debug info, and reload the plugin
--
-- this does NOT give them admin or mod powers, just access to some dev tools
---@type table<string, boolean>
DevTools.staff = {
	[4040000] = true, -- max (free weekend)
	[6443302] = true, -- max
	[2657364] = true, -- jpsh
	[4040002] = true, -- checkraisefold (free weekend)
	[2565518] = true, -- checkraisefold
}

return {
	export = DevTools,
}
