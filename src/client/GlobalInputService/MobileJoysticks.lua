export type GuiJoystick = {
	StickImage: string,
	RimImage: string,
	ImageType: Enum.ResamplerMode?,
	Size: number,
	PositionType: "AtTouch" | "AtCenter",

	Visibility: "Dynamic" | "Static",
	ActivationButton: TextButton,

	KeyCode: Enum.KeyCode,
	InputBegan: RBXScriptSignal<InputObject>,
	InputChanged: RBXScriptSignal<InputObject>,
	InputEnded: RBXScriptSignal<InputObject>,

	Destroy: (self: GuiJoystick) -> any?,

	Instance: Frame,
}

local mobileJoysticks = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local JOYSTICK_TWEEN_TIME = 0.25

function mobileJoysticks.setJoystickVisibility(value)
	for _, joystick: GuiJoystick in ipairs(mobileJoysticks) do
		joystick.Instance.Visible = value
	end
end

function mobileJoysticks.new(activationButton: TextButton?): GuiJoystick
	local inputBegan = Instance.new("BindableEvent")
	local inputChanged = Instance.new("BindableEvent")
	local inputEnded = Instance.new("BindableEvent")

	local joystick: GuiJoystick = {
		StickImage = "rbxassetid://502107146",
		RimImage = "rbxassetid://12201347372",
		ImageType = nil,

		Size = 0.1,
		PositionType = "AtTouch",
		Visibility = "Dynamic",
		ActivationButton = activationButton or Instance.new("TextButton"),
		KeyCode = Enum.KeyCode.Thumbstick1,
		InputBegan = inputBegan.Event,
		InputChanged = inputChanged.Event,
		InputEnded = inputEnded.Event,

		Destroy = function(self)
			table.remove(mobileJoysticks, table.find(mobileJoysticks, self))
			self.Instance:Destroy()
			self = nil
		end,

		Instance = Instance.new("Frame"),
	}

	local joystickInputObject = {
		Delta = Vector3.zero,
		KeyCode = joystick.KeyCode,
		Position = Vector3.zero,
		UserInputState = Enum.UserInputState.None,
		UserInputType = Enum.UserInputType.Touch,
	}
	local lastPosition = joystickInputObject.Position

	local function updateInputObject(position, state)
		joystickInputObject.KeyCode = joystick.KeyCode
		joystickInputObject.Position = position
		joystickInputObject.UserInputState = state

		joystickInputObject.Delta = joystickInputObject.Position - lastPosition
		lastPosition = joystickInputObject.Position
	end

	local stick = Instance.new("ImageLabel")
	local rim = Instance.new("ImageLabel")
	local onTouchChanged

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

	joystick.Instance.Name = "Joystick"
	joystick.Instance.BackgroundTransparency = 1
	joystick.Instance.Size = UDim2.fromScale(1, 1)

	updateJoystick()

	if joystick.Visibility == "Static" then
		rim.Visible = true
	end

	local ti = TweenInfo.new(JOYSTICK_TWEEN_TIME, Enum.EasingStyle.Quart)
	local returnTween = TweenService:Create(stick, ti, { Position = UDim2.fromScale(0.5, 0.5) })
	local showTweenA = TweenService:Create(stick, ti, { ImageTransparency = 0 })
	local showTweenB = TweenService:Create(rim, ti, { ImageTransparency = 0 })

	local hideTweenA = TweenService:Create(stick, ti, { ImageTransparency = 1 })
	local hideTweenB = TweenService:Create(rim, ti, { ImageTransparency = 1 })

	hideTweenA.Completed:Connect(function(state)
		if state ~= Enum.PlaybackState.Completed then
			return
		end

		rim.Visible = false
	end)

	rim.Position = UDim2.fromOffset(
		joystick.ActivationButton.AbsolutePosition.X + (joystick.ActivationButton.AbsoluteSize.X / 2),
		joystick.ActivationButton.AbsolutePosition.Y + (joystick.ActivationButton.AbsoluteSize.Y / 2)
	)

	local function onTouchEnd()
		if onTouchChanged then
			onTouchChanged:Disconnect()
		end

		if joystick.Visibility == "Dynamic" then
			hideTweenA:Play()
			hideTweenB:Play()
		end

		updateInputObject(Vector3.zero, Enum.UserInputState.End)
		inputChanged:Fire(joystickInputObject)
		inputEnded:Fire(joystickInputObject)

		returnTween:Play()
	end

	joystick.ActivationButton.MouseButton1Down:Connect(function(initX, initY)
		local initMouseLocation = UserInputService:GetMouseLocation()
		--print(initX)
		if joystick.Visibility == "Dynamic" then
			rim.Visible = true
			showTweenA:Play()
			showTweenB:Play()
		end

		if joystick.PositionType == "AtTouch" then
			TweenService:Create(rim, ti, { Position = UDim2.fromOffset(initMouseLocation.X, initMouseLocation.Y - 58) })
				:Play()
		elseif joystick.PositionType == "AtCenter" then
			rim.Position = UDim2.fromOffset(
				joystick.ActivationButton.AbsolutePosition.X + (joystick.ActivationButton.AbsoluteSize.X / 2),
				joystick.ActivationButton.AbsolutePosition.Y + (joystick.ActivationButton.AbsoluteSize.Y / 2)
			)
		end

		stick.Position = UDim2.fromScale(0.5, 0.5)

		updateInputObject(Vector3.zero, Enum.UserInputState.Begin)
		inputBegan:Fire(joystickInputObject)

		UserInputService.TouchStarted:Once(function(touchInput)
			onTouchChanged = touchInput.Changed:Connect(function()
				local state = touchInput.UserInputState

				if state == Enum.UserInputState.Change then
					local mouseLocation = Vector2.new(touchInput.Position.X, touchInput.Position.Y + 58) --UserInputService:GetMouseLocation()
					local relativePosition = mouseLocation - initMouseLocation --Vector2.new(x - initX, y - initY)
					local length = relativePosition.Magnitude
					local maxLength = rim.AbsoluteSize.X / 2

					returnTween:Cancel()

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

					updateInputObject(Vector3.new(inputPosition.X, inputPosition.Y, 0), Enum.UserInputState.Change)
					inputChanged:Fire(joystickInputObject)
				elseif state == Enum.UserInputState.End then
					onTouchEnd()
				end
			end)
		end)
	end)

	table.insert(mobileJoysticks, joystick)

	return proxy
end

return mobileJoysticks
