local module = {}
--// Services
local collectionService = game:GetService("CollectionService")
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

--// Instances
local player = players.LocalPlayer
local camera = workspace.CurrentCamera

--// Modues
local client = script.Parent
local cameraService = require(client.Camera)
local util = require(client.Util)
local musicService = require(client.MusicService)

--// Values
local lastAreaEntered
local currentAreaPart
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
		musicService:PlayTrack(trackName)
	end,

	Reverb = function(reverbName)
		SoundService.AmbientReverb = Enum.ReverbType[reverbName]
	end,
}

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

local function onHeartbeaat()
	local character = player.Character
	if not character then
		return
	end

	currentAreaPart = nil

	for _, part in ipairs(collectionService:GetTagged("Area")) do
		local partsInBox = workspace:GetPartBoundsInBox(part.CFrame, part.Size)

		if not table.find(partsInBox, character.PrimaryPart) then
			continue
		end

		currentAreaPart = part
	end

	if currentAreaPart ~= lastAreaEntered then
		onAreaEntered(currentAreaPart)
	end

	lastAreaEntered = currentAreaPart
end

function module.Init()
	setUpAreaParts()
end

--// Main //--
runService.Heartbeat:Connect(onHeartbeaat)

return module
