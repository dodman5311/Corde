local module = {}
--// Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

--// Modules
local signal = require(ReplicatedStorage.Packages.Signal)
local mouseOver = require(script.Parent.MouseOver)
local uiAnimationService = require(script.Parent.UIAnimationService)
local musicService = require(script.Parent.MusicService)
local util = require(script.Parent.Util)

--// Instances
local assets = ReplicatedStorage.Assets
local gui = assets.Gui
local sounds = assets.Sounds

local titleTheme = assets.Music.MemoriesOfWhatNeverWas
local mainMenu: ScreenGui = gui.MainMenu
mainMenu.Parent = Players.LocalPlayer.PlayerGui

local mainFrame = mainMenu.Main

--// Values
module.StartEvent = signal.new()

--// Functions

local hoverFunctions = {
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
}

local buttonFunctions = {
	Start = function(button: GuiButton)
		local ti = TweenInfo.new(2, Enum.EasingStyle.Quart)

		uiAnimationService.StopAnimation(mainFrame.Logo)
		musicService:StopTrack(0.025)

		mainMenu.Transition.BackgroundTransparency = 0
		mainFrame.Visible = false
		mainMenu.Background.Visible = false
		task.wait(4)

		util.tween(mainMenu.Transition, ti, { BackgroundTransparency = 1 }, false, function()
			mainMenu.Enabled = false
		end)
		module.StartEvent:Fire()
	end,
}

local function enableButtonFucntions()
	for _, button: GuiButton in ipairs(CollectionService:GetTagged("MenuButton")) do
		button:SetAttribute("DefaultSize", button.Size)

		local enter, exit = mouseOver.MouseEnterLeaveEvent(button)
		enter:Connect(function()
			hoverFunctions[button:GetAttribute("Hover")].Enter(button)
		end)

		exit:Connect(function()
			hoverFunctions[button:GetAttribute("Hover")].Exit(button)
		end)

		button.MouseButton1Click:Connect(function()
			buttonFunctions[button:GetAttribute("Action")](button)
		end)
	end
end

function module:ShowTitleScreen()
	mainMenu.FadeIn.BackgroundTransparency = 0
	util.tween(mainMenu.FadeIn, TweenInfo.new(4), { BackgroundTransparency = 1 })

	SoundService.AmbientReverb = Enum.ReverbType.Arena
	uiAnimationService.PlayAnimation(mainFrame.Logo, 0.05, true)
	titleTheme.TimePosition = 22.9
	musicService:PlayTrack(titleTheme.Name, 0)
end

function module.Init()
	module:ShowTitleScreen()
	enableButtonFucntions()
end

return module
