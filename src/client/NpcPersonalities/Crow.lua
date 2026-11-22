local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)

local rifleMax = Items.Rifle_Mag.Config.MaxValue
local pistolMax = Items.Pistol_Mag.Config.MaxValue
local shotgunMax = Items.Shotgun_Mag.Config.MaxValue

local ammo = {
	[Items.Rifle.Name] = { Current = rifleMax, Max = rifleMax },
	[Items.Heavy_Rifle.Name] = { Current = rifleMax, Max = rifleMax },
	[Items.Pistol.Name] = { Current = pistolMax, Max = pistolMax },
	[Items.Suppressed_Pistol.Name] = { Current = pistolMax, Max = pistolMax },
	[Items.Heavy_Pistol.Name] = { Current = pistolMax, Max = pistolMax },
	[Items.Shotgun.Name] = { Current = shotgunMax, Max = shotgunMax },
}

function initAmmo(npc)
	npc.MindData.Ammo = ammo
end

local module: Types.npcPersonality = {
	OnStep = {
		{ Function = "SearchForTarget", Parameters = { 25, 120 } },
		{ Function = "LookAtTarget", Parameters = { true, 0.1 }, Conditions = { GetState = "Attacking" } },
		{
			Function = "LookRandom",
			Parameters = { true, 0.05, NumberRange.new(3, 6) },
			Conditions = { IsState = "Idle" },
		},
		{
			Function = "FireInBursts",
			Parameters = { NumberRange.new(0.1, 0.35), NumberRange.new(0.75, 1.5) },
			Conditions = { GetState = "Attacking" },
		},
	},

	OnTargetFound = {
		{ Function = "EquipWeapon", Parameters = { Items.Pistol } },
		{ Function = "SwitchToState", Parameters = { "Attacking" } },
	},

	OnTargetLost = {
		{ Function = "UnequipWeapon" },
		{ Function = "SwitchToState", Parameters = { "Idle" } },
	},

	Start = {
		{ Function = "Custom", Parameters = { initAmmo } },
		{ Function = "SwitchToState", Parameters = { "Idle" } },
	},

	OnDeath = {
		{ Function = "PlaceNpcBody" },
		{ Function = "Destroy" },
	},
}

return module
