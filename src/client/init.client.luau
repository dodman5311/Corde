local modules = {}

for _, module in ipairs(script:GetChildren()) do
	if not module:IsA("ModuleScript") then
		continue
	end

	modules[module.Name] = require(module)
end

for _, module in pairs(modules) do
	if module.Init then
		module.Init()
	end

	if module.Start then
		task.delay(1, module.Start)
	end
end
