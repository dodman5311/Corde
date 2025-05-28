local module = {}
--// Services
local CollectionService = game:GetService("CollectionService")
local ContentProvider = game:GetService("ContentProvider")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

--// Modules
local signal = require(ReplicatedStorage.Packages.Signal)
local mouseOver = require(script.Parent.MouseOver)
local uiAnimationService = require(script.Parent.UIAnimationService)
local musicService = require(script.Parent.MusicService)
local util = require(script.Parent.Util)
local globalInputService = require(script.Parent.GlobalInputService)
local saveLoad = require(script.Parent.SaveLoad)
local Types = require(ReplicatedStorage.Shared.Types)
local objectFunctions = require(script.Parent.ObjectFunctions)
local gameSettings = require(script.Parent.GameSettings)
local slider = require(script.Parent.Slider)

--// Instances
local assets = ReplicatedStorage.Assets
local gui = assets.Gui
local sounds = assets.Sounds

local titleTheme = assets.Music.MemoriesOfWhatNeverWas
local menu = gui.Menu
menu.Parent = Players.LocalPlayer.PlayerGui

local mainFrame = menu.Main
local saveMenu = menu.Save

--// Values
module.StartEvent = signal.new()
local lockSelection = {}

--// Functions

local hoverFunctions = { -- SAVE MENU
	PlayButton = {
		Enter = function(button: GuiButton)
			local ti = TweenInfo.new(1, Enum.EasingStyle.Exponential)

			local size = button:GetAttribute("DefaultSize")
			util.tween(button, ti, { Size = UDim2.fromScale(size.X.Scale + 0.01, size.Y.Scale + 0.01) })

			local sound = util.PlaySound(sounds.HoverStart)
			sound.PlaybackSpeed = 3
			sound.Volume = 0.1
		end,

		Exit = function(button: GuiButton)
			local ti = TweenInfo.new(0.5, Enum.EasingStyle.Quint)

			util.tween(button, ti, { Size = button:GetAttribute("DefaultSize") })

			if not mainFrame.Visible then
				return
			end

			local sound = util.PlaySound(sounds.HoverStart)
			sound.PlaybackSpeed = 2
			sound.Volume = 0.025
		end,
	},

	SlotButton = {
		Enter = function(button: GuiButton)
			local ti = TweenInfo.new(0.1)
			local buttonImage = button.Parent

			buttonImage.ImageColor3 = Color3.new(1, 1, 1)
			if buttonImage:FindFirstChild("NewGame") then
				buttonImage.NewGame.ImageColor3 = Color3.new(1, 1, 1)
				buttonImage.LoadGame.ImageColor3 = Color3.new(1, 1, 1)
				buttonImage.Delete.ImageColor3 = Color3.new(1, 1, 1)
			end

			util.tween(buttonImage, ti, { Size = UDim2.fromScale(1.005, 1.005) })

			local sound = util.PlaySound(sounds.HoverStart)
			sound.PlaybackSpeed = 3
			sound.Volume = 0.1
		end,

		Exit = function(button: GuiButton)
			local ti = TweenInfo.new(0.5, Enum.EasingStyle.Quint)
			local buttonImage = button.Parent

			buttonImage.ImageColor3 = Color3.fromRGB(255, 92, 92)

			if buttonImage:FindFirstChild("NewGame") then
				buttonImage.NewGame.ImageColor3 = Color3.fromRGB(255, 92, 92)
				buttonImage.LoadGame.ImageColor3 = Color3.fromRGB(255, 92, 92)
				buttonImage.Delete.ImageColor3 = Color3.fromRGB(255, 92, 92)
			end

			util.tween(buttonImage, ti, { Size = UDim2.fromScale(1, 1) })
		end,
	},

	ColorSwitch = {
		Enter = function(button: GuiButton)
			local buttonImage = button.Parent
			buttonImage.ImageColor3 = Color3.new(1, 1, 1)

			local sound = util.PlaySound(sounds.HoverStart)
			sound.PlaybackSpeed = 3
			sound.Volume = 0.1
		end,

		Exit = function(button: GuiButton)
			local buttonImage = button.Parent
			buttonImage.ImageColor3 = Color3.fromRGB(255, 92, 92)
		end,
	},

	DeleteButton = {
		Enter = function(button: GuiButton)
			local buttonImage = button.Parent
			buttonImage.ImageColor3 = Color3.fromRGB(255, 0, 0)

			buttonImage.Parent.SaveSlot.Active = false
		end,

		Exit = function(button: GuiButton)
			local buttonImage = button.Parent
			buttonImage.ImageColor3 = buttonImage.Parent.ImageColor3

			buttonImage.Parent.SaveSlot.Active = true
		end,
	},
}

