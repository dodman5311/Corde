local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local storeData = {}

local Types = require(ReplicatedStorage.Shared.Types)

local Net = require(ReplicatedStorage.Packages.Net)
Net:RemoteFunction("SaveGameState")
Net:RemoteFunction("GetSavedGame")

local function deserializeVector3(tbl: { x: number, y: number, z: number }): Vector3
	return Vector3.new(tbl.X, tbl.Y, tbl.Z)
end

local function LoadData(player: Player, dataStore: DataStore): Types.GameState -- load data
	local foundData

	local success, errorMessage = pcall(function()
		foundData = dataStore:GetAsync(player.UserId .. "_GameState")
	end)
	if not success then
		warn("Failed to load " .. dataStore.Name, errorMessage)
	else
		return foundData
	end
end

local function SaveData(player: Player, dataStore: DataStore, value)
	local success, errorMessage = pcall(function()
		dataStore:SetAsync(player.UserId .. "_GameState", value)
	end)
	if not success then
		if dataStore then
			warn("Failed to save " .. dataStore.Name)
		end

		warn(errorMessage)
	end
end

local function saveGameState(player: Player, saveSlot: number, gameState: Types.GameState)
	local dataStore = DataStoreService:GetDataStore("Slot_" .. saveSlot)
	SaveData(player, dataStore, gameState)
end

local function getSavedGame(player: Player, saveSlot: number): Types.GameState
	local dataStore = DataStoreService:GetDataStore("Slot_" .. saveSlot)
	local data: Types.GameState = LoadData(player, dataStore)

	if not data or not data.Date then
		return
	end

	data.PlayerStats.Position = deserializeVector3(data.PlayerStats.Position)

	for _, container in ipairs(data.Containers) do
		container.Position = deserializeVector3(container.Position)
	end

	for _, object in ipairs(data.Objects) do
		object.Position = deserializeVector3(object.Position)
	end

	for _, npc in ipairs(data.Npcs) do
		npc.Position = deserializeVector3(npc.Position)
	end

	return data
end

Net:Handle("GetSavedGame", getSavedGame)
Net:Handle("SaveGameState", saveGameState)

return storeData
