local InputController = {}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

--// Instances
local InputsFolder = ReplicatedStorage.Inputs

--// Modules

--local Scales = require(ReplicatedStorage.Shared.Utils.Scales)

--// Values

--// Functions
local InputActionFunctions = {
	Sprint = function(inputActionValue: any) end,
	Movement = function(inputActionValue: Vector2) end,
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

		inputAction:SetAttribute("Disabled", false)

		inputAction:GetAttributeChangedSignal("Disabled"):Connect(function()
			inputAction.Enabled = not inputAction:GetAttribute("Disabled")
		end)

		inputAction.Changed:Connect(function(property: string)
			if property ~= "Enabled" then
				return
			end

			for _, inputActionChild in ipairs(inputAction:GetChildren()) do
				if inputAction:GetAttribute("Disabled") then
					continue
				end
				inputActionChild.Enabled = inputAction.Enabled
			end
		end)
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
