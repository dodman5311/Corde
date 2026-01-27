-- !strict
export type PlayerState = {
	Avatar: Instance?,

	Hunger: number,
	MaxHunger: number,

	AllowedEnterNet: boolean,
	AllowedSprint: boolean,
	AllowedInteract: boolean,
	AllowedMove: boolean,

	IsSprinting: boolean,
	IsWeaponReady: boolean,
	IsDoingAction: string?,
}

return {}
