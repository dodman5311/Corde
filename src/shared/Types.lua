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
	CurrentLayerIndex: string,

	PlayerStats: {
		Position: { X: number, Y: number, Z: number },
		HasNet: boolean,
		Health: number,
		Hunger: number,
		Inventory: {},
		StoreBox: {},
	},

	Layers: { LayerData },
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
	Instance: Instance,
	Personality: {},
	MindData: {}, -- extra data the npc might need
	MindState: StringValue,
	MindTarget: ObjectValue,

	Heartbeat: {},

	Timer: { new: (self: any) -> nil }?,
	Timers: {},
	Acts: {},
	Janitor: any,
	OnDied: any?,

	Spawn: (Npc: Npc, Position: Vector3 | CFrame) -> Instance,

	IsState: (Npc: Npc, State: string) -> boolean,
	GetState: (Npc: Npc) -> string,
	GetTarget: (Npc: Npc) -> any?,
	GetTimer: (Npc: Npc, TimerName: string) -> {},

	Exists: (Npc: Npc) -> boolean,

	Destroy: (Npc: Npc) -> nil,
	Place: (Npc: Npc, Position: Vector3 | CFrame) -> Instance,
	Run: (Npc: Npc) -> nil,
	LoadPersonality: (Npc: Npc) -> nil,
}

export type item = {
	Name: "string",
	Desc: "string",
	Value: any,
	InUse: boolean,
	Icon: "string",
	Use: "Eat" | "Read" | "EquipWeapon" | "Reload",

	CombineData: {}?,
	CanArchive: boolean?,
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

export type weapon = {
	Name: "string",
	Desc: "string",
	Value: weaponData,
	InUse: boolean,
	Icon: "string",
	Use: "EquipWeapon",

	CombineData: {}?,
	CanArchive: boolean?,
}

return {}
