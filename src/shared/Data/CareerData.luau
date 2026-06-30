local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local Net = require(ReplicatedStorage.Packages.Net)
local Util = require(StarterPlayer.StarterPlayerScripts.Client.Util)

local PlayerCareer = {
	-- combat
	Weapon_Shots = 0,
	Rifle_Shots = 0,
	Heavy_Rifle_Shots = 0,
	Pistol_Shots = 0,
	Heavy_Pistol_Shots = 0,
	Suppressed_Pistol_Shots = 0,
	Shotgun_Shots = 0,

	Damage_Taken = 0,
	Damage_Healed = 0,
	Damage_Delt = 0,
	Deaths = 0,

	Enemies_Killed = 0,

	-- World
	Objects_Hacked = 0,
	Objects_Used = 0,

	Distance_Walked = 0,
	Distance_Sprinted = 0,

	-- Inventory
	Items_Consumed = 0,
	Items_Dropped = 0,
	Items_Picked_Up = 0,

	-- Game
	Campaigns_Begun = 0,
	Campaigns_Saved = 0,
}

local SYNC_INTERVAL = 6

local SyncedCareer = {}
local lastSyncAttempt = os.clock()

local function loadCareer()
	local careerData = Net:RemoteFunction("LoadCareer"):InvokeServer()
	if not careerData then
		return
	end

	for index, value in pairs(careerData) do
		PlayerCareer[index] = value
	end

	for index, value in pairs(careerData) do
		SyncedCareer[index] = value
	end
end

loadCareer()

RunService.Heartbeat:Connect(function()
	if os.clock() - lastSyncAttempt < SYNC_INTERVAL then -- return if the time has not been reached
		return
	end

	lastSyncAttempt = os.clock() -- restart timer

	if Util.DeepCompare(PlayerCareer, SyncedCareer) then -- check if anything has changed
		return
	end

	for index, value in pairs(PlayerCareer) do
		SyncedCareer[index] = value
	end -- if something has changed fire the changes.
	Net:RemoteEvent("SyncCareer"):FireServer(PlayerCareer) -- sync the career (Can be fired from anywhere for important sync)
end)

return PlayerCareer
