local modules = {}

for _, module in ipairs(script:GetChildren()) do
	if not module:IsA("ModuleScript") then
		continue
	end

	modules[module.Name] = require(module)
end

local function callModuleAction(actionName: string, ...)
	for _, module in pairs(modules) do
		if not module[actionName] then
			continue
		end

		module[actionName](...)
	end
end

callModuleAction("Init")

modules.Menu.StartEvent:Connect(function(gameSave)
	callModuleAction("StartGame", gameSave, modules["Player"].spawnCharacter(gameSave))
end)
