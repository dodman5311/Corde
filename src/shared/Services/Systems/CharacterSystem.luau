local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterSystem = {}

type CharacterConfig = {
	Name: string,

	IsHumanoid: boolean,
	TurnSpeed: number,
	MaxHealth: number,
}

type CharacterState<T = { any }> = {
	MovementDirection: Vector2,
	LookDirection: Vector2,
	IsAlive: boolean,

	MaxHealth: number,
	Health: number,

	Context: T,
}

type Character = {
	Config: CharacterConfig,
	State: CharacterState,

	Instance: Model,

	PlayAnimation: (self: Character, animationName: string) -> any?,
	StopAnimation: (self: Character, animationName: string) -> any?,
	GetAnimation: (self: Character, animationName: string) -> any?,

	Spawn: (self: Character, spawnLocation: Vector2) -> any?,
	Run: (self: Character) -> any?,
	Stop: (self: Character) -> any?,
	Destroy: (self: Character) -> any?,
}

--// Services

--// Instances

--// Modules

--// Values

local DEFAULT_CHARACTER_CONFIG: CharacterConfig = {
	Name = "Placeholder",
	IsHumanoid = true,
	TurnSpeed = 1,
	MaxHealth = 100,
}

local DEFAULT_CHARACTER_STATE = {}

--// Functions

function CharacterSystem:Init() end

function CharacterSystem:Start() end

local function OnTableChanged<K, V>(proxy: { [K]: V }): { [K]: V }
	return setmetatable(proxy, {
		__newindex = function(table, key, newValue)
			local oldValue = table[key]

			if oldValue == newValue then
				return
			end

			rawset(proxy, key, newValue)
		end,
	}) :: any
end

function CharacterSystem.new(characterName: string, characterModel: Model): Character
	local newModel = characterModel:Clone()
	newModel.Name = characterName

	local newCharacter: Character = {
		Config = DEFAULT_CHARACTER_CONFIG,
		State = {
			MovementDirection = Vector2.zero,
			LookDirection = Vector2.zero,
			IsAlive = true,
			Health = DEFAULT_CHARACTER_CONFIG.MaxHealth,
			Context = {},
		},

		Instance = newModel,

		PlayAnimation = function(self: Character, animationName: string) end,
		StopAnimation = function(self: Character, animationName: string) end,
		GetAnimation = function(self: Character, animationName: string) end,

		Spawn = function(self: Character, spawnLocation: Vector2) end,
		Run = function(self: Character) end,
		Stop = function(self: Character) end,
		Destroy = function(self: Character) end,
	}

	return newCharacter
end

--// Main //--
return CharacterSystem
