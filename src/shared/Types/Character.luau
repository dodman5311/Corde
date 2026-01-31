local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)
local SpriteSheetAnimator = require(ReplicatedStorage.Shared.Services.Components.SpriteSheetAnimator)

local Assets = ReplicatedStorage.Assets
local Models = Assets.Models

export type CharacterConfig = {
	Name: string,

	IsHumanoid: boolean,
	TurnSpeed: number,
	FrameRate: number,

	MaxHealth: number,
	Health: number,
}

export type CharacterState = CharacterConfig & {
	MovementDirection: Vector2,
	LookDirection: Vector2,
	IsAlive: boolean,
}

export type CharacterInstance = typeof(Models.CharacterTemplate)

export type Character = {
	State: CharacterState,
	Context: { any },

	Instance: CharacterInstance,

	PlayAnimation: (
		self: Character,
		animationName: string,
		frameDelay: number?,
		loop: boolean?,
		stayOnLastFrame: boolean?,
		startOnFrame: number?
	) -> SpriteSheetAnimator.Animation2D?,

	StopAnimation: (self: Character, animationName: string) -> nil,
	GetAnimation: (self: Character, animationName: string) -> (Frame?, SpriteSheetAnimator.Animation2D?),

	Spawn: (self: Character, spawnLocation: Vector2) -> any?,
	Run: (self: Character) -> any?,
	Stop: (self: Character) -> any?,
	Destroy: (self: Character) -> any?,

	OnDied: Signal.Signal<>,
	OnHealthChanged: Signal.Signal<number>,
	OnMovementChanged: Signal.Signal<Vector2>,
}

return {}
