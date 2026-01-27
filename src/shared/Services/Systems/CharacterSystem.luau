local CharacterSystem = {}

type CharacterConfig = {
	Name: string,

	IsHumanoid: boolean,
	TurnSpeed: number,
}

type CharacterState<T = { any }> = {
	MovementDirection: Vector2,
	LookDirection: Vector2,
	Context: T,
}

type Character = {
	Config: CharacterConfig,
	State: CharacterState,

	Instance: Model,

	PlayAnimation: () -> any,
	StopAnimation: () -> any,
	GetAnimation: () -> any,
}

--// Services

--// Instances

--// Modules

--// Values

--// Functions
function CharacterSystem:Init() end

function CharacterSystem:Start() end

function CharacterSystem.new(characterName: string, characterModel: Model)
	local newModel = characterModel:Clone()
	newModel.Name = characterName
end

--// Main //--
return CharacterSystem
