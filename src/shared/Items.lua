local ReplicatedStorage = game:GetService("ReplicatedStorage")
local storedData = require(ReplicatedStorage.Shared.StoredData)

Items = {

	--// Weapons
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

		CanArchive = true,
	},

	SGM600 = {
		Name = "SGM-600",
		Desc = "Heavy Battle Rifle designed to combat UAE's. Fires 2 rounds each shot.", -- unidentified anomalous entities
		Value = {
			Type = 1,
			RateOfFire = 420,
			FireSound = "rbxassetid://113459455743841",
			Volume = 1.25,
			ReloadSound = "rbxassetid://75178331995986",
			ReloadTime = 3,
			Damage = 20,
			UseAmmoForBulletCount = true,
			BulletCount = 2,
			CurrentMag = nil,
			FireMode = 1,
			Spread = 2,
			StoppingPower = 0.75,

			Recoil = 70,
			DisplayImage = "rbxassetid://133886120497836",
		},
		InUse = false,
		Icon = "",
		Use = "EquipWeapon",

		CanArchive = true,
	},

	Mag_Rag = {
		Name = "Mag-Rag™ 12",
		Desc = "Magazine fed shotgun.",
		Value = {
			Type = 3,
			RateOfFire = 100,
			FireSound = "rbxassetid://115097223835358",
			Volume = 2.5,
			ReloadSound = "rbxassetid://6669540958",
			ReloadTime = 3.5,
			Damage = 11,
			BulletCount = 6,
			CurrentMag = nil,
			FireMode = 1,
			Spread = 18,
			StoppingPower = 0.8,

			Recoil = 90,
			DisplayImage = "rbxassetid://136619685843407",
		},
		InUse = false,
		Icon = "rbxassetid://109720113275520",
		Use = "EquipWeapon",

		CanArchive = true,
	},

	M45A1 = {
		Name = "M45A1",
		Desc = "Basic 45. Pistol.",
		Value = {
			Type = 2,
			RateOfFire = 400,
			FireSound = "rbxassetid://4527561460",
			Volume = 0.75,
			ReloadSound = "rbxassetid://8989486210",
			ReloadTime = 2,
			Damage = 16.75,
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

		CanArchive = true,
	},

	CP_32 = {
		Name = "CP-32",
		Desc = "A bullpup pistol, designed for CQB against armored aponents.",
		Value = {
			Type = 2,
			RateOfFire = 325,
			FireSound = "rbxassetid://77759027041140",
			Volume = 1,
			ReloadSound = "rbxassetid://75533251991749",
			ReloadTime = 2.4,
			Damage = 30,
			BulletCount = 1,
			CurrentMag = nil,
			FireMode = 1,
			Spread = 6,
			StoppingPower = 0.15,

			Recoil = 80,
			DisplayImage = "rbxassetid://99388402288970",
		},
		InUse = false,
		Icon = "rbxassetid://96910840102644",
		Use = "EquipWeapon",

		CanArchive = true,
	},

	--// Ammo
	Shotgun_Mag = {
		Name = "Shotgun Mag",
		Desc = "Magazine for a shotgun",
		Value = 8,
		InUse = false,
		Icon = "rbxassetid://97360139010521",
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
				MaxValue = 30,
				Result = "RemoveOnEmpty",
			},
		},
	},

	--// Food and Health
	Cat_Food = {
		Name = "Cat Food",
		Desc = [[Canned, wet, cat food.
		
<b>+10% Hunger</b>]],
		Value = {
			Hunger = 10,
		},
		InUse = false,
		Icon = "rbxassetid://125543981396297",
		Use = "Eat",
	},

	Can_Of_Nuts = {
		Name = "Can of Nuts",
		Desc = [[Can of assorted nuts.
		
<b>+8 Hunger</b>]],
		Value = {
			Hunger = 8,
		},
		InUse = false,
		Icon = "rbxassetid://125543981396297",
		Use = "Eat",
	},

	Spam = {
		Name = "Spam",
		Desc = [[Canned pork product.
		
<b>+20% Hunger</b>
<b>+5% Health</b>]],
		Value = {
			Hunger = 20,
			Health = 5,
		},
		InUse = false,
		Icon = "rbxassetid://125543981396297",
		Use = "Eat",
	},

	Stemc = {
		Name = "S.T.E.M.C",
		Desc = [[<b>S</b>tem
<b>T</b>herapy &
<b>E</b>lectro
<b>M</b>echanical
<b>C</b>orrection

<b>+20% Health</b>]],
		Value = {
			Health = 20,
		},
		InUse = false,
		Icon = "rbxassetid://106365304733869",
		Use = "Heal",
		CombineData = {
			["S.T.E.M.C"] = {
				Action = "RemoveAll",
				Item = "Stemb",
				Result = "AddItem",
			},
		},
	},

	StemcInjector = {
		Name = "S.T.E.M.C Injector",
		Desc = [[assists with the injection S.T.E.Ms for quicker application. 
		
When equipped, will use the loaded S.T.E.M.C automatically <b>when below 50% health</b>

<b>+15% Health</b>]],
		Value = {
			ActivateValue = 50,
			Health = 15,
		},
		InUse = false,
		Icon = "rbxassetid://107682922166577",
		Use = "EquipStem",
		CombineData = {},
	},

	Stemb = {
		Name = "S.T.E.M.B",
		Desc = [[<b>S</b>.T.E.M.C. 
<b>T</b>atcial
<b>E</b>dition for
<b>M</b>ilitary
<b>B</b>iomechanics

<b>+45% Health</b>]],
		Value = {
			Health = 45,
		},
		InUse = false,
		Icon = "rbxassetid://98624220766754",
		Use = "Heal",

		CombineData = {
			["S.T.E.M.B"] = {
				Action = "RemoveAll",
				Item = "Stema",
				Result = "AddItem",
			},
		},
	},

	StembInjector = {
		Name = "S.T.E.M.B Injector",
		Desc = [[assists with the injection S.T.E.Ms for quicker application. 
		
When equipped, will use the loaded S.T.E.M.B automatically <b>when below 25% health</b>

<b>+35% Health</b>]],
		Value = {
			ActivateValue = 25,
			Health = 35,
		},
		InUse = false,
		Icon = "rbxassetid://107682922166577",
		Use = "EquipStem",
		CombineData = {},
	},

	Stema = {
		Name = "S.T.E.M.A",
		Desc = [[<b>S</b>.T.E.M.B, 
<b>T</b>echnology with
<b>E</b>xperimental
<b>M</b>edical
<b>A</b>dvancements

<b>+100% Health</b>]],
		Value = {
			Health = 100,
		},
		InUse = false,
		Icon = "rbxassetid://78681397230063",
		Use = "Heal",
	},

	StemaInjector = {
		Name = "S.T.E.M.A Injector",
		Desc = [[assists with the injection S.T.E.Ms for quicker application. 
		
When equipped, will use the loaded S.T.E.M.A automatically <b>just before death</b>

<b>+85% Health</b>]],
		Value = {
			ActivateValue = 0,
			Health = 85,
		},
		InUse = false,
		Icon = "rbxassetid://107682922166577",
		Use = "EquipStem",
		CombineData = {},
	},

	--// Keys
	Toolbox_Key = {
		Name = "Small key",
		Desc = "Looks to go to a tool box",
		Value = nil,
		Icon = "rbxassetid://122322561802092",
		Use = nil,
		InUse = false,
		CanArchive = true,
	},

	Screwdriver = {
		Name = "Screwdriver",
		Desc = "A tool for screwing and unscrewing screws",
		Value = nil,
		InUse = false,
		Icon = "rbxassetid://138234409072848",
		Use = nil,
		CanArchive = true,
	},

	Armory_Key = {
		Name = "Armory Key",
		Desc = "Key for the armory",
		Value = nil,
		Icon = "rbxassetid://77384355406607",
		Use = nil,
		InUse = false,
		CanArchive = true,
	},

	Room_103_Key = {
		Name = "Room 103 Key",
		Desc = "Key for room 103",
		Value = nil,
		Icon = "rbxassetid://77384355406607",
		Use = nil,
		InUse = false,
		CanArchive = true,
	},

	Console_Key = {
		Name = "Console Room Key",
		Desc = "Key for the console room",
		Value = nil,
		Icon = "rbxassetid://77384355406607",
		Use = nil,
		InUse = false,
		CanArchive = true,
	},

	--// Tools
	AccessPad = {
		Name = "Access-Pad",
		Desc = [[A device used to connect to and access various VAX technology that isn't registered in the N.E.T system. ]],
		Value = nil,
		InUse = false,
		Icon = "rbxassetid://107682922166577",
		Use = "UsePad",
		CanArchive = true,
	},

	Flashlight = {
		Name = "Flashlight",
		Desc = [[A shoulder mounted flashlight.]],
		Value = nil,
		InUse = false,
		Icon = "rbxassetid://125778243412139",
		Use = "ToggleFlashlight",
		CanArchive = true,
	},

	--// Notes
	OldPhone = {
		Name = "Old Phone",
		Desc = "An old phone with a crack in the screen.",
		Value = { Message = storedData:GetData("BrokenPhone"), Image = "rbxassetid://72233013402684" },
		Icon = "rbxassetid://82487541380359",
		Use = "Read",
		InUse = false,
		CanArchive = true,
	},

	PersonalNote = {
		Name = "Personal Note",
		Desc = "A small scuffed note.",
		Value = { Message = storedData:GetData("PersonalNote"), Image = "rbxassetid://133550222984676" },
		Icon = "rbxassetid://82487541380359",
		Use = "Read",
		InUse = false,
	},

	RationsPoster = {
		Name = "Rations Poster",
		Desc = "A poster about rations and hunger.",
		Value = { Message = storedData:GetData("RationsPoster"), Image = "rbxassetid://111890673888434" },
		Icon = "rbxassetid://82487541380359",
		Use = "Read",
		InUse = false,
	},

	MysteriousJournal = {
		Name = "Journal",
		Desc = "A journal.",
		Value = { Message = storedData:GetData("Journal"), Image = "rbxassetid://94886205976075" },
		Icon = "rbxassetid://82487541380359",
		Use = "Read",
		InUse = false,
	},

	NetManual = {
		Name = "N.E.T Module Manual",
		Desc = "A user manual for the N.E.T Module.",
		Value = { Message = storedData:GetData("N.E.T Manual"), Image = "rbxassetid://96472182587307" },
		Icon = "rbxassetid://82487541380359",
		Use = "Read",
		InUse = false,
	},

	GunManual = {
		Name = "M45A1 Manual",
		Desc = "A safety manual for the M45A1.",
		Value = { Message = storedData:GetData("Gun Manual"), Image = "rbxassetid://104443115073021" },
		Icon = "rbxassetid://82487541380359",
		Use = "Read",
		InUse = false,
	},

	--// Misc
	NetModule = {
		Name = "N.E.T Module",
		Desc = [[<b>N</b>eural 
<b>E</b>xtention 
<b>T</b>ransmitter. 

A Bio Module that connects the user to nearby devices.]],
		Value = nil,
		InUse = false,
		Icon = "rbxassetid://110962933996937",
		Use = "InstallNet",
		CanArchive = true,
	},

	Injector = {
		Name = "S.T.E.M Injector",
		Desc = "Assists with the injection S.T.E.Ms for quicker application. <b>Unloaded</b>",
		Value = nil,
		InUse = false,
		Icon = "rbxassetid://107682922166577",
		Use = nil,
		CombineData = {
			["S.T.E.M.C"] = {
				Action = "RemoveAll",
				Item = "StemcInjector",
				Result = "AddItem",
			},

			["S.T.E.M.B"] = {
				Action = "RemoveAll",
				Item = "StembInjector",
				Result = "AddItem",
			},

			["S.T.E.M.A"] = {
				Action = "RemoveAll",
				Item = "StemaInjector",
				Result = "AddItem",
			},
		},
	},

	Toolbox = {
		Name = "Toolbox",
		Desc = "A locked toolbox",
		Value = nil,
		InUse = false,
		Icon = "rbxassetid://135848984864658",
		Use = nil,
		CombineData = {
			["Small key"] = {
				Result = "RemoveAll",
				Item = "Screwdriver",
				Action = "AddItem",
			},
		},
		CanArchive = true,
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
