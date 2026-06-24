local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local storeData = {}
local playerCareers = {}

local Types = require(ReplicatedStorage.Shared.Types)

local Net = require(ReplicatedStorage.Packages.Net)
Net:RemoteFunction("SaveGameState")
Net:RemoteFunction("GetSavedGame")
Net:RemoteEvent("ClearAllData")

local function deserializeVector3(tbl: { x: number, y: number, z: number }): Vector3
	return Vector3.new(tbl.X, tbl.Y, tbl.Z)
end

local function LoadData(player: Player, dataStore: DataStore): Types.GameState? -- load data
	local foundData

	local success, errorMessage = pcall(function()
		foundData = dataStore:GetAsync(player.UserId .. "_GameState")
	end)
	if not success then
		warn("Failed to load " .. dataStore.Name, errorMessage)
		return
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

local function savePlayerSettings(player: Player, SettingsData)
	local settingsDataStore = DataStoreService:GetDataStore("Settings")
	SaveData(player, settingsDataStore, SettingsData)
end

local function savePlayerCareer(player: Player)
	local career = playerCareers[player] or {}

	local careerDataStore = DataStoreService:GetDataStore("Career")
	SaveData(player, careerDataStore, career)
end

local function syncPlayerCareer(player: Player, CareerData)
	playerCareers[player] = CareerData
end

local function getPlayerCareer(player: Player)
	local dataStore = DataStoreService:GetDataStore("Career")
	local career = LoadData(player, dataStore)

	if not career then
		return
	end

	syncPlayerCareer(player, career)
end

local function loadPlayerCareer(player: Player)
	return playerCareers[player]
end

local function getSavedGame(player: Player, saveSlot: number): Types.GameState?
	local dataStore = DataStoreService:GetDataStore("Slot_" .. saveSlot)
	local data: Types.GameState? = LoadData(player, dataStore)

	if not data or not data.Date then
		return
	end

	data.PlayerStats.Position = deserializeVector3(data.PlayerStats.Position)

	if not data.Layers then
		return
	end

	for _, layer in pairs(data.Layers) do
		for _, container in ipairs(layer.Containers) do
			container.Position = deserializeVector3(container.Position)
		end

		for _, object in ipairs(layer.Objects) do
			object.Position = deserializeVector3(object.Position)
		end

		for _, npc in ipairs(layer.Npcs) do
			npc.Position = deserializeVector3(npc.Position)
		end
	end

	return data
end

local function clear(player: Player)
	for slot = 0, 2 do
		saveGameState(player, slot, {})
	end
end

Net:Handle("GetSavedGame", getSavedGame)
Net:Handle("SaveGameState", saveGameState)
Net:Handle("LoadCareer", loadPlayerCareer)
Net:Connect("SyncCareer", syncPlayerCareer)
Net:Connect("ClearAllData", clear)

Players.PlayerRemoving:Connect(savePlayerCareer) -- save player career when leaving
Players.PlayerAdded:Connect(getPlayerCareer) -- load player career when joining

return storeData
