local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterConfig = require(ReplicatedStorage.Shared.Config.Character)
local Types = require(ReplicatedStorage.Shared.Types.PlayerState)

type PlayerState = Types.PlayerState

local function createPlayerState(): PlayerState
	return {
		Position = Vector2.zero,
		Rotation = 0,
		Instance = nil,

		Health = CharacterConfig.MaxHealth,
		MaxHealth = CharacterConfig.MaxHealth,

		Hunger = CharacterConfig.MaxHunger,
		MaxHunger = CharacterConfig.MaxHunger,

		AllowedEnterNet = false,
		AllowedSprint = true,
		AllowedInteract = true,
		AllowedMove = true,

		IsAlive = false,
		IsSprinting = false,
		IsWeaponReady = false,
	}
end

--// Main //--
return createPlayerState()
