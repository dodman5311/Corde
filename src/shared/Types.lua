export type GameState = {
	Date: string,
	PlayTime: number,
	Area: string,

	PlayerStats: {
		Position: { X: number, Y: number, Z: number },
		HasNet: boolean,
		Health: number,
		Hunger: number,
		Inventory: {},
	},

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

return {}
