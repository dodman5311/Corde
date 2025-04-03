local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer

local selectionUi = ReplicatedStorage.Assets.Gui.GamepadSelectionUi
local selectionImage = selectionUi.SelectionImage

local acts = require(script.Parent.Acts)

local ti = TweenInfo.new(0.25, Enum.EasingStyle.Quart)

local module = {
	inputType = "Keyboard",
	gamepadType = "Xbox",

	inputIcons = {
		Ps4 = {
			ButtonX = "rbxassetid://122062730815411",
			ButtonA = "rbxassetid://99222140491626",
			ButtonB = "rbxassetid://139151046418306",
		},
		Xbox = {
			ButtonX = "rbxassetid://122267119998385",
			ButtonA = "rbxassetid://121295530666976",
			ButtonB = "rbxassetid://97330447691033",
		},
		Misc = {
			Dpad = "rbxassetid://104088083610808",
			Left = "rbxassetid://102626010372615",
			Right = "rbxassetid://128897927978505",
			Horizontal = "rbxassetid://134923880414479",
			Up = "rbxassetid://112547970720772",
			Down = "rbxassetid://136246329210868",
			Vertical = "rbxassetid://81470201795928",
		},
	},

	inputs = {},
	LastGamepadInput = nil,
}

local ps4Keys = {
	"ButtonCross",
	"ButtonCircle",
	"ButtonTriangle",
	"ButtonSquare",

	"ButtonR1",
	"ButtonR2",
	"ButtonR3",
	"ButtonL1",
	"ButtonL2",
	"ButtonL3",
	"ButtonOptions",
	"ButtonShare",
}

local xboxKeys = {
	"ButtonA",
	"ButtonB",
	"ButtonX",
	"ButtonY",

	"ButtonLB",
	"ButtonRB",
	"ButtonLT",
	"ButtonRT",
	"ButtonLS",
	"ButtonRS",
	"ButtonStart",
	"ButtonSelect",
}

local function setGamepadType(lastInput)
	local inputName = UserInputService:GetStringForKeyCode(lastInput.KeyCode)

	if table.find(ps4Keys, inputName) then
		module.gamepadType = "Ps4"
	elseif table.find(xboxKeys, inputName) then
		module.gamepadType = "Xbox"
	end
end

local function setInputType(lastInput)
	if lastInput.KeyCode == Enum.UserInputType.Touch then
		module.inputType = "Mobile"
		return
	end

	if lastInput.UserInputType.Name:find("Gamepad") then
		module.inputType = "Gamepad"
		setGamepadType(lastInput)
		module.LastGamepadInput = lastInput
	else
		module.inputType = "Keyboard"
	end

	for _, image: ImageLabel in ipairs(CollectionService:GetTagged("KeyPrompt")) do
		local iconKey = image:GetAttribute("Key")

		if module.inputIcons.Misc[iconKey] then
			image.Image = module.inputIcons.Misc[iconKey]
			continue
		end

		image.Image = module.inputIcons[module.gamepadType][iconKey]
	end
end

local function Lerp(num, goal, i)
	return num + (goal - num) * i
end

local function getUdim2Magnitude(udim2: UDim2)
	local offsetMagnitude = Vector2.new(udim2.X.Offset, udim2.Y.Offset).Magnitude
	return offsetMagnitude
end

local function lerpToDistance(value: UDim2, goal: UDim2, alpha: number, pixelMagnitude: number)
	local valueMagnitude = getUdim2Magnitude(value - goal)

	if valueMagnitude < pixelMagnitude then
		return goal
	end
	return value:Lerp(goal, alpha)
end

local function handleGamepadSelection()
	local object = GuiService.SelectedObject

	if object then
		if selectionImage.Visible then
			-- TweenService:Create(selectionImage, ti, {
			-- 	Position = UDim2.fromOffset(object.AbsolutePosition.X, object.AbsolutePosition.Y),
			-- 	Size = UDim2.fromOffset(object.AbsoluteSize.X, object.AbsoluteSize.Y),
			-- 	Rotation = object.Rotation,
			-- }):Play()

			selectionImage.Position = lerpToDistance(
				selectionImage.Position,
				UDim2.fromOffset(object.AbsolutePosition.X, object.AbsolutePosition.Y),
				0.25,
				5
			)

			selectionImage.Size = lerpToDistance(
				selectionImage.Size,
				UDim2.fromOffset(object.AbsoluteSize.X, object.AbsoluteSize.Y),
				0.25,
				5
			)

			selectionImage.Rotation = Lerp(selectionImage.Rotation, object.Rotation, 0.25)
		else
			selectionImage.Position = UDim2.fromOffset(object.AbsolutePosition.X, object.AbsolutePosition.Y)
			selectionImage.Size = UDim2.fromOffset(object.AbsoluteSize.X, object.AbsoluteSize.Y)
			selectionImage.Rotation = object.Rotation
		end

		selectionImage.Visible = true
	else
		selectionImage.Visible = false
	end
end

function module.CreateNewInput(inputName: string, func: () -> any?, ...)
	local newInput = {
		Name = inputName,
		KeyInputs = { ... },
		Callback = func,

		Enable = function(self)
			local callback = self.Callback
			ContextActionService:BindAction(self.Name, function(_, inputState: Enum.UserInputState, input: InputObject)
				if acts:checkAct("Paused") then -- pause inputs
					return
				end
				return callback(inputState, input)
			end, false, table.unpack(self.KeyInputs))
		end,

		Disable = function(self)
			ContextActionService:UnbindAction(self.Name)
		end,
	}

	module.inputs[inputName] = newInput
	newInput:Enable()

	return newInput
end

UserInputService.InputBegan:Connect(setInputType)
UserInputService.InputChanged:Connect(setInputType)

local stepped
GuiService.Changed:Connect(function()
	if GuiService.SelectedObject then
		if not stepped then
			stepped = RunService.RenderStepped:Connect(handleGamepadSelection)
		end
	elseif stepped then
		stepped:Disconnect()
		stepped = nil
		handleGamepadSelection()
	end
end)

Player:WaitForChild("PlayerGui").SelectionImageObject = selectionUi.HideSelection
selectionUi.Parent = Player.PlayerGui

return module
