local ReplicatedStorage = game:GetService("ReplicatedStorage")
local assets = ReplicatedStorage.Assets
local notes = assets.StoredData

Items = {
	Shotgun_Mag = {
		Name = "Shotgun Mag",
		Desc = "Magazine for a shotgun",
		Value = 8,
		InUse = false,
		Icon = "rbxassetid://17429767099",
		Use = "Reload",
		CombineData = {
			["Shotgun Mag"] = {
				Action = "AddValue",
				MaxValue = 8,
			},
		},
	},

	Rifle_Mag = {
		Name = "Rifle Mag",
		Desc = "Magazine for a rifle",
		Value = 30,
		InUse = false,
		Icon = "rbxassetid://17429767099",
		Use = "Reload",
		CombineData = {
			["Rifle Mag"] = {
				Action = "AddValue",
				MaxValue = 30,
			},
		},
	},

	Toolbox = {
		Name = "Toolbox",
		Desc = "Magazine for a rifle",
		Value = 30,
		InUse = false,
		Icon = "rbxassetid://17429767099",
		Use = "Reload",
		CombineData = {
			["Small key"] = {
				Action = "AddItem",
				Item = "Screwdriver",
				Result = "RemoveAll",
			},
		},
	},

	Toolbox_Key = {
		Name = "Small key",
		Desc = "Looks to go to some kind of box",
		Value = nil,
		Icon = "rbxassetid://77384355406607",
		Use = nil,
		InUse = false,
		CombineData = {},
	},

	Screwdriver = {
		Name = "Screwdriver",
		Desc = "A tool for screwing and unscrewing screws",
		Value = nil,
		InUse = false,
		Icon = "rbxassetid://17429767099",
		Use = nil,
		CombineData = {},
	},

	Pistol_Mag = {
		Name = "Pistol Mag",
		Desc = "Magazine for a pistol",
		Value = 10,
		InUse = false,
		Icon = "rbxassetid://17429886486",
		Use = "Reload",
		CombineData = {
			["Pistol Mag"] = {
				Action = "AddValue",
				MaxValue = 10,
			},
		},
	},

	Pistol_Bullets = {
		Name = "Pistol Bullets",
		Desc = "bullets for a pistol",
		Value = 30,
		InUse = false,
		Icon = "rbxassetid://120524406905008",
		Use = nil,
		CombineData = {
			["Pistol Mag"] = {
				Action = "AddValue",
				MaxValue = 10,
				Result = "RemoveOnEmpty",
			},

			["Pistol Bullets"] = {
				Action = "AddValue",
				MaxValue = 10,
				Result = "RemoveOnEmpty",
			},
		},
	},

	Cat_Food = {
		Name = "Cat Food",
		Desc = "Food (+10 Hunger)",
		Value = 10,
		InUse = false,
		Icon = "rbxassetid://125543981396297",
		Use = "Eat",
	},

	PersonalNote = {
		Name = "Personal Note",
		Desc = "A small scuffed note.",
		Value = { Message = require(notes.PersonalNote), Image = "rbxassetid://133550222984676" },
		Icon = "rbxassetid://82487541380359",
		Use = "Read",
		InUse = false,
		CombineData = {},
	},

	RationsPoster = {
		Name = "Rations Poster",
		Desc = "A poster about rations and hunger.",
		Value = { Message = require(notes.RationsPoster), Image = "rbxassetid://111890673888434" },
		Icon = "rbxassetid://82487541380359",
		Use = "Read",
		InUse = false,
		CombineData = {},
	},

	Armory_Key = {
		Name = "Armory Key",
		Desc = "Key for the armory",
		Value = nil,
		Icon = "rbxassetid://77384355406607",
		Use = nil,
		InUse = false,
		CombineData = {},
	},

	Room_103_Key = {
		Name = "Room 103 Key",
		Desc = "Key for room 103",
		Value = nil,
		Icon = "rbxassetid://77384355406607",
		Use = nil,
		InUse = false,
		CombineData = {},
	},

	Console_Key = {
		Name = "Console Room Key",
		Desc = "Key for the console room",
		Value = nil,
		Icon = "rbxassetid://77384355406607",
		Use = nil,
		InUse = false,
		CombineData = {},
	},

	SG550 = {
		Name = "SG550",
		Desc = "Standard issue assault rifle.",
		Value = {
			Type = 1,
			RateOfFire = 700,
			FireSound = "rbxassetid://4334525640",
			Volume = 0.5,
			ReloadSound = "rbxassetid://799968994",
			ReloadTime = 3,
			Damage = 18,
			BulletCount = 1,
			CurrentMag = nil,
			FireMode = 2,
			Spread = 6,
			StoppingPower = 0.1,

			Recoil = 55,
			DisplayImage = "rbxassetid://133886120497836",
		},
		InUse = false,
		Icon = "rbxassetid://74163431732494",
		Use = "EquipWeapon",

		CombineData = {},
	},

	AK_74 = {
		Name = "AK-74",
		Desc = "Heavy Assault Rifle",
		Value = {
			Type = 1,
			RateOfFire = 600,
			FireSound = "rbxassetid://799916696",
			Volume = 1,
			ReloadSound = "rbxassetid://6669540958",
			ReloadTime = 3.5,
			Damage = 20,
			BulletCount = 1,
			CurrentMag = nil,
			FireMode = 2,
			Spread = 7,
			StoppingPower = 0.3,

			Recoil = 65,
			DisplayImage = "rbxassetid://133886120497836",
		},
		InUse = false,
		Icon = "",
		Use = "EquipWeapon",

		CombineData = {},
	},

	Mag_Rag = {
		Name = "Mag-Rag™ 12",
		Desc = "Mag fed, pump action, shotgun.",
		Value = {
			Type = 3,
			RateOfFire = 80,
			FireSound = "rbxassetid://7244956099",
			Volume = 2.5,
			ReloadSound = "rbxassetid://6669540958",
			ReloadTime = 3.5,
			Damage = 8,
			BulletCount = 8,
			CurrentMag = nil,
			FireMode = 1,
			Spread = 18,
			StoppingPower = 0.8,

			Recoil = 90,
			DisplayImage = "rbxassetid://133886120497836",
		},
		InUse = false,
		Icon = "",
		Use = "EquipWeapon",

		CombineData = {},
	},

	M45A1 = {
		Name = "M45A1",
		Desc = "Basic 45. Pistol.",
		Value = {
			Type = 2,
			RateOfFire = 400,
			FireSound = "rbxassetid://5108454724",
			Volume = 0.25,
			ReloadSound = "rbxassetid://8989486210",
			ReloadTime = 2.5,
			Damage = 15,
			BulletCount = 1,
			CurrentMag = nil,
			FireMode = 1,
			Spread = 8,
			StoppingPower = 0.25,

			Recoil = 60,
			DisplayImage = "rbxassetid://79496777132333",
		},
		InUse = false,
		Icon = "rbxassetid://94406546559401",
		Use = "EquipWeapon",

		CombineData = {},
	},
}

function Items.SetValue(item, value: any | "Random", min: number?, max: number?)
	local clone = table.clone(item)

	if value == "Random" then
		clone.Value = math.random(min or 1, max or item.Value)
	else
		clone.Value = value
	end

	return clone
end

return Items
