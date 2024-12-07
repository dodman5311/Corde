local module = {
    inputType = "Keyboard",
    gamepadType = "Xbox"
}

local UserInputService = game:GetService("UserInputService")

local ps4Keys = {
	"ButtonCross",
	"ButtonCircle",
	"ButtonTriangle",
	"ButtonSquare",
}

local xboxKeys = {
	"ButtonA",
	"ButtonB",
	"ButtonX",
	"ButtonY",
}

local lastInput

local function setInputType()
	
	if lastInput == Enum.UserInputType.Touch then
         module.inputType = "Mobile"
		return
	end
	
	if not UserInputService.GamepadEnabled then
         module.inputType = "Keyboard"
		return
	end

	if not lastInput then
        module.inputType = "Gamepad"
		return
	end
	
	local input = UserInputService:GetStringForKeyCode(lastInput)

	if table.find(ps4Keys, input) then
        module.inputType = "Gamepad"
        module.gamepadType = "Ps4"
	else
        module.inputType = "Gamepad"
        module.gamepadType = "Xbox"
	end
end

UserInputService.InputBegan:Connect(function(i)
	local input = UserInputService:GetStringForKeyCode(i.KeyCode)
	
	if table.find(ps4Keys, input) or table.find(xboxKeys, input) then
		lastInput = i.KeyCode
	elseif i.UserInputType == Enum.UserInputType.Touch then
		lastInput = Enum.UserInputType.Touch
	end
	
	setInputType()
end)

return module