local function SaveLoadGame(button: GuiButton, newGame: boolean?)
	globalInputService.inputs.MenuBack:Disable()

	saveMenu.Slot_0.SaveSlot.Visible = false
	saveMenu.Slot_1.SaveSlot.Visible = false
	saveMenu.Slot_2.SaveSlot.Visible = false

	util.PlaySound(sounds.CloseSave)
	util.tween(menu.Transition, TweenInfo.new(0.5), { BackgroundTransparency = 0 }, true)

	menu.Save.Visible = false
	menu.Background.Visible = false

	task.wait(1)

	util.tween(menu.Transition, TweenInfo.new(2), { BackgroundTransparency = 1 }, false, function()
		menu.Enabled = false
	end, Enum.PlaybackState.Completed)

	sounds.InventoryAmbience:Stop()
	-- load game

	if newGame == true then
		module.StartEvent:Fire()
		return
	elseif newGame == false then
		return
	end

	local slotIndex = button:GetAttribute("SlotIndex")
	if menu.Save:GetAttribute("Type") == "Load" then
		module.StartEvent:Fire(saveLoad:LoadGame(slotIndex))
	else
		saveLoad:SaveGame(slotIndex)
	end
end

local function lockSelectionTo(buttons: {})
	lockSelection = buttons
	for _, button: GuiButton in ipairs(CollectionService:GetTagged("MenuButton")) do
		if not button:GetAttribute("Hover") then
			continue
		end
		hoverFunctions[button:GetAttribute("Hover")].Exit(button)
	end
end

local function transitionFromMain()
	uiAnimationService.StopAnimation(mainFrame.Logo)
	musicService:StopTrack(0.025)

	mainFrame.Visible = false

	menu.Background.BackgroundColor3 = Color3.new()
end

local buttonFunctions = {
	Start = function()
		transitionFromMain()
		module:ShowSaveMenu("Load")
	end,

	Settings = function()
		transitionFromMain()
		module:ShowSettingsMenu()
	end,

	SaveLoadSlot = SaveLoadGame,
	NewGame = function(button: GuiButton)
		SaveLoadGame(button, true)
	end,

	CloseMenu = function()
		SaveLoadGame(nil, false)
	end,

	DeleteSlot = function(button)
		local label = button.Parent.Parent
		local slotFrame = label.Frame

		local deletePrompt = saveMenu.DeleteConfirm
		deletePrompt.Visible = true

		if globalInputService.inputType == "Gamepad" then
			GuiService:Select(deletePrompt.CancelBtn)
		end

		lockSelectionTo({ deletePrompt.CancelBtn.Button, deletePrompt.ConfirmBtn.Button })

		local cancelConnect
		local confirmConnect

		cancelConnect = deletePrompt.CancelBtn.Button.MouseButton1Click:Connect(function()
			deletePrompt.Visible = false

			cancelConnect:Disconnect()
			confirmConnect:Disconnect()

			lockSelection = {}
		end)

		confirmConnect = deletePrompt.ConfirmBtn.Button.MouseButton1Click:Connect(function()
			deletePrompt.Visible = false

			saveLoad:ClearSave(button:GetAttribute("SlotIndex"))

			slotFrame.Visible = false
			label.NewGame.Visible = true
			label.LoadGame.Visible = false
			label.Delete.Visible = false

			cancelConnect:Disconnect()
			confirmConnect:Disconnect()

			lockSelection = {}
		end)
	end,
}

local function checkLocked(button)
	return #lockSelection > 0 and not table.find(lockSelection, button)
end

