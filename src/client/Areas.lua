local module = {
	lastArea = nil :: Part?,
	currentArea = nil :: Part?,
}
--// Services
local SoundService = game:GetService("SoundService")
local collectionService = game:GetService("CollectionService")
local players = game:GetService("Players")
local runService = game:GetService("RunService")

--// Instances
local player = players.LocalPlayer
local camera = workspace.CurrentCamera

--// Modues
local client = script.Parent
local Achievements = require(script.Parent.Achievements)
local cameraService = require(client.Camera)
local musicService = require(client.MusicService)
local util = require(client.Util)

--// Values
local shiftTi = TweenInfo.new(3, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)

--// Functions
local attributeEffects = {
	FieldOfView = function(value)
		if value == "Default" then
			value = cameraService.fieldOfView
		end

		util.tween(camera, shiftTi, { FieldOfView = tonumber(value) })
	end,

	Track = function(trackName)
		if
			workspace:GetAttribute("InCombat")
			-- and musicService.playingTrack
			--and musicService.playingTrack.Name == "SuddenDeath"
		then
			return
		end
		musicService:PlayTrack(trackName)
	end,

	Reverb = function(reverbName)
		SoundService.AmbientReverb = Enum.ReverbType[reverbName]
	end,
}

local function CheckForEchoAchievement(part)
	if part.Name == "EchoChamber" then
		Achievements:AwardAchievement(Achievements.Ids.SomethingWrong)
	end
end

local function onAreaEntered(part: Part)
	if not part then
		return
	end

	for attributeName, value in pairs(part:GetAttributes()) do
		local effect = attributeEffects[attributeName]

		if not effect then
			continue
		end

		effect(value)
	end

	CheckForEchoAchievement(part)
end

local function setUpAreaParts()
	for _, part: Part in ipairs(collectionService:GetTagged("Area")) do
		part.Transparency = 1
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Anchored = true
	end
end

local function onHeartbeat()
	local character = player.Character
	if not character then
		return
	end

	module.currentArea = nil

	for _, part in ipairs(collectionService:GetTagged("Area")) do
		local partsInBox = workspace:GetPartBoundsInBox(part.CFrame, part.Size)

		if not table.find(partsInBox, character.PrimaryPart) then
			continue
		end

		module.currentArea = part
	end

	if module.currentArea ~= module.lastArea then
		onAreaEntered(module.currentArea)
	end

	module.lastArea = module.currentArea
end

function module.Init()
	setUpAreaParts()
end

--// Main //--
runService.Heartbeat:Connect(onHeartbeat)

return module
