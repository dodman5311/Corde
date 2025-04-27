export type Input = {
	Name: string,
	KeyInputs: {
		Keyboard: { InputObject },
		Gamepad: { InputObject },
	},
	Callback: () -> any?,
	Priority: number?,
	IsEnabled: () -> boolean,

	Enable: (self: Input) -> nil,
	Disable: (self: Input) -> nil,
	Refresh: (self: Input) -> nil,
	SetPriority: (self: Input, priority: number | Enum.ContextActionPriority) -> nil,
	SetKeybinds: (self: Input, bindGroup: "Gamepad" | "Keyboard", T...) -> nil,
	AddKeybinds: (self: Input, bindGroup: "Gamepad" | "Keyboard", T...) -> nil,
	RemoveKeybinds: (self: Input, bindGroup: "Gamepad" | "Keyboard", T...) -> nil,
	ReplaceKeybinds: (self: Input, bindGroup: "Gamepad" | "Keyboard", keybindsTable: { InputObject }) -> nil,
}

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

local inputs: { Input } = {}
local module = {
	inputType = "Keyboard",
	gamepadType = "Xbox",

	inputIcons = {
		Ps4 = {
			ButtonX = "rbxassetid://122062730815411",
			ButtonA = "rbxassetid://99222140491626",
			ButtonB = "rbxassetid://139151046418306",
			ButtonY = "rbxassetid://124498431294550",

			ButtonL1 = "rbxassetid://97608958968765", -- left bumper
			ButtonL2 = "rbxassetid://84837513862254", -- left trigger
			ButtonR1 = "rbxassetid://84450330851971",
			ButtonR2 = "rbxassetid://70730301952026",
		},
		Xbox = {
			ButtonX = "rbxassetid://122267119998385",
			ButtonA = "rbxassetid://121295530666976",
			ButtonB = "rbxassetid://97330447691033",
			ButtonY = "rbxassetid://73181495754569",

			ButtonL1 = "rbxassetid://97608958968765", -- left bumper
			ButtonL2 = "rbxassetid://84837513862254", -- left trigger
			ButtonR1 = "rbxassetid://84450330851971",
			ButtonR2 = "rbxassetid://70730301952026",
		},
		Keyboard = {
			MouseButton1 = "rbxassetid://115777151252419",
			MouseButton2 = "rbxassetid://126344159018792",
			MouseButton3 = "rbxassetid://95452537473335",
			Scroll = "rbxassetid://129056272209004",
			F = "rbxassetid://74228350755401",
			One = "rbxassetid://87310485799989",
			Two = "rbxassetid://104360287893229",
			Three = "rbxassetid://108142578535176",
			Four = "rbxassetid://131238976336903",
			Tab = "rbxassetid://116362922317477",
			LeftShift = "rbxassetid://77318620414643",
			Shift = "rbxassetid://77318620414643",
		},
		Misc = {
			Dpad = "rbxassetid://104088083610808",
			Left = "rbxassetid://102626010372615",
			Right = "rbxassetid://128897927978505",
			Horizontal = "rbxassetid://134923880414479",
			Up = "rbxassetid://112547970720772",
			Down = "rbxassetid://136246329210868",
			Vertical = "rbxassetid://81470201795928",
			Unknown = "rbxassetid://136342675608310",
		},
	},

	inputs = inputs,
	LastGamepadInput = nil,
}

local lastInputType
local lastGamepadType

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

function module:CheckKeyPrompts()
	for _, image: ImageLabel in ipairs(CollectionService:GetTagged("KeyPrompt")) do
		local iconKey

		if image:GetAttribute("InputName") and module.inputs[image:GetAttribute("InputName")] then
			iconKey = module.inputs[image:GetAttribute("InputName")].KeyInputs[module.inputType][1].Name

			print(iconKey, module.inputs[image:GetAttribute("InputName")].KeyInputs)
		end

		local KEY = image:GetAttribute("Key")
		local BUTTON = image:GetAttribute("Button")
		local INPUT_NAME = image:GetAttribute("InputName")

		if (module.inputType == "Gamepad" and BUTTON) or (module.inputType == "Keyboard" and KEY) then
			iconKey = module.inputType == "Gamepad" and BUTTON or KEY
		elseif INPUT_NAME and module.inputs[INPUT_NAME] then
			iconKey = module.inputs[INPUT_NAME].KeyInputs[module.inputType][1].Name
		end

		if not iconKey then
			image.Visible = false
			continue
		end

		image.Visible = true

		if module.inputIcons.Misc[iconKey] then
			image.Image = module.inputIcons.Misc[iconKey]
			continue
		end

		local list = module.inputType == "Gamepad" and module.inputIcons[module.gamepadType]
			or module.inputIcons.Keyboard

		image.Image = list[iconKey]
	end
