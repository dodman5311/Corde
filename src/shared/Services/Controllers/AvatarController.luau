local CharacterController = {}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Instances
local Assets = ReplicatedStorage.Assets

--// Modules
local AvatarConfig = require(ReplicatedStorage.Shared.Config.Avatar)
local CharacterSystem = require(ReplicatedStorage.Shared.Services.Systems.CharacterSystem)
--local MovementSystem = require(ReplicatedStorage.Shared.Services.Systems.MovementSystem)

--// Values

--// Functions
local function CreateCharacter(position: Vector2)
	CharacterSystem.new("Avatar", Assets.Models.Avatar, AvatarConfig)
end

function CharacterController:Load(gameSave)
	CreateCharacter(Vector2.zero)
end

function CharacterController:Init()
	--Prestart Code
end

function CharacterController:Start()
	--Start Code
end

--// Main //--
return CharacterController
