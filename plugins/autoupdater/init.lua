---@type JPXSPlugin
local plugin = ...

local json = require("main.json")

plugin.name = "AutoUpdater"
plugin.author = "max"
plugin.description = "Keeps RosaServer up to date with a command."

---@class VersionMeta
---@field version string
---@field bundledBy string
---@field date string

---@class JPXSAutoUpdater
local AutoUpdater = {
	path = "/rosaserver",
}

function AutoUpdater.compareSymver(a, b)
	--- check if a and b are valid semantic versions
	if not a or not b or not a:match("^%d+%.%d+%.%d+$") or not b:match("^%d+%.%d+%.%d+$") then
		plugin.core:print("Invalid version format: " .. tostring(a) .. " or " .. tostring(b))
		return nil
	end

	local aParts = a:split(".")
	local bParts = b:split(".")

	for i = 1, math.max(#aParts, #bParts) do
		local aPart = tonumber(aParts[i] or "0")
		local bPart = tonumber(bParts[i] or "0")

		if aPart < bPart then
			return -1
		elseif aPart > bPart then
			return 1
		end
	end

	return 0
end

---@param cb fun(version: VersionMeta)
function AutoUpdater.getLatestVersion(cb)
	plugin.core:httpGet(AutoUpdater.path .. "/latest/info.json", function(response)
		if not response then
			plugin.core:print("Failed to fetch latest version info: " .. (error or "Unknown error"))
			return
		end

		local versionInfo = json.decode(response)
		if not versionInfo or not versionInfo.version then
			plugin.core:print("Invalid version info received.")
			return
		end

		if not versionInfo.bundledBy then
			versionInfo.bundledBy = "Unknown"
		end

		if not versionInfo.date then
			versionInfo.date = tostring(os.date("%Y-%m-%d %H:%M:%S"))
		end
		cb({
			version = versionInfo.version,
			bundledBy = versionInfo.bundledBy,
			date = versionInfo.date,
		})
	end)
end

---@return VersionMeta|nil
function AutoUpdater.getCurrentVersion()
	local versionFilePath = plugin.core.storagePath .. "/version.json"
	local file = io.open(versionFilePath, "r")

	if not file then
		plugin.core:print("No current version file found, assuming no version.")
		return nil
	end

	local content = file:read("*a")
	file:close()

	local versionData = json.decode(content)
	if not versionData or not versionData.version then
		plugin.core:print("Invalid current version file format.")
		return nil
	end

	return {
		version = versionData.version,
		bundledBy = versionData.bundledBy or "Unknown",
		date = versionData.date or tostring(os.date("%Y-%m-%d %H:%M:%S")),
	}
end

---@param version string|nil
---@param cb fun(success: boolean, message: string)
function AutoUpdater.updateToVersion(version, cb)
	version = version or "latest"

	local tempDir = plugin.core.storagePath .. version .. "_temp"

	if os.createDirectory(tempDir) then
		plugin:debug("Created temporary directory: " .. tempDir)
	end

	local url = AutoUpdater.path .. "/" .. version .. "/bundle.zip"

	plugin.core:httpGet(url, function(response)
		if not response then
			cb(false, "Failed to download update: " .. (error or "Unknown error"))
			return
		end

		local zipFilePath = tempDir .. "/update.zip"
		local file = io.open(zipFilePath, "w")
		if not file then
			cb(false, "Failed to create zip file: " .. zipFilePath)
			return
		end

		file:write(response)
		file:close()

		if os.execute("unzip -qq -o " .. zipFilePath .. " -d " .. tempDir) then
			os.remove(zipFilePath)

			local versionFilePath = tempDir .. "/info.json"
			local versionFile = io.open(versionFilePath, "r")
			if not versionFile then
				cb(false, "Version file not found in update package.")
				return
			end

			local versionData = versionFile:read("*a")
			versionFile:close()

			local versionInfo = json.decode(versionData)
			if not versionInfo or not versionInfo.version then
				cb(false, "Invalid version info in update package.")
				return
			end

			-- move files around

			local root = os.getenv("PWD") or "."
			os.execute("mv " .. tempDir .. "/librosaserver.so " .. root .. "/librosaserver.so")
			os.execute("mv " .. tempDir .. "/rosaserversatellite " .. root .. "/rosaserversatellite")
			os.execute("mv " .. tempDir .. "/libluajit.so " .. root .. "/libluajit.so")

			-- version.json goes in the storage path
			os.execute("mv " .. tempDir .. "/info.json " .. plugin.core.storagePath .. "/version.json")
			os.execute("rm -rf " .. tempDir)

			cb(true, versionInfo.version)
		else
			cb(false, "Failed to unzip update.")
		end
	end)
end

plugin:addEnableHandler(function()
	plugin.rsPlugin.commands["update"] = {
		info = "Updates RosaServer to a version.",
		usage = "update [version]",
		call = function(args, cb)
			local version = args[1] or "latest"
			local currentVersion = AutoUpdater.getCurrentVersion()
			AutoUpdater.updateToVersion(version, function(success, newVersion)
				if success then
					if currentVersion then
						plugin:print(
							string.format("Updated from %s to %s (%s)", currentVersion.version, version, newVersion)
						)
						plugin:print("Restart your server to apply the update.")
					else
						plugin:print("Updated to version " .. version)
					end
				else
					plugin:error("Update failed: " .. newVersion)
				end
			end)
		end,
	}

	local currentVersion = AutoUpdater.getCurrentVersion()
	AutoUpdater.getLatestVersion(function(latestVersion)
		if not currentVersion then
			plugin:print("New version available: " .. latestVersion.version)
			plugin:print("Run 'update latest` to update.")
		else
			local comparison = AutoUpdater.compareSymver(currentVersion.version, latestVersion.version)

			if not comparison then
				plugin:error("Failed to compare versions, or you're on a non release version.")
				plugin:print("Current version: " .. currentVersion.version)
				plugin:print("Latest version: " .. latestVersion.version)
				return
			elseif comparison < 0 then
				plugin:print(
					string.format(
						"New version available: %s (Current: %s)",
						latestVersion.version,
						currentVersion.version
					)
				)
				plugin:print("Run 'update latest' to update.")
			elseif comparison == 0 then
				plugin:print("You are already on the latest version: " .. currentVersion.version)
			else
				plugin:print("You are ahead of the latest version: " .. currentVersion.version)
			end
		end
	end)
end)
