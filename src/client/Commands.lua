local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local items = require(ReplicatedStorage.Shared.Items)

local function convertToArray(dictionary)
	local array = {}

	for name, _ in pairs(dictionary) do
		table.insert(array, name)
	end

	print(array)

	return array
end

local commands = {

	Player = {

		God_Mode = {

			Parameters = function()
				return {
					{ Name = "Enable", Options = { true, false } },
				}
			end,

			Execute = function(self, Value)
				Players.LocalPlayer:SetAttribute("GodMode", Value)
			end,
		},

		Take_Damage = {
			Parameters = function()
				return {
					{ Name = "Amount", Options = { "_input" } },
				}
			end,

			Execute = function(self, Value)
				require(script.Parent.Player):DamagePlayer(Value, "god")
			end,
		},

		Enable_Hacking = {
			Parameters = function()
				return {
					{ Name = "Enable", Options = { true, false } },
				}
			end,

			Execute = function(self, Value)
				require(script.Parent.Hacking).HasNet = Value
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

			Execute = function(self, ...)
				local ItemsToAdd = { ... }
				local inventory = require(script.Parent.Inventory)

				for _, itemName in ipairs(ItemsToAdd) do
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

			Execute = function(self, area)
				Players.LocalPlayer.Character:PivotTo(area.CFrame)
			end,
		},

		Spawn = {
			Parameters = function()
				return {
					{ Name = "ToSpawn", Options = ReplicatedStorage.Assets.Npcs:GetChildren() },
				}
			end,

			Execute = function(self, npcToSpawn)
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
