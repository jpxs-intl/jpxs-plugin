---@diagnostic disable: deprecated
require("main.util")

---@param message string
local function handleMessage(message)
	local method, scheme, path = ("zss"):unpack(message)

	-- Diagnostics disabled due to language server bug
	---@type HTTPResponse?
	local res
	if method == "POST" then
		local body, contentType = ("ss"):unpack(message)
		---@diagnostic disable-next-line: param-type-mismatch
		res = http.postSync(scheme, path, {}, body, contentType)
	else
		---@diagnostic disable-next-line: param-type-mismatch
		res = http.getSync(scheme, path, {})
	end

	local serialized = ("i1"):pack(res and 1 or 0)

	if res then
		serialized = serialized .. ("ns"):pack(res.status, res.body)
	end

	sendMessage(serialized)
end

while true do
	while true do
		local message = receiveMessage()
		if not message then
			break
		end

		handleMessage(message)
	end

	if sleep(100) then
		break
	end
end
