local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CareerData = require(ReplicatedStorage.Shared.Data.CareerData)
local modules = {}
local orderedCall = {
	"Spawners",
	"World",
}

for _, module in ipairs(script:GetChildren()) do
	if not module:IsA("ModuleScript") then
		continue
	end

	modules[module.Name] = require(module)
end

local function callModuleAction(actionName: string, ...)
	for _, moduleName in ipairs(orderedCall) do
		local module = modules[moduleName]

		if not module or not module[actionName] then
			continue
		end

		module[actionName](...)
	end

	for moduleName, module in pairs(modules) do
		if table.find(orderedCall, moduleName) then
			continue
		end

		if not module[actionName] then
			continue
		end

		module[actionName](...)
	end
end

callModuleAction("Init")

modules.Menu.StartEvent:Connect(function(gameSave)
	if not gameSave then
		CareerData.Campaigns_Begun += 1
	end

	callModuleAction("StartGame", gameSave, modules["Player"].spawnCharacter(gameSave))
end)
