local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Controllers = ReplicatedStorage.Shared.Services.Controllers

local ModuleLoadOrder = {
	"CameraController",
	"CharacterController",
	"InputController",
	"UIController",
}

local function CallModuleMethods(methodName: string, ...)
	for _, moduleName in ipairs(ModuleLoadOrder) do
		local module = require(Controllers[moduleName])
		module[methodName](module, ...)
	end
end

CallModuleMethods("Init")
CallModuleMethods("Start")
