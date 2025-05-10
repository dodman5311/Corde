local module = {}
--// Services
local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

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

--// Instances
local assets = ReplicatedStorage.Assets
local gui = assets.Gui
local sounds = assets.Sounds

local titleTheme = assets.Music.MemoriesOfWhatNeverWas
local menu: ScreenGui = gui.Menu
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

local buttonFunctions = {
	Start = function()
		uiAnimationService.StopAnimation(mainFrame.Logo)
		musicService:StopTrack(0.025)

		util.tween(menu.Transition, TweenInfo.new(0), { BackgroundTransparency = 0 })
		mainFrame.Visible = false

		menu.Background.BackgroundColor3 = Color3.new()
		task.wait(2)
		module:ShowSaveMenu("Load")
	end,

	SaveLoadSlot = SaveLoadGame,
	NewGame = function(button: GuiButton)
		SaveLoadGame(button, true)
	end,

	CloseMenu = function(button: GuiButton)
		SaveLoadGame(button, false)
	end,

	DeleteSlot = function(button: GuiButton)
		local label: ImageLabel = button.Parent.Parent
		local slotFrame = label.Frame

		local deletePrompt = saveMenu.DeleteConfirm
		deletePrompt.Visible = true

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
			if not button:GetAttribute("Hover") or checkLocked(button) then
				return
			end
			hoverFunctions[button:GetAttribute("Hover")].Enter(button)
		end)

		exit:Connect(function()
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

function module:ShowSaveMenu(menuType: "Save" | "Load")
	saveMenu.Slot_0.SaveSlot.Visible = true
	saveMenu.Slot_1.SaveSlot.Visible = true
	saveMenu.Slot_2.SaveSlot.Visible = true

	local ti_1 = TweenInfo.new(2, Enum.EasingStyle.Quart)

	util.PlaySound(sounds.OpenSave)

	menu.Enabled = true
	menu.Background.BackgroundColor3 = Color3.new()
	menu.Background.Visible = true

	for i = 0, 2 do
		local saveData: Types.GameState = saveLoad:GetSaveData(i)
		local label: ImageLabel = saveMenu["Slot_" .. i]
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

	menu.Transition.BackgroundTransparency = 0
	sounds.InventoryAmbience.Volume = 0

	sounds.InventoryAmbience:Play()

	util.tween(menu.Transition, ti_1, { BackgroundTransparency = 1 })
	util.tween(sounds.InventoryAmbience, ti_1, { Volume = 0.1 })
end

function module:ShowTitleScreen()
	menu.Transition.BackgroundTransparency = 0

	util.tween(menu.Graphics, TweenInfo.new(1), { TextTransparency = 0 }, true)
	task.wait(3)

	util.tween(menu.Graphics, TweenInfo.new(1), { TextTransparency = 1 }, true)
	util.tween(menu.Transition, TweenInfo.new(4), { BackgroundTransparency = 1 })

	SoundService.AmbientReverb = Enum.ReverbType.Arena
	uiAnimationService.PlayAnimation(mainFrame.Logo, 0.05, true)
	titleTheme.TimePosition = 22.9
	musicService:PlayTrack(titleTheme.Name, 0)

	task.delay(0.5, function()
		if globalInputService.inputType == "Gamepad" then
			GuiService:Select(mainFrame)
		end
	end)
end

function module.Init()
	task.spawn(module.ShowTitleScreen)
	enableButtonFunctions()
end

objectFunctions.SaveGameEvent:Connect(function()
	module:ShowSaveMenu("Save")
end)

return module
