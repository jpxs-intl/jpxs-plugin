---@type Core
local Core = ...

local path = Core.storagePath
os.createDirectory(path)

local workers = {
	"tcp",
}

---@class WorkerLoader
local WorkerLoader = {}

---@param worker string
---@param cb? fun()
function WorkerLoader.load(worker, cb)
	local workerPath = path .. worker .. ".worker.lua"
	http.get(Core.assetHost.host, Core.assetHost.path .. "workers/" .. worker .. ".worker.lua", {}, function(res)
		if res and res.status == 200 then
			local file = io.open(workerPath, "w")
			if not file then
				Core:debug("Failed to write worker " .. worker)
				return
			end
			file:write(Core.addFileHeader(res.body, worker .. ".worker"))
			file:close()

			Core:debug("Downloaded worker " .. worker)
			if cb then
				cb()
			end
		else
			Core:debug("Failed to download worker " .. worker .. " (" .. (res and res.status or "no response") .. ")")
		end
	end)
end

---@param cb? fun()
function WorkerLoader.loadWorkers(cb)
	WorkerLoader.loadGitIgnore()

	local function checkComplete()
		for _, worker in pairs(workers) do
			local f = io.open(path .. worker .. ".worker.lua", "r")
			if not f then
				Core:debug("Worker " .. worker .. " not loaded")
				return
			end

			f:close()
			Core:debug("Worker " .. worker .. " loaded")
		end

		Core:debug("All workers loaded")
		if cb then
			cb()
		end
	end
	
	for _, worker in pairs(workers) do
		WorkerLoader.load(worker, checkComplete)
	end
end

function WorkerLoader.loadGitIgnore()
	local fileRead = io.open(".gitignore", "r")
	if fileRead then
		local content = fileRead:read("*a")
		if content:find(".jpxs/") then
			fileRead:close()
			return
		end
		fileRead:close()
	end

	local file = io.open(".gitignore", "a")
	if not file then
		Core:debug("Failed to write .gitignore")
		return
	end

	file:write("\n.jpxs/")
	file:close()
end

return WorkerLoader