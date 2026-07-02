local module = {
	lastArea = nil :: Part?,
	currentArea = nil :: Part?,
}
--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local collectionService = game:GetService("CollectionService")
local players = game:GetService("Players")
local runService = game:GetService("RunService")

--// Instances
local player = players.LocalPlayer
local areas = {}

--// Modues
local Achievements = require(script.Parent.Achievements)
local AttributeEffects = require(script.Parent.AttributeEffects)
local GlobalEvents = require(ReplicatedStorage.Shared.GlobalEvents)
local Util = require(script.Parent.Util)

--// Values

--// Functions

local function CheckForEchoAchievement(part)
	if part.Name == "EchoChamber" then
		Achievements:AwardAchievement(Achievements.Ids.SomethingWrong)
	end
end

local function onAreaEntered(areaPart: Part)
	if not areaPart then
		return
	end

	AttributeEffects.DoEffects(areaPart)

	GlobalEvents.React.AreaEntered:Fire(areaPart)
	CheckForEchoAchievement(areaPart)
end

local function onAreaLeft(areaPart: Part)
	GlobalEvents.React.AreaLeft:Fire(areaPart)
end

local function setUpAreaParts()
	for _, part: Part in ipairs(areas) do
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

	for _, part in ipairs(areas) do
		if not part:FindFirstAncestor("Workspace") then
			continue
		end
		local partsInBox = workspace:GetPartBoundsInBox(part.CFrame, part.Size)

		if not table.find(partsInBox, character.PrimaryPart) then
			continue
		end

		module.currentArea = part
	end

	if module.currentArea ~= module.lastArea then
		onAreaLeft(module.lastArea)
		onAreaEntered(module.currentArea)
	end

	module.lastArea = module.currentArea
end

function module.Init()
	areas = collectionService:GetTagged("Area")
	setUpAreaParts()
end

--// Main //--
runService.Heartbeat:Connect(onHeartbeat)

return module
