--// Modules
local lists = require(script.Lists)
local scales = require(script.Parent.Scales)

--// Types
export type GuiJoystick = {
	StickImage: string,
	RimImage: string,
	ImageType: Enum.ResamplerMode?,
	Size: number,
	Position: "AtTouch" | "AtCenter",

	Visibility: "Dynamic" | "Static",
	ActivationButton: TextButton,

	InputBegan: RBXScriptSignal,
	InputChanged: RBXScriptSignal,
	InputEnded: RBXScriptSignal,

	Instance: Frame,
}

type InputCode = Enum.KeyCode | Enum.UserInputType

export type InputAction = {
	Name: string,
	KeyInputs: {
		Keyboard: { InputCode },
		Gamepad: { InputCode },
	},
	Callback: () -> any?,
	Priority: number?,
	IsEnabled: () -> boolean,

	Enable: (self: InputAction) -> nil,
	Disable: (self: InputAction) -> nil,
	Refresh: (self: InputAction) -> nil,
	GetMobileInput: (self: InputAction) -> ImageButton | GuiJoystick?,
	SetPriority: (self: InputAction, priority: number | Enum.ContextActionPriority) -> nil,
	SetKeybinds: (self: InputAction, bindGroup: "Gamepad" | "Keyboard", ...InputCode) -> nil,
	AddKeybinds: (self: InputAction, bindGroup: "Gamepad" | "Keyboard", ...InputCode) -> nil,
	RemoveKeybinds: (self: InputAction, bindGroup: "Gamepad" | "Keyboard", ...InputCode) -> nil,
	ReplaceKeybinds: (self: InputAction, bindGroup: "Gamepad" | "Keyboard", keybindsTable: { InputCode }) -> nil,
}

export type ActionGroup = {
	Name: string,
	Actions: { [string]: InputAction },
	IsEnabled: boolean,
	Enable: (self: ActionGroup, index: any?) -> nil,
	Disable: (self: ActionGroup, index: any?) -> nil,
}

type InputType = "Keyboard" | "Gamepad" | "Touch"
type GamepadType = "Ps4" | "Xbox"?

export type InputSource = {
	Type: InputType,
	GamepadType: GamepadType,
	LastGamepadInput: InputObject?,
}

local CUSTOM_GAMEPAD_GUI = true

--// Services
local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

--// Instances
local Player: Player = Players.LocalPlayer
local inputServiceGui: ScreenGui = Instance.new("ScreenGui")
local inputTypeChanged = Instance.new("BindableEvent")

--// Values
local stepped: RBXScriptConnection?

local selectionImage
local hideSelection

local lastInputType: string?
local lastGamepadType: string?
local lastGamepadInput: InputObject?

local globalInputService = {
	InputTypeChanged = inputTypeChanged.Event :: RBXScriptSignal,
	GetInputSource = function(self): InputSource
		return {
			Type = self._inputType,
			GamepadType = self._inputType == "Gamepad" and self._gamepadType,
			LastGamepadInput = lastGamepadInput,
		}
	end,

	inputIcons = lists.inputIcons,

	inputActions = {} :: { [string]: InputAction },
	actionGroups = {} :: { [string]: ActionGroup },

	_inputType = "Keyboard" :: InputType,
	_gamepadType = "Xbox" :: GamepadType,
}

local ps4Keys = lists.ps4Keys

local xboxKeys = lists.xboxKeys

--// Functions

local function createCustomGamepadGui()
	-- Essentials
	selectionImage = Instance.new("ImageLabel")
	selectionImage.Parent = inputServiceGui
	selectionImage.Image = "rbxassetid://94490241725589"
	selectionImage.BackgroundTransparency = 1
	selectionImage.ScaleType = Enum.ScaleType.Slice
	selectionImage.SliceCenter = Rect.new(30, 30, 295, 295)
	selectionImage.SliceScale = 0.5
	selectionImage.ResampleMode = Enum.ResamplerMode.Pixelated
	selectionImage.ImageTransparency = 0.5

	-- Hide Default UI
	hideSelection = Instance.new("ImageLabel")
	hideSelection.BackgroundTransparency = 1
	hideSelection.ImageTransparency = 1

	-- Extra
	local centerImage = Instance.new("ImageLabel")
	centerImage.BackgroundTransparency = 1
	centerImage.Parent = selectionImage
	centerImage.Image = "rbxassetid://78657964270656"
	centerImage.ResampleMode = Enum.ResamplerMode.Pixelated
	centerImage.ScaleType = Enum.ScaleType.Fit
	centerImage.AnchorPoint = Vector2.new(0.5, 0.5)
	centerImage.Position = UDim2.fromScale(0.5, 0.5)
	centerImage.Size = UDim2.fromOffset(100, 100)

	local uiSizeConstraint = Instance.new("UISizeConstraint")
	uiSizeConstraint.Parent = centerImage
	uiSizeConstraint.MinSize = Vector2.new(25, 25)
