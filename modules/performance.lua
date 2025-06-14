---@type Core
local Core = ...

---@class JPXSPerformance
local Performance = {}

Performance.tpsInfo = {
	sampleInterval = 100,
	sampleCounter = 0,
	recent = 62.5,
	lastSampleTime = os.realClock(),
}

function Performance.calcTPS(avg, exp, tps)
	return (avg * exp) + (tps * (1 - exp))
end

function Performance:updateTPS()
	Performance.tpsInfo.sampleCounter = Performance.tpsInfo.sampleCounter + 1
	if Performance.tpsInfo.sampleCounter == Performance.tpsInfo.sampleInterval then
		Performance.tpsInfo.sampleCounter = 0

		local now = os.realClock()
		local tps = 1 / (now - Performance.tpsInfo.lastSampleTime) * Performance.tpsInfo.sampleInterval

		Performance.tpsInfo.recent = Performance.calcTPS(
			Performance.tpsInfo.recent,
			1 / math.exp((16 * Performance.tpsInfo.sampleInterval) / 5000),
			tps
		)

		Performance.tpsInfo.lastSampleTime = now
	end
end
---@param Client JPXSClient
Core:getDependencies({ "client" }, function(Client)
	Core.addHook("Logic", "performance", function()
		Performance:updateTPS()

		if server.ticksSinceReset % (Core.config:get("updateInterval") or 300) == 0 then
			Client.sendMessage("data", "server:performance", {
				tps = Performance.tpsInfo.recent,
			})
		end
	end)
end)

return Performance