local function enableButtonFunctions()
	for _, button: GuiButton in ipairs(CollectionService:GetTagged("MenuButton")) do
		button:SetAttribute("DefaultSize", button.Size)

		local enter, exit = mouseOver.MouseEnterLeaveEvent(button)
		enter:Connect(function()
			if not button:GetAttribute("Hover") or checkLocked(button) or globalInputService.inputType == "Gamepad" then
				return
			end
			hoverFunctions[button:GetAttribute("Hover")].Enter(button)
		end)

		exit:Connect(function()
			if not button:GetAttribute("Hover") or checkLocked(button) or globalInputService.inputType == "Gamepad" then
				return
			end
			hoverFunctions[button:GetAttribute("Hover")].Exit(button)
		end)

		button.SelectionGained:Connect(function()
			if not button:GetAttribute("Hover") or checkLocked(button) then
				return
			end
			hoverFunctions[button:GetAttribute("Hover")].Enter(button)
		end)

		button.SelectionLost:Connect(function()
			if not button:GetAttribute("Hover") or checkLocked(button) then
				return
			end
			hoverFunctions[button:GetAttribute("Hover")].Exit(button)
		end)

		button.MouseButton1Click:Connect(function()
			if not button:GetAttribute("Action") or checkLocked(button) then
				return
			end
			buttonFunctions[button:GetAttribute("Action")](button)
		end)
	end
end

function formatTime(seconds)
	local days = math.floor(seconds / 86400)
	seconds = seconds % 86400

	local hours = math.floor(seconds / 3600)
	seconds = seconds % 3600

	local minutes = math.floor(seconds / 60)

	local parts = {}
	if days > 0 then
		table.insert(parts, days .. "D")
	end
	if hours > 0 then
		table.insert(parts, hours .. "H")
	end
	if minutes > 0 then
		table.insert(parts, minutes .. "M")
	end

	-- If all values are 0, show "0M"
	if #parts == 0 then
		return math.round(seconds) .. "S"
	end

	return table.concat(parts, " ")
end

local function doTransition(transitionTime: number?)
	transitionTime = transitionTime or 2

	util.tween(menu.Transition, TweenInfo.new(0), { BackgroundTransparency = 0 }, true)
	util.tween(menu.Transition, TweenInfo.new(transitionTime, Enum.EasingStyle.Quart), { BackgroundTransparency = 1 })
end

function module:ShowSaveMenu(menuType: "Save" | "Load")
	saveMenu.Slot_0.SaveSlot.Visible = true
	saveMenu.Slot_1.SaveSlot.Visible = true
	saveMenu.Slot_2.SaveSlot.Visible = true

	local ti_1 = TweenInfo.new(2, Enum.EasingStyle.Quart)

	util.PlaySound(sounds.OpenSave)

	menu.Enabled = true
	menu.Background.BackgroundColor3 = Color3.new()
	menu.Background.Visible = true

	globalInputService.inputs.MenuBack:Disable()

	for i = 0, 2 do
		local saveData: Types.GameState = saveLoad:GetSaveData(i)
		local label = saveMenu["Slot_" .. i]
		local saveFrame = label.Frame

		if saveData then
			saveFrame.SaveDate.Text = saveData.Date
			saveFrame.Area.Text = saveData.Area
			saveFrame.TimePlayed.Text = formatTime(saveData.PlayTime)

			saveFrame.Visible = true
			label.LoadGame.Visible = true
			label.NewGame.Visible = false
			label.Delete.Visible = true
		else
			saveFrame.Visible = false
			label.NewGame.Visible = true
			label.LoadGame.Visible = false
			label.Delete.Visible = false
		end
	end

	saveMenu.Visible = true

	saveMenu:SetAttribute("Type", menuType)

	saveMenu.LoadGame.Visible = menuType == "Load"
	saveMenu.NewGame.Visible = menuType == "Load"
	saveMenu.Cancel.Visible = menuType == "Save"
	saveMenu.SaveGame.Visible = menuType == "Save"

	sounds.InventoryAmbience.Volume = 0

	sounds.InventoryAmbience:Play()

	doTransition()
	util.tween(sounds.InventoryAmbience, ti_1, { Volume = 0.1 })

	if globalInputService.inputType == "Gamepad" then
		GuiService:Select(mainFrame)
	end

	globalInputService.inputs.MenuBack:Enable()
