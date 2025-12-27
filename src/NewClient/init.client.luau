local modules = {}

for _, value in ipairs(script.Controllers:GetChildren()) do
	modules[value.Name] = require(value)
	modules[value.Name]:Init()
end