end

local function setGamepadType(lastInput)
	local inputName = UserInputService:GetStringForKeyCode(lastInput.KeyCode)

	if table.find(ps4Keys, inputName) then
		globalInputService._gamepadType = "Ps4"
	elseif table.find(xboxKeys, inputName) then
		globalInputService._gamepadType = "Xbox"
	end
end

function globalInputService:CheckKeyPrompts()
	for _, image: ImageLabel in ipairs(CollectionService:GetTagged("KeyPrompt")) do
		local iconKey

		local key = image:GetAttribute("Key")
		local button = image:GetAttribute("Button")
		local inputName = image:GetAttribute("InputName")

		if inputName and globalInputService.inputActions[inputName] then
			iconKey = globalInputService.inputActions[inputName].KeyInputs[globalInputService._inputType][1].Name
		end

		if
			(globalInputService._inputType == "Gamepad" and button)
			or (globalInputService._inputType == "Keyboard" and key)
		then
			iconKey = globalInputService._inputType == "Gamepad" and button or key
		elseif inputName and globalInputService.inputActions[inputName] then
			iconKey = globalInputService.inputActions[inputName].KeyInputs[globalInputService._inputType][1].Name
		end

		if not iconKey then
			image.Visible = false
			continue
		end

		image.Visible = true

		local imageId

		if globalInputService.inputIcons.Misc[iconKey] then
			imageId = globalInputService.inputIcons.Misc[iconKey]
		elseif globalInputService.inputIcons.Keyboard[iconKey] then
			imageId = globalInputService.inputIcons.Keyboard[iconKey]
		elseif globalInputService.inputIcons[globalInputService._gamepadType][iconKey] then
			imageId = globalInputService.inputIcons[globalInputService._gamepadType][iconKey]
		else
			imageId = globalInputService.inputIcons.Misc.Unknown
		end

		image.Image = imageId and "rbxassetid://" .. imageId or ""
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
		globalInputService._inputType = "Touch"
		return
	end

	if lastInput.UserInputType.Name:find("Gamepad") then
		globalInputService._inputType = "Gamepad"
		setGamepadType(lastInput)
		lastGamepadInput = lastInput
	else
		globalInputService._inputType = "Keyboard"
	end

	if lastInputType ~= globalInputService._inputType or lastGamepadType ~= globalInputService._gamepadType then
		globalInputService:CheckKeyPrompts()
		inputTypeChanged:Fire(globalInputService._inputType, lastInputType, globalInputService._gamepadType)
	end

	lastInputType = globalInputService._inputType
	lastGamepadType = globalInputService._gamepadType
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
	if not selectionImage then
		return
	end

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

