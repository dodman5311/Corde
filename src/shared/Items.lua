local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(script.Parent.Types)
local storedData = require(ReplicatedStorage.Shared.StoredData)

local Items: { [string]: Types.Item } = {

	Template_Item = {
		ItemType = "Item",
		Name = "",
		IconId = 0,
		Desc = "",

		UseAction = "",
		CanDrop = true,

		Config = {},
		State = {
			InUse = false,
		},
		CombineData = {},
	},

	--// Weapons
	Rifle = {
		ItemType = "Weapon",
		Name = "SG550",
		IconId = 74163431732494,
		Desc = "Standard issue assault rifle.",

		UseAction = "EquipWeapon",
		CanDrop = false,

		Config = {
			Type = 1,
			RateOfFire = 700,
			FireSound = "rbxassetid://4334525640",
			Volume = 0.5,
			ReloadSound = "rbxassetid://799968994",
			ReloadTime = 3,
			Damage = 18,
			BulletCount = 1,
			FireMode = 2,
			Spread = 6,
			StoppingPower = 0.1,

			Recoil = 55,
			DisplayImage = "rbxassetid://133886120497836",
		},
		State = {
			InUse = false,
			CurrentMag = nil,
		},
	},

	Heavy_Rifle = {
		ItemType = "Weapon",
		Name = "SGM-600",
		IconId = 133771746645077,
		Desc = "Heavy Battle Rifle designed to combat UAE's. Fires 2 rounds each shot.",

		UseAction = "EquipWeapon",
		CanDrop = false,

		Config = {
			Type = 1,
			RateOfFire = 420,
			FireSound = "rbxassetid://113459455743841",
			Volume = 1.25,
			ReloadSound = "rbxassetid://75178331995986",
			ReloadTime = 3,
			Damage = 20,
			UseAmmoForBulletCount = true,
			BulletCount = 2,
			FireMode = 1,
			Spread = 2,
			StoppingPower = 0.75,

			Recoil = 70,
			DisplayImage = "rbxassetid://84974769590129",
		},
		State = {
			InUse = false,
			CurrentMag = nil,
		},
	},

	Shotgun = {
		ItemType = "Weapon",
		Name = "Mag-Rag™ 12",
		IconId = 109720113275520,
		Desc = "Magazine fed shotgun.",

		UseAction = "EquipWeapon",
		CanDrop = false,

		Config = {
			Type = 3,
			RateOfFire = 100,
			FireSound = "rbxassetid://115097223835358",
			Volume = 2.5,
			ReloadSound = "rbxassetid://6669540958",
			ReloadTime = 3.5,
			Damage = 11,
			BulletCount = 6,
			FireMode = 1,
			Spread = 18,
			StoppingPower = 0.8,

			Recoil = 90,
			DisplayImage = "rbxassetid://136619685843407",
		},
		State = {
			InUse = false,
			CurrentMag = nil,
		},
	},

	Pistol = {
		ItemType = "Weapon",
		Name = "M45A1",
		IconId = 114178515311412, --94406546559401,
		Desc = "Basic 45. Pistol.",

		UseAction = "EquipWeapon",
		CanDrop = false,

		Config = {
			Type = 2,
			RateOfFire = 400,
			FireSound = "rbxassetid://4527561460",
			Volume = 0.75,
			ReloadSound = "rbxassetid://8989486210",
			ReloadTime = 2,
			Damage = 16.75,
			BulletCount = 1,
			FireMode = 1,
			Spread = 8,
			StoppingPower = 0.25,

			Recoil = 60,
			DisplayImage = "rbxassetid://79496777132333",
		},
		State = {
			InUse = false,
			CurrentMag = nil,
		},
	},

	Suppressed_Pistol = {
		ItemType = "Weapon",
		Name = "M45A1",
		IconId = 135737430812549,
		Desc = "Basic 45. Pistol with a suppressor attached.",

		UseAction = "EquipWeapon",
		CanDrop = false,

		Config = {
			Type = 2,
			RateOfFire = 400,
			FireSound = "rbxassetid://116826905160732",
			Volume = 0.5,
			ReloadSound = "rbxassetid://8989486210",
			ReloadTime = 2,
			Damage = 16.75,
			BulletCount = 1,
			FireMode = 1,
			Spread = 7.5,
			StoppingPower = 0.25,
			IsSuppressed = true,

			Recoil = 50,
			DisplayImage = "rbxassetid://114334200007827",
		},
		State = {
			InUse = false,
			CurrentMag = nil,
		},
	},

	Heavy_Pistol = {
		ItemType = "Weapon",
		Name = "CP-32",
		IconId = 96910840102644,
		Desc = "A bullpup pistol, designed for CQB against armored aponents",

		UseAction = "EquipWeapon",
		CanDrop = false,

		Config = {
			Type = 2,
			RateOfFire = 325,
			FireSound = "rbxassetid://77759027041140",
			Volume = 1,
			ReloadSound = "rbxassetid://75533251991749",
			ReloadTime = 2.4,
			Damage = 30,
			BulletCount = 1,
			FireMode = 1,
			Spread = 6,
			StoppingPower = 0.15,

			Recoil = 80,
			DisplayImage = "rbxassetid://99388402288970",
		},
		State = {
			InUse = false,
			CurrentMag = nil,
		},
	},

	--// Ammo
	Shotgun_Mag = {
		ItemType = "Equipment",
		Name = "Shotgun Mag",
		IconId = 97360139010521,
		Desc = "Magazine for a shotgun",

		UseAction = "Reload",
		CanDrop = true,

		Config = {
			MaxValue = 8,
		},
		State = {
			Value = 8,
			InUse = false,
		},
		CombineData = {
			["Shotgun_Mag"] = {
				Action = "AddValue",
			},
		},
	},

	Rifle_Mag = {
		ItemType = "Equipment",
		Name = "Rifle Mag",
		IconId = 17429767099,
		Desc = "Magazine for a rifle",

		UseAction = "Reload",
		CanDrop = true,

		Config = {
			MaxValue = 30,
		},
		State = {
			Value = 30,
			InUse = false,
		},
		CombineData = {
			["Rifle_Mag"] = {
				Action = "AddValue",
			},
		},
	},

	Pistol_Mag = {
		ItemType = "Equipment",
		Name = "Pistol Mag",
		IconId = 17429886486,
		Desc = "Magazine for a pistol",

		UseAction = "Reload",
		CanDrop = true,

		Config = {
			MaxValue = 10,
		},
		State = {
			Value = 10,
			InUse = false,
		},
		CombineData = {
			["Pistol_Mag"] = {
				Action = "AddValue",
			},
		},
	},

	Pistol_Bullets = {
		ItemType = "Resource",
		Name = "Pistol Bullets",
		IconId = 120524406905008,
		Desc = "Bullets for a pistol",

		UseAction = "",
		CanDrop = true,

		Config = {
			MaxValue = 30,
		},
		State = {
			Value = 30,
			InUse = false,
		},
		CombineData = {
			["Pistol_Mag"] = {
				Action = "AddValue",
				Result = "RemoveOnEmpty",
			},

			["Pistol_Bullets"] = {
				Action = "AddValue",
				Result = "RemoveOnEmpty",
			},
		},
	},

	--// Food and Health
	Cat_Food = {
		ItemType = "Resource",
		Name = "Cat Food",
		IconId = 125543981396297,
		Desc = [[Canned, wet, cat food.
		
<b>+10% Hunger</b>]],

		UseAction = "Eat",
		CanDrop = true,

		Config = {
			HungerRestoration = 10,
		},
		State = {},
	},

	Can_Of_Nuts = {
		ItemType = "Resource",
		Name = "Can of Nuts",
		IconId = 125543981396297,
		Desc = [[Can of assorted nuts.
		
<b>+8% Hunger</b>]],

		UseAction = "Eat",
		CanDrop = true,

		Config = {
			HungerRestoration = 8,
		},
		State = {},
	},

	Spam = {
		ItemType = "Resource",
		Name = "Spam",
		IconId = 125543981396297,
		Desc = [[Canned pork product.
		
<b>+20% Hunger</b>
<b>+5% Health</b>]],

		UseAction = "Eat",
		CanDrop = true,

		Config = {
			HungerRestoration = 20,
			HealthRestoration = 5,
		},
		State = {},
		CombineData = {
			["Canned_Soup"] = {
				Action = "RemoveAll",
				Result = "AddItem",
				Item = "Spam_Of_Stew",
			},
		},
	},

	MRE = {
		ItemType = "Resource",
		Name = "M.R.E",
		IconId = 125543981396297,
		Desc = [[Meal, ready to eat.
Prepackaged meal ration for appropriate neutriant sustenance.
		
<b>+25% Hunger</b>
<b>+6% Health</b>]],

		UseAction = "Eat",
		CanDrop = true,

		Config = {
			HungerRestoration = 25,
			HealthRestoration = 6,
		},
		State = {},
	},

	Canned_Soup = {
		ItemType = "Resource",
		Name = "Canned Soup",
		IconId = 125543981396297,
		Desc = [[A can of premade soup. 
The contents of which have been scratched off the can.
		
<b>+35% Hunger</b>]],

		UseAction = "Eat",
		CanDrop = true,

		Config = {
			HungerRestoration = 35,
		},
		State = {},

		CombineData = {
			["Spam"] = {
				Action = "RemoveAll",
				Result = "AddItem",
				Item = "Spam_Of_Stew",
			},
		},
	},

	Spam_Of_Stew = {
		ItemType = "Resource",
		Name = "Stewed Spam",
		IconId = 125543981396297,
		Desc = [[Enjoy, I guess...
		
<b>+50% Hunger</b>
<b>-1% Health</b>]],

		UseAction = "Eat",
		CanDrop = true,

		Config = {
			HungerRestoration = 50,
			HealthRestoration = -1,
		},
		State = {},
	},

	Stemc = {
		ItemType = "Resource",
		Name = "S.T.E.M.C",
		IconId = 106365304733869,
		Desc = [[<b>S</b>tem
<b>T</b>herapy &
<b>E</b>lectro
<b>M</b>echanical
<b>C</b>orrection

<b>+20% Health</b>]],

		UseAction = "Heal",
		CanDrop = true,

		Config = {
			HealthRestoration = 20,
		},
		State = {},
		CombineData = {
			["Stemc"] = {
				Action = "RemoveAll",
				Result = "AddItem",
				Item = "Stemb",
			},
		},
	},

	Stemc_Injector = {
		ItemType = "Equipment",
		Name = "S.T.E.M.C Injector",
		IconId = 107682922166577,
		Desc = [[assists with the injection S.T.E.Ms for quicker application. 
		
When equipped, will use the loaded S.T.E.M.C automatically <b>when below 50% health</b>

<b>+15% Health</b>]],

		UseAction = "EquipStem",
		CanDrop = true,

		Config = {
			ActivateValue = 50,
			HealthRestoration = 15,
		},
		State = {
			InUse = false,
		},
	},

	Stemb = {
		ItemType = "Resource",
		Name = "S.T.E.M.B",
		IconId = 98624220766754,
		Desc = [[<b>S</b>.T.E.M.C. 
<b>T</b>atcial
<b>E</b>dition for
<b>M</b>ilitary
<b>B</b>iomechanics

<b>+45% Health</b>]],

		UseAction = "Heal",
		CanDrop = true,

		Config = {
			HealthRestoration = 45,
		},
		State = {},
		CombineData = {
			["Stemb"] = {
				Action = "RemoveAll",
				Item = "Stema",
				Result = "AddItem",
			},
		},
	},

	Stemb_Injector = {
		ItemType = "Equipment",
		Name = "S.T.E.M.B Injector",
		IconId = 107682922166577,
		Desc = [[assists with the injection S.T.E.Ms for quicker application. 
		
When equipped, will use the loaded S.T.E.M.B automatically <b>when below 25% health</b>

<b>+35% Health</b>]],

		UseAction = "EquipStem",
		CanDrop = true,

		Config = {
			ActivateValue = 25,
			HealthRestoration = 35,
		},
		State = {
			InUse = false,
		},
	},

	Stema = {
		ItemType = "Resource",
		Name = "S.T.E.M.A",
		IconId = 78681397230063,
		Desc = [[<b>S</b>.T.E.M.B, 
<b>T</b>echnology with
<b>E</b>xperimental
<b>M</b>edical
<b>A</b>dvancements

<b>+100% Health</b>]],

		UseAction = "Heal",
		CanDrop = true,

		Config = {
			HealthRestoration = 100,
		},
		State = {},
	},

	Stema_Injector = {
		ItemType = "Equipment",
		Name = "S.T.E.M.A Injector",
		IconId = 107682922166577,
		Desc = [[assists with the injection S.T.E.Ms for quicker application. 
		
When equipped, will use the loaded S.T.E.M.A automatically <b>just before death</b>

<b>+85% Health</b>]],

		UseAction = "EquipStem",
		CanDrop = true,

		Config = {
			ActivateValue = 0,
			HealthRestoration = 85,
		},
		State = {
			InUse = false,
		},
	},

	--// Keys
	Toolbox_Key = {
		ItemType = "Item",
		Name = "Small key",
		IconId = 122322561802092,
		Desc = "Looks to go to a tool box",

		UseAction = "",
		CanDrop = false,

		Config = {},
		State = {},
	},

	Screwdriver = {
		ItemType = "Item",
		Name = "Screwdriver",
		IconId = 138234409072848,
		Desc = "A tool for screwing and unscrewing screws",

		UseAction = "",
		CanDrop = false,

		Config = {},
		State = {},
	},

	Armory_Key = {
		ItemType = "Item",
		Name = "Armory Key",
		IconId = 77384355406607,
		Desc = "Key for the armory",

		UseAction = "",
		CanDrop = false,

		Config = {},
		State = {},
	},

	Room_103_Key = {
		ItemType = "Item",
		Name = "Room 103 Key",
		IconId = 77384355406607,
		Desc = "Key for room 103",

		UseAction = "",
		CanDrop = false,

		Config = {},
		State = {},
	},

	Console_Key = {
		ItemType = "Item",
		Name = "Console Room Key",
		IconId = 77384355406607,
		Desc = "Key for the console room",

		UseAction = "",
		CanDrop = false,

		Config = {},
		State = {},
	},

	Hallway_Key = {
		ItemType = "Item",
		Name = "Entry Hall_1 Key",
		IconId = 77384355406607,
		Desc = "Key for the hallway",

		UseAction = "",
		CanDrop = false,

		Config = {},
		State = {},
	},

	--// Tools
	Access_Pad = {
		ItemType = "Equipment",
		Name = "Access-Pad",
		IconId = 107682922166577,
		Desc = [[A device used to connect to and access various VAX technology that isn't registered in the N.E.T system.]],

		UseAction = "UsePad",
		CanDrop = false,

		Config = {},
		State = {
			IsUse = false,
		},
	},

	Flashlight = {
		ItemType = "Equipment",
		Name = "Flashlight",
		IconId = 125778243412139,
		Desc = [[A shoulder mounted flashlight.]],

		UseAction = "ToggleFlashlight",
		CanDrop = false,

		Config = {},
		State = {
			IsUse = false,
		},
	},

	Gas_Mask = {
		ItemType = "Equipment",
		Name = "Gas Mask",
		IconId = 125778243412139,
		Desc = [[A mask designed to filter out harmful gases.]],

		UseAction = "ToggleGasMask",
		CanDrop = false,

		Config = {},
		State = {
			IsUse = false,
		},
	},

	--// Notes
	Old_Phone = {
		ItemType = "Note",
		Name = "Old Phone",
		IconId = 82487541380359,
		Desc = [[An old phone with a crack in the screen.]],

		UseAction = "Read",
		CanDrop = true,

		Config = {
			Message = storedData:GetData("BrokenPhone"),
			Image = "rbxassetid://72233013402684",
		},
		State = {
			IsUse = false,
		},
	},

	Personal_Note = {
		ItemType = "Note",
		Name = "Personal Note",
		IconId = 82487541380359,
		Desc = [[A small scuffed note.]],

		UseAction = "Read",
		CanDrop = true,

		Config = {
			Message = storedData:GetData("PersonalNote"),
			Image = "rbxassetid://133550222984676",
		},
		State = {
			IsUse = false,
		},
	},

	Rations_Poster = {
		ItemType = "Note",
		Name = "Rations Poster",
		IconId = 82487541380359,
		Desc = [[A poster about rations and hunger.]],

		UseAction = "Read",
		CanDrop = true,

		Config = {
			Message = storedData:GetData("RationsPoster"),
			Image = "rbxassetid://111890673888434",
		},
		State = {
			IsUse = false,
		},
	},

	Mysterious_Journal = {
		ItemType = "Note",
		Name = "Journal",
		IconId = 82487541380359,
		Desc = [[A journal.]],

		UseAction = "Read",
		CanDrop = true,

		Config = {
			Message = storedData:GetData("Journal"),
			Image = "rbxassetid://94886205976075",
		},
		State = {
			IsUse = false,
		},
	},

	Net_Manual = {
		ItemType = "Note",
		Name = "N.E.T Module Manual",
		IconId = 82487541380359,
		Desc = [[A user manual for the N.E.T Module.]],

		UseAction = "Read",
		CanDrop = true,

		Config = {
			Message = storedData:GetData("N.E.T Manual"),
			Image = "rbxassetid://96472182587307",
		},
		State = {
			IsUse = false,
		},
	},

	Gun_Manual = {
		ItemType = "Note",
		Name = "M45A1 Manual",
		IconId = 82487541380359,
		Desc = [[A safety & usage manual for the M45A1.]],

		UseAction = "Read",
		CanDrop = true,

		Config = {
			Message = storedData:GetData("Gun Manual"),
			Image = "rbxassetid://104443115073021",
		},
		State = {
			IsUse = false,
		},
	},

	Photo = {
		ItemType = "Note",
		Name = "Old Photo",
		IconId = 82487541380359,
		Desc = [[A photo of me and my dad.]],

		UseAction = "Read",
		CanDrop = true,

		Config = {
			Message = { "A photo of me and my dad." },
			Image = "rbxassetid://135824933780230",
		},
		State = {
			IsUse = false,
		},
	},

	--// Misc
	Net_Module = {
		ItemType = "Item",
		Name = "N.E.T Module",
		IconId = 110962933996937,
		Desc = [[<b>N</b>eural 
<b>E</b>xtention 
<b>T</b>ransmitter. 

A Bio Module that connects the user to nearby devices.]],

		UseAction = "InstallNet",
		CanDrop = false,

		Config = {},
		State = {},
	},

	Injector = {
		ItemType = "Item",
		Name = "S.T.E.M Injector",
		IconId = 107682922166577,
		Desc = [[Assists with the injection S.T.E.Ms for quicker application. <b>Unloaded</b>]],

		UseAction = "",
		CanDrop = true,

		Config = {},
		State = {},
		CombineData = {
			["Stemc"] = {
				Action = "RemoveAll",
				Item = "StemcInjector",
				Result = "AddItem",
			},

			["Stemb"] = {
				Action = "RemoveAll",
				Item = "StembInjector",
				Result = "AddItem",
			},

			["Stema"] = {
				Action = "RemoveAll",
				Item = "StemaInjector",
				Result = "AddItem",
			},
		},
	},

	Toolbox = {
		ItemType = "Item",
		Name = "Toolbox",
		IconId = 135848984864658,
		Desc = [[A locked toolbox.]],

		UseAction = "",
		CanDrop = false,

		Config = {},
		State = {},
		CombineData = {
			["Toolbox_Key"] = {
				Result = "RemoveAll",
				Item = "Screwdriver",
				Action = "AddItem",
			},
		},
	},

	Suppressor = {
		ItemType = "Item",
		Name = "45. Suppressor",
		IconId = 101906011273059,
		Desc = [[A Silencerco suppressor designed for a pistol chambered in 45 acp.]],

		UseAction = "",
		CanDrop = false,

		Config = {},
		State = {},
		CombineData = {
			["Pistol"] = {
				Result = "RemoveAll",
				Item = "Suppressed_Pistol",
				Action = "AddItem",
			},
		},
	},

	Wrist_Band = {
		ItemType = "Item",
		Name = "Wrist Band",
		IconId = 77793554789189,
		Desc = [[A wrist band with the name, <font color="rgb(255,125,0)">Kaia Parlow</font> written on it.]],

		UseAction = "",
		CanDrop = true,

		Config = {},
		State = {},
	},
}
return Items
