---@type Core
local Core = ...

local path = Core.storagePath .. "README.txt"

local content = [[JPXS 

please don't mess with any of this, other than config.json 
it's literally months of work here and I don't want it fucking with something on the server.

thanks, 
gart                                                  

p.s. I've added this folder to your .gitignore if you had one :3]]

local f = io.open(path, "w")
if f then
	f:write(content)
	f:close()
end