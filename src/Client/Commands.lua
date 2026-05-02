local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local items = require(ReplicatedStorage.Shared.Items)
local Net = require(ReplicatedStorage.Packages.Net)

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
		ClearAllData = {
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
					inventory:AddItem(items[itemName])
				end
			end,
		},
	},

	World = {
		Go_To_Area = {
			Parameters = function()
				return {
					{ Name = "AreaName", Options = CollectionService:GetTagged("Area") },
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
	},
}

return commands