end

local function setInputType(lastInput)
	if
		(lastInput.KeyCode == Enum.KeyCode.Thumbstick1 or lastInput.KeyCode == Enum.KeyCode.Thumbstick2)
		and lastInput.Position.Magnitude < 0.25
	then
		return
	end

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

	if lastInputType ~= module.inputType or lastGamepadType ~= module.gamepadType then
		module:CheckKeyPrompts()
	end

	lastInputType = module.inputType
	lastGamepadType = module.gamepadType
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

function module.CreateNewInput(
	inputName: string,
	func: () -> any?,
	keyboardInputs: { InputObject } | InputObject,
	gamepadInputs: { InputObject } | InputObject
): Input
	if typeof(keyboardInputs) ~= "table" then
		keyboardInputs = { keyboardInputs }
	end

	if typeof(gamepadInputs) ~= "table" then
		gamepadInputs = { gamepadInputs }
	end

	local inputIsEnabled = false
	local newInput: Input = {
		Name = inputName,
		KeyInputs = {
			Keyboard = keyboardInputs,
			Gamepad = gamepadInputs,
		},
		Callback = func,
		Priority = nil,

		IsEnabled = function()
			return inputIsEnabled
		end,

		Enable = function(self: Input)
			local callback = self.Callback
			inputIsEnabled = true

			if self.Priority then
				ContextActionService:BindActionAtPriority(
					self.Name,
					function(_, inputState: Enum.UserInputState, input: InputObject)
						if acts:checkAct("Paused") then -- pause inputs
							return
						end
						return callback(inputState, input)
					end,
					false,
					self.Priority,
					table.unpack(self.KeyInputs.Keyboard),
					table.unpack(self.KeyInputs.Gamepad)
				)
			else
				ContextActionService:BindAction(
					self.Name,
					function(_, inputState: Enum.UserInputState, input: InputObject)
						if acts:checkAct("Paused") then -- pause inputs
							return
						end
						return callback(inputState, input)
					end,
					false,
					table.unpack(self.KeyInputs.Keyboard),
					table.unpack(self.KeyInputs.Gamepad)
				)
			end
		end,

		Disable = function(self: Input)
			inputIsEnabled = false
			ContextActionService:UnbindAction(self.Name)
		end,

		Refresh = function(self: Input)
			if not inputIsEnabled then
				return
			end

			self:Disable()
			self:Enable()
		end,

		SetPriority = function(self: Input, priority: number | Enum.ContextActionPriority)
			self.Priority = tonumber(priority) and priority or priority.Value
			self:Refresh()
		end,

		SetKeybinds = function(self: Input, bindGroup: "Gamepad" | "Keyboard", ...)
			self.KeyInputs[bindGroup] = { ... }
			self:Refresh()
		end,
		AddKeybinds = function(self: Input, bindGroup: "Gamepad" | "Keyboard", ...)
			local keybinds = { ... }
			for _, keybind: Enum.KeyCode | Enum.UserInputType in ipairs(keybinds) do
				table.insert(self.KeyInputs[bindGroup], keybind)
			end
			self:Refresh()
		end,
		RemoveKeybinds = function(self: Input, bindGroup: "Gamepad" | "Keyboard", ...)
			local keybinds = { ... }
			for _, keybind in ipairs(keybinds) do
				local keybindIndex = table.find(self.KeyInputs[bindGroup], keybind)
				if not keybindIndex then
					continue
				end

				table.remove(self.KeyInputs[bindGroup], keybindIndex)
			end
			self:Refresh()
		end,
		ReplaceKeybinds = function(self: Input, bindGroup: "Gamepad" | "Keyboard", keybindsTable: { InputObject })
			for toReplace, keybind in pairs(keybindsTable) do
				local keybindIndex = table.find(self.KeyInputs[bindGroup], toReplace)
				if not keybindIndex then
					continue
				end

				self.KeyInputs[bindGroup][keybindIndex] = keybind
			end

			self:Refresh()
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