end

local function updateValue(label, setting: Types.Setting)
	if setting.Type == "List" then
		if typeof(setting.Value) == "boolean" then
			if setting.Value then
				label.Value.Text = "Enabled"
			else
				label.Value.Text = "Disabled"
			end
		else
			label.Value.Text = tostring(setting.Value)
		end
	elseif setting.Type == "Slider" then
		local pos = setting.Value / setting.Values.Max
		label.Value.Bar.UIGradient.Offset = Vector2.new(pos, 0)
	elseif setting.Type == "KeyInput" then
		label.Value:SetAttribute("Key", setting.Value.Name)
		label.Value:SetAttribute("Button", setting.Value.Name)
		globalInputService:CheckKeyPrompts()
	end
end

local function changeValue(label, setting, value)
	setting.Value = value
	updateValue(label, setting)
	setting:OnChanged()
end

local function connectSettingButtons(label, setting: Types.Setting)
	if setting.Type == "List" then
		label.Value.Next.MouseButton1Click:Connect(function()
			local currentIndex = table.find(setting.Values, setting.Value)
			currentIndex += 1

			if currentIndex > #setting.Values then
				currentIndex = 1
			end

			changeValue(label, setting, setting.Values[currentIndex])
		end)

		label.Value.Prev.MouseButton1Click:Connect(function()
			local currentIndex = table.find(setting.Values, setting.Value)
			currentIndex -= 1

			if currentIndex == 0 then
				currentIndex = #setting.Values
			end

			changeValue(label, setting, setting.Values[currentIndex])
		end)
	elseif setting.Type == "Slider" then
		local stepDelay = 0.05
		local newSlider = slider.new(label.Value, {
			SliderData = {
				Start = setting.Values.Min,
				End = setting.Values.Max,
				Increment = 5,
				DefaultValue = setting.Value,
			},
			MoveInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad),
			Axis = "X",
			Padding = 0,
		})

		newSlider:Track()
		newSlider.Changed:Connect(function(value)
			changeValue(label, setting, value)
		end)

		local nextBtn: ImageButton = label.Value.Next
		local prevBtn: ImageButton = label.Value.Prev

		nextBtn.MouseButton1Down:Connect(function()
			local lastStep = 0
			local startTime = os.clock()
			newSlider:OverrideValue(newSlider:GetValue() + newSlider:GetIncrement())

			local connection = RunService.Heartbeat:Connect(function(dt)
				if os.clock() - startTime < 0.25 then
					return
				end

				lastStep += dt
				if lastStep < stepDelay then
					return
				end

				lastStep = 0
				newSlider:OverrideValue(newSlider:GetValue() + newSlider:GetIncrement())
			end)

			nextBtn.MouseButton1Up:Once(function()
				connection:Disconnect()
			end)

			nextBtn.MouseLeave:Once(function()
				connection:Disconnect()
			end)

			nextBtn.SelectionChanged:Once(function()
				connection:Disconnect()
			end)
		end)

		prevBtn.MouseButton1Down:Connect(function()
			local lastStep = 0
			local startTime = os.clock()
			newSlider:OverrideValue(newSlider:GetValue() - newSlider:GetIncrement())

			local connection = RunService.Heartbeat:Connect(function(dt)
				if os.clock() - startTime < 0.25 then
					return
				end

				lastStep += dt
				if lastStep < stepDelay then
					return
				end

				lastStep = 0
				newSlider:OverrideValue(newSlider:GetValue() - newSlider:GetIncrement())
			end)

			prevBtn.MouseButton1Up:Once(function()
				connection:Disconnect()
			end)

			prevBtn.MouseLeave:Once(function()
				connection:Disconnect()
			end)

			prevBtn.SelectionChanged:Once(function()
				connection:Disconnect()
			end)
		end)
	elseif setting.Type == "KeyInput" then
		local btn: ImageButton = label.Value
		btn.MouseButton1Click:Connect(function()
			--btn.Active = false
			btn.Interactable = false
			globalInputService.inputs.MenuBack:Disable()

			UserInputService.InputBegan:Once(function(input)
				if string.match(input.UserInputType.Name, "MouseButton") then
					input = input.UserInputType
				else
					input = input.KeyCode
				end

				changeValue(label, setting, input)

				btn.Interactable = true
				--btn.Active = true
				globalInputService.inputs.MenuBack:Enable()
			end)
		end)
	end