function globalInputService.CreateJoystick(

	stickImage: string?,
	rimImage: string?,
	activationButton: TextButton?,
	size: number?,
	position: "AtTouch" | "AtCenter"?,
	visibility: "Dynamic" | "Static"?
): GuiJoystick
	local inputBegan = Instance.new("BindableEvent")
	local inputChanged = Instance.new("BindableEvent")
	local inputEnded = Instance.new("BindableEvent")

	local joystick: GuiJoystick = {
		StickImage = stickImage or "",
		RimImage = rimImage or "",
		ImageType = nil,

		Size = size or 0.1,
		Position = position or "AtTouch",
		Visibility = visibility or "Dynamic",
		ActivationButton = activationButton or Instance.new("TextButton"),

		InputBegan = inputBegan.Event,
		InputChanged = inputChanged.Event,
		InputEnded = inputEnded.Event,

		Instance = Instance.new("Frame"),
	}

	local stick = Instance.new("ImageLabel")
	local rim = Instance.new("ImageLabel")
	local onMouseMoved

	local function updateJoystick()
		rim.Size = UDim2.fromScale(joystick.Size, joystick.Size)
		rim.Image = joystick.RimImage
		stick.Image = joystick.StickImage
		stick.ResampleMode = joystick.ImageType or Enum.ResamplerMode.Default
	end

	local proxy = setmetatable({}, {
		__index = joystick,
		__newindex = function(_, key, value)
			local oldValue = joystick[key]
			if oldValue == value then
				return
			end -- No change detected
			joystick[key] = value

			if key ~= "StickImage" and key ~= "RimImage" and key ~= "Size" and key ~= "ImageType" then
				return
			end

			updateJoystick()
		end,
		__metatable = "Locked", -- Prevent external access to the metatable
	})

	joystick.ActivationButton.Parent = joystick.Instance
	joystick.ActivationButton.ZIndex = 2
	joystick.ActivationButton.BackgroundTransparency = 1
	joystick.ActivationButton.TextTransparency = 1

	stick.Parent = rim
	stick.Name = "Stick"
	stick.Size = UDim2.fromScale(1, 1)
	stick.BackgroundTransparency = 1
	stick.AnchorPoint = Vector2.new(0.5, 0.5)
	stick.Position = UDim2.fromScale(0.5, 0.5)

	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.Parent = rim

	rim.Parent = joystick.Instance
	rim.Name = "Rim"
	rim.BackgroundTransparency = 1
	rim.AnchorPoint = Vector2.new(0.5, 0.5)

	joystick.Instance.Parent = inputServiceGui
	joystick.Instance.Name = "Joystick"
	joystick.Instance.BackgroundTransparency = 1
	joystick.Instance.Size = UDim2.fromScale(1, 1)

	updateJoystick()

	if joystick.Visibility == "Static" then
		rim.Visible = true
	end

	joystick.ActivationButton.MouseButton1Down:Connect(function(initX, initY)
		if joystick.Visibility == "Dynamic" then
			rim.Visible = true
		end

		if joystick.Position == "AtTouch" then
			rim.Position = UDim2.fromOffset(initX, initY - 58)
		elseif joystick.Position == "AtCenter" then
			rim.Position = UDim2.fromOffset(
				joystick.ActivationButton.AbsolutePosition.X,
				joystick.ActivationButton.AbsolutePosition.Y
			)
		end

		inputChanged:Fire(Vector2.zero)

		stick.Position = UDim2.fromScale(0.5, 0.5)

		onMouseMoved = joystick.ActivationButton.MouseMoved:Connect(function(x, y)
			local relativePosition = Vector2.new(x - initX, y - initY)
			local length = relativePosition.Magnitude
			local maxLength = rim.AbsoluteSize.X / 2

			length = math.min(length, maxLength)
			relativePosition = relativePosition.Unit * length

			stick.Position = UDim2.new(
				0,
				relativePosition.X + rim.AbsoluteSize.X / 2,
				0,
				relativePosition.Y + rim.AbsoluteSize.Y / 2
			)

			local inputPosition = (relativePosition / rim.AbsoluteSize.Y) * 2
			inputPosition = Vector2.new(inputPosition.X, -inputPosition.Y)

			inputChanged:Fire(inputPosition)
		end)
	end)

	local function onTouchEnd()
		if onMouseMoved then
			onMouseMoved:Disconnect()
		end

		if joystick.Visibility == "Dynamic" then
			rim.Visible = false
		end

		inputChanged:Fire(Vector2.zero)
		inputEnded:Fire()
	end

	joystick.ActivationButton.MouseButton1Up:Connect(onTouchEnd)
	joystick.ActivationButton.MouseLeave:Connect(onTouchEnd)

	return proxy
end

