local modules = {}

for _,module in ipairs(script:GetChildren()) do
    modules[module.Name] = require(module)
end

for _,module in pairs(modules) do
    if not module.Init then
        continue
    end
    module.Init()
end