end

local function loadSettings(settingGroup: {})
	menu.Settings.Groups.Visible = false
	menu.Settings.SettingGroup.Visible = true

	for _, child in ipairs(menu.Settings.SettingGroup:GetChildren()) do
		if not child:IsA("TextLabel") then
			continue
		end

		child:Destroy()
	end

	for _, setting: Types.Setting in ipairs(settingGroup) do
		local newLabel = gui.SettingLabels:FindFirstChild(setting.Type):Clone()
		newLabel.Parent = menu.Settings.SettingGroup
		newLabel.Text = setting.Name

		updateValue(newLabel, setting)

		if setting.Type == "Slider" then
			local pos = setting.Value / setting.Values.Max
			newLabel.Value.Slider.Position = UDim2.fromScale(pos, 0.5)
		end

		connectSettingButtons(newLabel, setting)
	end
end

local function loadSettingGroups()
	local settingsMenu = menu.Settings

	for _, child in ipairs(settingsMenu.Groups:GetChildren()) do
		if not child:IsA("TextButton") then
			continue
		end

		child:Destroy()
	end

	for _, settingGroup in ipairs(gameSettings) do
		local newGroupButton = gui.SettingLabels.SettingGroup:Clone()
		newGroupButton.Parent = settingsMenu.Groups
		newGroupButton.Text = settingGroup.Name
		newGroupButton.MouseButton1Click:Connect(function()
			doTransition(1)
			loadSettings(settingGroup)
		end)
	end
end

function module:ShowSettingsMenu()
	menu.Enabled = true
	menu.Background.BackgroundColor3 = Color3.new()
	menu.Background.Visible = true

	menu.Settings.Visible = true

	doTransition()

	menu.Settings.Groups.Visible = true
	menu.Settings.SettingGroup.Visible = false

	loadSettingGroups()

	if globalInputService.inputType == "Gamepad" then
		GuiService:Select(mainFrame)
	end
end

function module:ShowTitleScreen()
	menu.Background.BackgroundColor3 = Color3.new(1, 1, 1)

	doTransition(4)

	SoundService.AmbientReverb = Enum.ReverbType.Arena
	uiAnimationService.PlayAnimation(mainFrame.Logo, 0.05, true)
	titleTheme.TimePosition = 22.9
	musicService:PlayTrack(titleTheme.Name, 0)

	menu.Save.Visible = false
	menu.Settings.Visible = false
	menu.Main.Visible = true

	if globalInputService.inputType == "Gamepad" then
		GuiService:Select(mainFrame)
	end
end

function module:ShowDisclaimer()
	util.tween(menu.Transition, TweenInfo.new(0), { BackgroundTransparency = 0 }, true)

	util.tween(menu.Graphics, TweenInfo.new(1), { TextTransparency = 0 }, true)
	task.wait(3)

	util.tween(menu.Graphics, TweenInfo.new(1), { TextTransparency = 1 }, true)
end

function module.Init()
	task.spawn(function()
		module:ShowDisclaimer()
		module:ShowTitleScreen()
	end)
	enableButtonFunctions()

	globalInputService.CreateNewInput("MenuBack", function(inputState)
		if inputState ~= Enum.UserInputState.Begin then
			return
		end

		if menu.Save:GetAttribute("Type") == "Save" then
			buttonFunctions.CloseMenu()
			return
		end

		if menu.Settings.SettingGroup.Visible then
			module:ShowSettingsMenu()
		elseif not menu.Main.Visible then
			module:ShowTitleScreen()
		end
	end, Enum.KeyCode.Backspace, Enum.KeyCode.ButtonB)
end

objectFunctions.SaveGameEvent:Connect(function()
	module:ShowSaveMenu("Save")
end)

return module
