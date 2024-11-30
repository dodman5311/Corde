local modules = {}

for _,module in ipairs(script:GetChildren()) do
    if not module:IsA("ModuleScript") then
        continue
    end

    modules[module.Name] = require(module)
end

for _,module in pairs(modules) do
    if not module.Init then
        continue
    end
    module.Init()
end

task.wait(1)
modules.NpcService.new("E-01"):Spawn(workspace.SpawnPoint.Position)