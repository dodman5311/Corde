local InputController = {}
type DeviceType = "Touch" | "Keyboard" | "Gamepad"

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Instances
local InputsFolder = ReplicatedStorage.Inputs

--// Modules
local Scales = require(ReplicatedStorage.Shared.Utils.Scales)

--// Values

--// Functions
local InputActionFunctions = {
	Sprint = function(inputActionValue: any)
		if inputActionValue then
		else
		end
	end,
	Movement = function(inputActionValue: any) end,
	Look = function(inputActionValue: any) end,
	Interact = function(inputActionValue: any) end,

	["Toggle Inventory"] = function(inputActionValue: any) end,
	["N.E.T"] = function(inputActionValue: any) end,

	["Ready Weapon"] = function(inputActionValue: any) end,
	["Reload Weapon"] = function(inputActionValue: any) end,
	["Fire Weapon"] = function(inputActionValue: any) end,

	Back = function(inputActionValue: any) end,
	Settings = function(inputActionValue: any) end,
}

local function connectInputActions()
	for _, inputAction: InputAction in ipairs(InputsFolder:GetDescendants()) do
		if not inputAction:IsA("InputAction") then
			continue
		end

		local dedicatedFunction = InputActionFunctions[inputAction.Name]
		inputAction.StateChanged:Connect(dedicatedFunction)
	end
end

function InputController:Init()
	--Prestart Code
	connectInputActions()
end

function InputController:Start()
	--Start Code
end

--// Main //--
return InputController
