local AvatarController = {}

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Instances
local Assets = ReplicatedStorage.Assets
local Player = Players.LocalPlayer

--// Modules
local AvatarConfig = require(ReplicatedStorage.Shared.Config.Avatar)
local CharacterSystem = require(ReplicatedStorage.Shared.Services.Systems.CharacterSystem)
local CharacterTypes = require(ReplicatedStorage.Shared.Types.Character)
local InputSystem = require(ReplicatedStorage.Shared.Services.Systems.InputSystem)

--// Values
local movementKeyDirections = {
	W = Vector2.new(0, -1),
	A = Vector2.new(-1, 0),
	S = Vector2.new(0, 1),
	D = Vector2.new(1, 0),
}

--// Functions
local function CreateCharacter(): CharacterTypes.Character
	return CharacterSystem.new(Assets.Models.Avatar, AvatarConfig)
end

local function connectMovement(avatar: CharacterTypes.Character)
	InputSystem:ConnectToAction(
		InputSystem.InputActions.Sprint,
		function(inputState: Enum.UserInputState, input: InputObject): any?
			if inputState == Enum.UserInputState.Begin then
				avatar.State.WalkSpeed = AvatarConfig.WalkSpeed + 10
			elseif inputState == Enum.UserInputState.End then
				avatar.State.WalkSpeed = AvatarConfig.WalkSpeed
			end
			return
		end
	)

	InputSystem:ConnectToAction(
		InputSystem.InputActions["Move Player"],
		function(inputState: Enum.UserInputState, input: InputObject): any?
			if inputState == Enum.UserInputState.Begin then
				if movementKeyDirections[input.KeyCode.Name] then
					avatar.State.MovementDirection += movementKeyDirections[input.KeyCode.Name]
					--avatar.State.LookDirection = movementKeyDirections[input.KeyCode.Name]
				end
			elseif inputState == Enum.UserInputState.End then
				if movementKeyDirections[input.KeyCode.Name] then
					avatar.State.MovementDirection -= movementKeyDirections[input.KeyCode.Name]
					--avatar.State.LookDirection = Vector2.zero
				end
			end

			return
		end
	)
end

function AvatarController:Load(gameSave): CharacterTypes.Character
	local avatar = CreateCharacter()
	avatar:Spawn(Vector2.zero)
	Player.Character = avatar.Instance

	connectMovement(avatar)

	return avatar
end

function AvatarController:Init()
	--Prestart Code
end

function AvatarController:Start()
	CharacterSystem:Start()
	--Start Code
end

--// Main //--
return AvatarController
