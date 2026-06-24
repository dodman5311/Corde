local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Pathfinder = require(script.Parent.Pathfinder)
local Timer = require(StarterPlayer.StarterPlayerScripts.Client.Timer)

export type LayerData = {
	Npcs: {
		{
			Name: string,
			Position: { X: number, Y: number, Z: number },
			Direction: number,
			Health: number,
		}
	},

	Containers: { { Name: string, Position: { X: number, Y: number, Z: number }, Contents: {} } },
	Objects: {
		{
			Name: string,
			Position: { X: number, Y: number, Z: number },
			Locked: boolean?,
			Used: boolean?,
			Tags: { string },
		}
	},
}

export type GameState = {
	Date: string,
	PlayTime: number,
	Area: string,
	CurrentLayerKey: string,
	Difficulty: number,

	PlayerStats: {
		Position: { X: number, Y: number, Z: number },
		HasNet: boolean,
		Health: number,
		Hunger: number,
		Inventory: {},
	},

	Layers: { LayerData },
	GameData: { [string]: any },
}

export type npcPersonality = {
	[string]: { { Function: string, Parameters: { any }?, Conditions: { Invert: boolean?, [string]: any }? } },
}

export type Setting = {
	Name: string,
	Type: "Slider" | "List" | "KeyInput",
	Value: any,
	Default: any?,
	Values: any?,
	OnChanged: (self: Setting) -> any?,
}

export type Npc = {
	Name: string,
	Instance: Model,
	Personality: {},
	MindData: { [string]: any? }, -- extra data the npc might need
	MindState: {
		Current: StringValue,
		Last: string,
	},
	MindTarget: ObjectValue,

	Heartbeat: { [string]: any? },

	Path: Pathfinder.State,
	Timer: Timer.TimerQueue,
	Timers: { [string]: Timer.Timer },
	Acts: {},
	Janitor: Janitor.Janitor,
	OnDied: any?,
	IsRunning: boolean,

	Spawn: (Npc: Npc, Position: Vector3 | CFrame) -> Npc,

	IsState: (Npc: Npc, State: string) -> boolean,
	GetState: (Npc: Npc) -> string,
	GetTarget: (Npc: Npc) -> any?,
	GetTimer: (Npc: Npc, TimerName: string) -> Timer.Timer,

	Exists: (Npc: Npc) -> boolean,

	Destroy: (Npc: Npc) -> nil,
	Place: (Npc: Npc, Position: Vector3 | CFrame, Parent: Instance?) -> Instance,
	Run: (Npc: Npc) -> nil,
	Stop: (Npc: Npc) -> nil,
}

export type ItemType = "Weapon" | "Equipment" | "Resource" | "Item" | "Note"

export type ItemReference = {
	Key: string,
	State: { [string]: any }?,
}

export type Item = {
	Key: string?,
	ItemType: ItemType,
	Name: string,
	IconId: number,
	Desc: string,

	UseAction: string,
	CanDrop: boolean,

	Config: { [string]: any },
	State: {
		[string]: any,
	},
	CombineData: {
		[string]: any,
	}?,
}

export type weaponData = {
	Type: number,
	RateOfFire: number,
	FireSound: string,
	Volume: number,
	ReloadSound: string,
	ReloadTime: number,
	Damage: number,
	BulletCount: number,
	CurrentMag: item?,
	FireMode: number,
	Spread: number,
	StoppingPower: number,

	Recoil: number,
	DisplayImage: string,
}

export type weapon = Item & {
	Config: weaponData,
}

export type WorldSpaceGui = {
	Name: string,
	Base: Part,
	Sway: number,
	Enabled: boolean,

	GetFrames: (self: WorldSpaceGui) -> { WorldSpaceFrame },
	AddFrame: (self: WorldSpaceGui, frame: Frame) -> WorldSpaceFrame,
	GetFrame: (self: WorldSpaceGui, frameName: string) -> WorldSpaceFrame?,

	Destroy: (self: WorldSpaceGui) -> any?,
}

export type WorldSpaceFrame = {
	Name: string,
	WorldSpaceGui: WorldSpaceGui,
	Enabled: boolean,

	Base: Part,
	Gui: SurfaceGui,

	GetObject: (self: WorldSpaceFrame, objectName: string) -> GuiObject?,
	TweenObject: (
		self: WorldSpaceFrame,
		object: string,
		tweenInfo: TweenInfo,
		propertyTable: { [string]: any },
		callbackFunction: (() -> any?)?,
		callbackStateCondition: Enum.PlaybackState?
	) -> Tween,
	SetObjectProperties: (
		self: WorldSpaceFrame,
		object: string | { string },
		propertyTable: { [string]: any }
	) -> any?,

	DestroyObject: (self: WorldSpaceFrame, objectName: string) -> any?,

	Destroy: (self: WorldSpaceFrame) -> any?,
}

return {}
