local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Controllers = ReplicatedStorage.Shared.Services.Controllers

local AvatarController = require(Controllers.AvatarController)
local CameraController = require(Controllers.CameraController)
local UIController = require(Controllers.UIController)

local function Init()
	AvatarController:Init()
	CameraController:Init()
	UIController:Init()
end

local function Start()
	AvatarController:Start()
end

local function LoadGame(gameSave)
	local avatar = AvatarController:Load(gameSave)
end

Init()
Start()
LoadGame()
