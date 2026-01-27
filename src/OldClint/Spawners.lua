local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local module = {}

local client = script.Parent
local NpcService = require(client.NpcService)
local Types = require(ReplicatedStorage.Shared.Types)

function module:SpawnFromSpawner(spawner: Part)
	if spawner:GetAttribute("SpawnType") == "Npc" then
		NpcService.new(spawner:GetAttribute("ToSpawn")):Spawn(spawner.CFrame)
	end
end

function module:SpawnFromData(name: string, position: Vector3, direction: number, health: number)
	NpcService.new(name):Spawn(CFrame.new(position) * CFrame.Angles(0, direction, 0)):SetAttribute("Health", health)
end

function module.StartGame(saveData: Types.GameState)
	if saveData then
		for _, data in ipairs(saveData.Layers[saveData.CurrentLayerIndex].Npcs) do
			module:SpawnFromData(data.Name, data.Position, data.Direction, data.Health)
		end
	end

	for _, spawner: Part in ipairs(CollectionService:GetTagged("SpawnPoint")) do
		if saveData then
			spawner:Destroy()
			continue
		end

		if not spawner:FindFirstAncestor("Workspace") then
			continue
		end

		local gui = spawner:FindFirstChildOfClass("SurfaceGui")
		if gui then
			gui:Destroy()
		end

		spawner.Transparency = 1

		module:SpawnFromSpawner(spawner)
	end
end

return module
