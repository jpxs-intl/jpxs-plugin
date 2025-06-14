---@type JPXSPlugin
local plugin = ...

plugin:warn("################################################################################")
plugin:warn("WARNING: SUPER EARLY ANTI-CHEAT PLUGIN!!! WILL BREAK SHIT!!! USE WITH CAUTION!!!")
plugin:warn("################################################################################")

local cons = {}
local restore = {}

local Vector = _G.Vector

local pairs, humans, humans_getAll, lineIntersectLevel, readInt, readVector, base, getAddress =
	_G.pairs,
	_G.humans,
	_G.humans.getAll,
	_G.physics.lineIntersectLevel,
	memory.readInt,
	memory.readVector,
	memory.getBaseAddress(),
	memory.getAddress

local materialID = base + 0x569ef78c
--^^ This should be added to rosaserver as "raycast.materialType"

local calcBoundingBox = function(man)
	local humanBaseAddress = getAddress(man)
	local min, max = readVector(humanBaseAddress + 0x104), readVector(humanBaseAddress + 0x110)
	--                                                  ^^ boundingBoxCornerA                        ^^ boundingBoxCornerB
	local corners = {
		Vector(min.x, min.y, min.z),
		Vector(min.x, min.y, max.z),
		Vector(min.x, max.y, min.z),
		Vector(min.x, max.y, max.z),
		Vector(max.x, min.y, min.z),
		Vector(max.x, min.y, max.z),
		Vector(max.x, max.y, min.z),
		Vector(max.x, max.y, max.z),
	}
	return corners
end

local function intersectLevelWrap(posA, posB)
	local ray = lineIntersectLevel(posA, posB, false)
	if ray and ray.hit ~= true then
		return true
	elseif ray.hit and readInt(materialID) == 12 then --magic numbers.
		local offset = ray.pos - posA
		offset:normalize()
		return intersectLevelWrap(ray.pos + (offset * 0.25), posB)
	end
end

plugin:addHook("PostLogic", function()
	cons = {}
	restore = {}
	local humansGetAll = humans_getAll()
	for _, man in pairs(humansGetAll) do
		local ply = man.player
		if ply ~= nil and ply.connection then
			cons[ply.index] = {}
			local conTab = cons[ply.index]
			--Faster to use bone, getRigidBody uses getBone & then more overhead
			local head = man:getBone(3)
			local posA = head.pos
			local posB = head.pos + (head.rot:forwardUnit() * 0.25)
			for _, man2 in pairs(humansGetAll) do
				local ind = man2.index
				if man2 == man then
					conTab[ind] = true
					goto continue
				end
				local distA, distB = man2.pos:dist(posA), man2.pos:dist(posB)
				if distB < distA and distA < 768 then --Originally had this at 1024, the round map lengthwise is like 1200,
					local corners = calcBoundingBox(man2)
					local doShow = false
					for _, pos in pairs(corners) do
						if intersectLevelWrap(posA, pos) then
							doShow = true
							break
						end
					end
					if distA < 4 then
						doShow = true
					end
					conTab[ind] = doShow
				else
					conTab[ind] = false
				end
				::continue::
			end
		end
		restore[man.index] = true
	end
end)

local lastCon
plugin:addHook("PacketBuilding", function(con)
	if lastCon == con then
		return
	end
	lastCon = con
	local conPly = con.player
	if conPly == nil then
		return
	end
	local conTab = cons[conPly.index]
	if conTab == nil then
		return
	end
	for ind, bool in pairs(conTab) do
		humans[ind].isActive = bool
	end
end)

plugin:addHook("PostServerReceive", function()
	if restore == nil then
		return
	end
	for ind, _ in pairs(restore) do
		humans[ind].isActive = true
	end
	restore = nil
end)
