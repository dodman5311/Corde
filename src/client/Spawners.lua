local CollectionService = game:GetService("CollectionService")
local module = {}

local client = script.Parent
local NpcService = require(client.NpcService)

function module:SpawnFromSpawner(spawner: Part)
	if spawner:GetAttribute("SpawnType") == "Npc" then
		NpcService.new(spawner:GetAttribute("ToSpawn")):Spawn(spawner.CFrame)
	end
end

function module.OnSpawn(character: Model)
	for _, spawner: Part in ipairs(CollectionService:GetTagged("SpawnPoint")) do
		local gui = spawner:FindFirstChildOfClass("SurfaceGui")
		if gui then
			gui:Destroy()
		end

		spawner.Transparency = 1

		module:SpawnFromSpawner(spawner)
	end
end

return module
