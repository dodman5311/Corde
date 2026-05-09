local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local module = {}

local client = script.Parent
local NpcService = require(client.NpcService)
local Types = require(ReplicatedStorage.Shared.Types)

function module:SpawnFromSpawner(layerKey: string, spawner: Part)
	local layer = ReplicatedStorage.Layers:FindFirstChild(layerKey)
	if not layer then
		return
	end

	if spawner:GetAttribute("SpawnType") == "Npc" then
		local newNpc = NpcService.new(spawner:GetAttribute("ToSpawn"))
		newNpc:Place(spawner.CFrame, layer)
	end
end

function module:SpawnFromData(layerKey, name: string, position: Vector3, direction: number, health: number)
	local layer = ReplicatedStorage.Layers:FindFirstChild(layerKey)
	if not layer then
		return
	end

	local newNpc = NpcService.new(name)
	local npcPosition = CFrame.new(position) * CFrame.Angles(0, direction, 0)
	newNpc:Place(npcPosition, layer)
	newNpc.Instance:SetAttribute("Health", health)
end

function module:SpawnLayerNpcs(layerKey: string)
	for _, spawner: Part in ipairs(CollectionService:GetTagged("SpawnPoint")) do
		if not spawner:FindFirstAncestor(layerKey) then
			continue
		end

		self:SpawnFromSpawner(layerKey, spawner)
		spawner:Destroy()
	end
end

local function hideSpawners()
	for _, spawner: Part in ipairs(CollectionService:GetTagged("SpawnPoint")) do
		local gui = spawner:FindFirstChildOfClass("SurfaceGui")
		if gui then
			gui:Destroy()
		end

		spawner.Transparency = 1
	end
end

function module.StartGame(saveData: Types.GameState)
	if saveData then
		for layerKey, layerData: Types.LayerData in pairs(saveData.Layers) do
			-- if the layer has no NPC data, it hasn't been loaded yet
			if #layerData.Npcs == 0 then
				continue
			end

			-- spawn npcs from data
			for _, npcData in ipairs(layerData.Npcs) do
				module:SpawnFromData(layerKey, npcData.Name, npcData.Position, npcData.Direction, npcData.Health)
			end

			-- remove layer spawn points if npcs have been loaded already
			for _, spawner: Part in ipairs(CollectionService:GetTagged("SpawnPoint")) do
				if spawner:FindFirstAncestor(layerKey) then
					spawner:Destroy()
				end
			end
		end
	end

	hideSpawners()
end

return module