function globalInputService.CreateInputAction(
	inputName: string,
	func: () -> any?,
	keyboardInputs: { InputCode } | InputCode,
	gamepadInputs: ({ InputCode } | InputCode)?,
	mobileInputType: "Button" | "Joystick"?
): InputAction
	if typeof(keyboardInputs) ~= "table" then
		keyboardInputs = { keyboardInputs }
	end

	if typeof(gamepadInputs) ~= "table" then
		gamepadInputs = { gamepadInputs }
	end

	local mobileJoystick: GuiJoystick?
	local inputIsEnabled = false
	local newInput: InputAction = {
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

		Enable = function(self: InputAction)
			local callback = self.Callback
			inputIsEnabled = true

			local allInputs = {}
			for _, input in ipairs(self.KeyInputs.Gamepad) do
				table.insert(allInputs, input)
			end

			for _, input in ipairs(self.KeyInputs.Keyboard) do
				table.insert(allInputs, input)
			end

			if self.Priority then
				ContextActionService:BindActionAtPriority(
					self.Name,
					function(_, inputState: Enum.UserInputState, input: InputObject)
						return callback(inputState, input)
					end,
					mobileInputType == "Button",
					self.Priority,
					table.unpack(allInputs)
				)
			else
				ContextActionService:BindAction(
					self.Name,
					function(_, inputState: Enum.UserInputState, input: InputObject)
						return callback(inputState, input)
					end,
					mobileInputType == "Button",
					table.unpack(allInputs)
				)
			end

			if mobileInputType == "Joystick" then
				mobileJoystick = globalInputService.CreateJoystick().InputChanged:Connect(function(position)
					callback(Enum.UserInputState.Change, {
						Position = position,
					})
				end)
			end
		end,

		Disable = function(self: InputAction)
			inputIsEnabled = false
			local mobileInput = self:GetMobileInput()
			if mobileInput then
				mobileInput:Destroy()
			end

			ContextActionService:UnbindAction(self.Name)
		end,

		Refresh = function(self: InputAction)
			if not inputIsEnabled then
				return
			end

			self:Disable()
			self:Enable()
		end,

		GetMobileInput = function(self: InputAction)
			if mobileInputType == "Button" then
				return ContextActionService:GetButton(self.Name)
			elseif mobileInputType == "Joystick" then
				return mobileJoystick
			end

			return
		end,

		SetPriority = function(self: InputAction, priority: number | Enum.ContextActionPriority)
			self.Priority = tonumber(priority) and priority or priority.Value
			self:Refresh()
		end,

		SetKeybinds = function(self: InputAction, bindGroup: "Gamepad" | "Keyboard", ...)
			self.KeyInputs[bindGroup] = { ... }
			self:Refresh()
		end,
		AddKeybinds = function(self: InputAction, bindGroup: "Gamepad" | "Keyboard", ...)
			local keybinds = { ... }
			for _, keybind: Enum.KeyCode | Enum.UserInputType in ipairs(keybinds) do
				table.insert(self.KeyInputs[bindGroup], keybind)
			end
			self:Refresh()
		end,
		RemoveKeybinds = function(self: InputAction, bindGroup: "Gamepad" | "Keyboard", ...)
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
		ReplaceKeybinds = function(self: InputAction, bindGroup: "Gamepad" | "Keyboard", keybindsTable: { InputCode })
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

	globalInputService.inputActions[inputName] = newInput
	newInput:Enable()

	return newInput
end

function globalInputService.CreateActionGroup(name: string): ActionGroup
	local newScale = scales.new()
	local actionGroup: ActionGroup = {
		Name = name,
		Actions = {},
		IsEnabled = not newScale:Check(),
		Enable = function(self, index: any?)
			newScale:Remove(index)
		end,

		Disable = function(self, index: any?)
			newScale:Add(index)
		end,
	}

	newScale.Changed:Connect(function(isDisabled)
		actionGroup.IsEnabled = not isDisabled

		if actionGroup.IsEnabled then
			for _, action: InputAction in pairs(actionGroup.Actions) do
				action:Enable()
			end
		else
			for _, action: InputAction in pairs(actionGroup.Actions) do
				action:Disable()
			end
		end
	end)

	globalInputService.actionGroups[name] = actionGroup

	return actionGroup
end

function globalInputService.AddToActionGroup(actionGroup: ActionGroup | string, ...)
	if typeof(actionGroup) == "string" then
		local actionGroupName = actionGroup
		actionGroup = globalInputService.actionGroups[actionGroupName]

		if not actionGroup then
			actionGroup = globalInputService.CreateActionGroup(actionGroupName)
		end
	end

	local actions = { ... }

	for _, action in ipairs(actions) do
		actionGroup.Actions[action.Name] = action
	end
end

function globalInputService:SelectGui(frame: GuiObject)
	if self:GetInputSource().Type == "Gamepad" then
		GuiService:Select(frame)
	end
end

function globalInputService.StartGame()
	globalInputService:CheckKeyPrompts()
end

--// Main //--
UserInputService.InputBegan:Connect(setInputType)
UserInputService.InputChanged:Connect(setInputType)

inputServiceGui.Parent = Player.PlayerGui

if not CUSTOM_GAMEPAD_GUI then
	return globalInputService
end

createCustomGamepadGui()

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

inputServiceGui.DisplayOrder = 100
inputServiceGui.Name = "InputServiceGui"
Player:WaitForChild("PlayerGui").SelectionImageObject = hideSelection

return globalInputService
