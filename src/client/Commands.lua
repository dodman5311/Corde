local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CareerData = require(ReplicatedStorage.Shared.Data.CareerData)
local Net = require(ReplicatedStorage.Packages.Net)
local items = require(ReplicatedStorage.Shared.Items)

local function convertToArray(dictionary)
	local array = {}

	for name, _ in pairs(dictionary) do
		table.insert(array, name)
	end

	return array
end

local commands = {

	Gui = {
		Play_Sequence = {
			Parameters = function()
				return {
					{ Name = "Sequence", Options = { "InstallModule" } },
				}
			end,

			Execute = function(_, Value)
				require(script.Parent.Sequences):beginSequence(Value)
			end,
		},

		Play_Sound = {
			Parameters = function()
				local sounds = ReplicatedStorage.Assets.Sounds:GetChildren()

				return {
					{ Name = "Sound", Options = sounds },
				}
			end,

			Execute = function(_, Value)
				if not Value then
					return
				end
				Value:Play()
			end,
		},

		ShowElevatorMenu = {
			Parameters = function()
				return {}
			end,

			Execute = function(_, Value)
				task.wait(1)
				require(script.Parent.Elevator):ShowGuiAnimation()
			end,
		},
	},

	Player = {

		God_Mode = {

			Parameters = function()
				return {
					{ Name = "Enable", Options = { true, false } },
				}
			end,

			Execute = function(_, Value)
				Players.LocalPlayer:SetAttribute("GodMode", Value)
			end,
		},

		Take_Damage = {
			Parameters = function()
				return {
					{ Name = "Amount", Options = { "_input" } },
				}
			end,

			Execute = function(_, Value)
				require(script.Parent.Player):DamagePlayer(Value, "god")
			end,
		},

		Enable_Hacking = {
			Parameters = function()
				return {
					{ Name = "Enable", Options = { true, false } },
				}
			end,

			Execute = function(_, Value)
				Players.LocalPlayer.Character:SetAttribute("HasNet", Value)
			end,
		},

		SaveData = {
			Parameters = function()
				return {
					{ Name = "Slot", Options = { 0, 1, 2 } },
				}
			end,

			Execute = function(_, slot)
				print(require(script.Parent.SaveLoad):SaveGame(slot))
			end,
		},
		ClearSaves = {
			Parameters = function()
				return {
					{ Name = "Confirm?", Options = { true, false } },
				}
			end,

			Execute = function(_, confirm)
				if not confirm then
					return
				end

				Net:RemoteEvent("ClearAllData"):FireServer()
			end,
		},
		ClearCareer = {
			Parameters = function()
				return {
					{ Name = "Confirm?", Options = { true, false } },
				}
			end,

			Execute = function(_, confirm)
				if not confirm then
					return
				end

				for index, _ in pairs(CareerData) do
					CareerData[index] = 0
				end

				Net:RemoteEvent("SyncCareer"):FireServer(CareerData)
			end,
		},
	},

	Inventory = {
		Give_Item = {
			Parameters = function()
				local optionsTable = {}
				local items = convertToArray(items)

				for _ = 1, 12 do
					table.insert(optionsTable, { Name = "ItemToAdd", Options = items })
				end

				return optionsTable
			end,

			Execute = function(_, ...)
				local ItemsToAdd = { ... }
				local inventory = require(script.Parent.Inventory)

				for _, itemName in ipairs(ItemsToAdd) do
					if not items[itemName] then
						continue
					end
					inventory:AddItem { Key = itemName }
				end

				print(inventory)
			end,
		},
	},

	World = {
		Go_To_Area = {
			Parameters = function()
				local areas = {}
				for _, v in ipairs(CollectionService:GetTagged("Area")) do
					if v:FindFirstAncestor("Workspace") then
						table.insert(areas, v)
					end
				end
				return {
					{
						Name = "AreaName",
						Options = areas,
					},
				}
			end,

			Execute = function(_, area)
				Players.LocalPlayer.Character:PivotTo(area.CFrame)
			end,
		},

		Spawn = {
			Parameters = function()
				return {
					{ Name = "ToSpawn", Options = ReplicatedStorage.Assets.Npcs:GetChildren() },
				}
			end,

			Execute = function(_, npcToSpawn)
				if not npcToSpawn then
					return
				end
				local npcSystem = require(script.Parent.NpcService)
				npcSystem.new(npcToSpawn.Name):Spawn(require(script.Parent.Interact).MouseHitLocation)
			end,
		},

		Load_Layer = {
			Parameters = function()
				return {
					{ Name = "Layer Key", Options = ReplicatedStorage.Layers:GetChildren() },
				}
			end,

			Execute = function(_, layerKey)
				if not layerKey then
					return
				end
				require(script.Parent.World).LoadLayer(layerKey.Name)
			end,
		},
	},
}

return commands
