--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

--// Instances
local CameraInstance = workspace.CurrentCamera

--// Modules
local Camera = require(script.Parent.Camera)
local GlobalEvents = require(ReplicatedStorage.Shared.GlobalEvents)
local MusicService = require(script.Parent.MusicService)
local Util = require(script.Parent.Util)

--// Values
local shiftTi = TweenInfo.new(3, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)

local attributeEffects = {}

attributeEffects.Effects = {
	FieldOfView = function(value)
		if value == "Default" then
			value = Camera.fieldOfView
		end

		Util.tween(CameraInstance, shiftTi, { FieldOfView = tonumber(value) })
	end,

	Track = function(trackName)
		if
			workspace:GetAttribute("InCombat")
			-- and musicService.playingTrack
			--and musicService.playingTrack.Name == "SuddenDeath"
		then
			return
		end
		MusicService:PlayTrack(trackName)
	end,

	MoveToPoint = function(point: Vector2)
		GlobalEvents.Control.WalkPlayerToPoint:Fire(point)
	end,

	Reverb = function(reverbName)
		SoundService.AmbientReverb = Enum.ReverbType[reverbName]
	end,
	ToxicArea = function(value: boolean)
		local player = Players.LocalPlayer
		local character = player.Character
		if not character then
			return
		end

		character:SetAttribute("InToxicArea", value)
	end,
}

function attributeEffects.DoEffects(instance: Instance)
	for attributeName, value in pairs(instance:GetAttributes()) do
		local effect = attributeEffects.Effects[attributeName]

		if not effect then
			continue
		end

		effect(value)
	end
end

return attributeEffects
