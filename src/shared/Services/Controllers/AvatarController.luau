local CharacterController = {}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Instances
local Assets = ReplicatedStorage.Assets

--// Modules
local CharacterState = require(ReplicatedStorage.Shared.Services.State.CharacterState)
local MovementSystem = require(ReplicatedStorage.Shared.Services.Systems.MovementSystem)

--// Values

--// Functions

local function CreateCharacterModel(position: Vector2): Model
	local newModel = Assets.Models.Character:Clone()
	newModel:PivotTo(CFrame.new(position.X, 0, position.Y))

	return newModel
end

local function CreateCharacter(position: Vector2)
	CharacterState.Instance = CreateCharacterModel(position)
	CharacterState.IsAlive = true
	MovementSystem.ConnectMovement(CharacterState.Instance)
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
