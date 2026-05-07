local saveLoad = {}

--// Services
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Instances
local player = Players.LocalPlayer
local Layers = ReplicatedStorage.Layers

--// Modules
local Areas = require(script.Parent.Areas)
local Inventory = require(script.Parent.Inventory)
local Net = require(ReplicatedStorage.Packages.Net)
local NpcFunctions = require(script.Parent.NpcFunctions)
local Types = require(ReplicatedStorage.Shared.Types)

--// Values
local interactables = {} -- Hackable, interest, interactable
local layersData = {}

local function getDataStoreSize(data)
	local size = #HttpService:JSONEncode(data)

	print("Size in bytes:", size)
	print("Size in KB:", size / 1024)
	print("Size in MB:", (size / 1024) / 1000)
end

local function serializeVector3(vector: Vector3)
	return { X = vector.X, Y = vector.Y, Z = vector.Z }
end

local function packInventory()
	local inv = {}

	for i = 1, 25 do
		local item = Inventory["slot_" .. i]
		if not item then
			continue
		end
		inv["slot_" .. i] = { Key = item.Key, State = item.State }
	end

	local weapon = Inventory["Weapon_Slot"]
	if weapon then
		inv["Weapon_Slot"] = { Key = weapon.Key, State = weapon.State }
	end

	return inv
end

local function getInteractables()
	interactables = {}

	for _, object: Instance in ipairs(CollectionService:GetTagged("Interactable")) do
		if object:HasTag("Container") then
			continue
		end

		interactables[object] = object
	end

	for _, object in ipairs(CollectionService:GetTagged("Hackable")) do
		interactables[object] = object
	end

	for _, object in ipairs(CollectionService:GetTagged("Interest")) do
		interactables[object] = object
	end
end

local function checkInLayer(object, layerKey)
	if layerKey == workspace:GetAttribute("CurrentLayerKey") then
		return object:FindFirstAncestor("Map")
	else
		return object:FindFirstAncestor(layerKey)
	end
end

local function saveLayer(layerKey: string)
	layersData[layerKey] = { Npcs = {}, Containers = {}, Objects = {} }

	for _, object in pairs(interactables) do
		if not checkInLayer(object, layerKey) then
			continue
		end

		table.insert(layersData[layerKey].Objects, {
			Name = object.Name,
			Position = serializeVector3(object:GetPivot().Position),
			Locked = object:GetAttribute("Locked"),
			Used = object:GetAttribute("Used"),
			Tags = object:GetTags(),
		})
	end

	for _, npc: Types.Npc in ipairs(NpcFunctions.npcs) do
		local model: Model = npc.Instance
		if not checkInLayer(model, layerKey) then
			continue
		end

		local _, y = model:GetPivot().Rotation:ToOrientation()

		table.insert(layersData[layerKey].Npcs, {
			Name = npc.Name,
			Position = serializeVector3(model:GetPivot().Position),
			Direction = y,
			Health = model:GetAttribute("Health"),
		})
	end

	for _, container in ipairs(CollectionService:GetTagged("Container")) do
		if container:GetAttribute("DroppedAt") or not checkInLayer(container, layerKey) then
			continue
		end

		table.insert(layersData[layerKey].Containers, {
			Name = container.Name,
			Position = serializeVector3(container:GetPivot().Position),
			Contents = require(container.Container),
		})
	end
end

function getGameState(): Types.GameState
	for _, layerFolder in ipairs(Layers:GetChildren()) do
		saveLayer(layerFolder.Name)
	end

	local character = player.Character
	local gameState: Types.GameState = {
		Date = DateTime.now():FormatLocalTime("lll", "en-us"),
		PlayTime = (os.clock() - workspace:GetAttribute("StartTime")) + workspace:GetAttribute("PlayTime"),
		Area = Areas.currentArea and Areas.currentArea.Name or "Unknown",
		CurrentLayerKey = workspace:GetAttribute("CurrentLayerKey"),
		Difficulty = workspace:GetAttribute("Difficulty"),

		PlayerStats = {
			Position = serializeVector3(character:GetPivot().Position),
			Health = character:GetAttribute("Health"),
			Hunger = character:GetAttribute("Hunger"),
			HasNet = character:GetAttribute("HasNet"),
			Inventory = packInventory(),
		},

		Layers = layersData,
	}

	return gameState
end

function saveLoad:SaveGame(saveSlot: number)
	local gameState = getGameState()

	Net:Invoke("SaveGameState", saveSlot, gameState)

	getDataStoreSize(gameState)
	return gameState
end

function saveLoad:ClearSave(saveSlot: number)
	Net:Invoke("SaveGameState", saveSlot, {})
end

function saveLoad:GetSaveData(saveSlot: number)
	return Net:Invoke("GetSavedGame", saveSlot)
end

function saveLoad:LoadGame(saveSlot: number)
	local gameState: Types.GameState = self:GetSaveData(saveSlot)
	layersData = gameState and gameState.Layers or {}
	-- CHANGE SECTION

	getInteractables()

	if gameState then
		for slot, itemReference in pairs(gameState.PlayerStats.Inventory) do
			Inventory[slot] = Inventory:CreateItemFromReference(itemReference)
		end
	end

	return gameState
end

getInteractables()

return saveLoad
