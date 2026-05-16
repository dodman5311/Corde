local Elevator = {}

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local GlobalInputService = require(script.Parent.GlobalInputService)
local MouseOver = require(script.Parent.MouseOver)
local Scales = require(script.Parent.Scales)
local Timer = require(script.Parent.Timer)
local Util = require(script.Parent.Util)

--// Instances
local Player = Players.LocalPlayer
local UI = StarterGui.Elevator
local Assets = ReplicatedStorage.Assets
local Sounds = Assets.Sounds
local NetSounds = Sounds.NET
local Camera = workspace.CurrentCamera

-- UI Instances
local Frame = UI.Frame
local Floors = Frame.Floors
local FloorDesc = Frame.FloorDescription
local Logo = Frame.Logo
local LoadingFrame = Frame.Loading
local Edges = Frame.Edges
local BackgroundImage = Frame.BackgroundDetails
local Background = UI.Background

--// Modules

--// Values
local MenuIsOpen = false
local CurrentDisplayedKey = ""

local glitchTimer = Timer:new("ElevatorGlitchTimer", 0.2, function()
	FloorDesc.LayerKeyName.Text = CurrentDisplayedKey
end)

local c = 0

--// Functions
local function ResetButtons()
	for _, button in ipairs(Floors:GetChildren()) do
		if button:GetAttribute("LayerKey") == workspace:GetAttribute("CurrentLayerKey") then
			button.YouAreHere.Visible = true
		else
			button.YouAreHere.Visible = false
		end
	end
end

local function ResetGui()
	FloorDesc.Visible = false
	Floors.Visible = false
	Logo.Size = UDim2.fromScale(5.1, 5.1)
	BackgroundImage.Visible = false
	Edges.Visible = false
	Edges.Size = UDim2.fromScale(1.15, 1.15)
	Edges.ImageTransparency = 1
	Background.BackgroundTransparency = 1

	--logo.Grad = -0.15
	Logo.Grad.Offset = Vector2.new(-0.26, 0)

	LoadingFrame.Visible = false
	LoadingFrame.Bar.Size = UDim2.fromScale(0, 1)

	ResetButtons()
	for _, button in ipairs(Floors:GetChildren()) do
		button.Visible = false
	end
end

local function UpdateLayerDescription(layerNumber, layerKey)
	local ti = TweenInfo.new(0.75, Enum.EasingStyle.Quint)

	CurrentDisplayedKey = layerKey
	glitchTimer:Reset()
	glitchTimer:Run()
	Util.tween(FloorDesc.FloorNumbersFrame.Numbers, ti, { Position = UDim2.fromScale(0, -(layerNumber - 1)) })
end

function Elevator:ShowGuiAnimation()
	if MenuIsOpen then
		return
	end

	MenuIsOpen = true
	ResetGui()
	UI.Enabled = true

	Scales.activeScales["InteractDisabled"]:Add("Elevator")

	local ti = TweenInfo.new(0.25, Enum.EasingStyle.Linear)
	local ti_0 = TweenInfo.new(1, Enum.EasingStyle.Quint)
	local ti_1 = TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
	local ti_2 = TweenInfo.new(0.9, Enum.EasingStyle.Quart)
	local ti_3 = TweenInfo.new(0.75, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)

	Util.PlaySound(NetSounds.NetOpen)

	Util.tween(Background, ti, { BackgroundTransparency = 0.05 })
	Edges.Visible = true
	Util.tween(Edges, ti_0, { ImageTransparency = 0, Size = UDim2.fromScale(1, 1) })
	task.wait(0.5)
	task.delay(0.25, function()
		Util.PlaySound(Sounds.VaxNetJingle)
	end)
	Util.tween(Logo.Grad, ti_1, { Offset = Vector2.new(-0.15, 0) }, true)
	Util.flickerUi(LoadingFrame, 0.025, 8, true)
	Util.PlaySound(Sounds.SynthSweep)
	Util.tween(LoadingFrame.Bar, ti_2, { Size = UDim2.fromScale(1, 1) }, true)
	Util.flickerUi(LoadingFrame, 0.025, 8, true)
	Util.tween(Logo, ti_3, { Size = UDim2.fromScale(1, 1) })
	task.wait(0.5)

	Util.flickerUi(BackgroundImage, 0.025, 8, true)
	Util.flickerUi(FloorDesc, 0.025, 8)

	Floors.Visible = true
	for _, button in ipairs(Floors:GetChildren()) do
		Util.flickerUi(button, 0.025, 8, true)
		task.wait(0.1)
	end

	GlobalInputService:SelectGui(Floors)
end

function Elevator:HideGuiAnimation()
	if MenuIsOpen then
		return
	end

	Scales.activeScales["InteractDisabled"]:Remove("Elevator")
	MenuIsOpen = false
end

local function ButtonEntered(button)
	local ti = TweenInfo.new(0.1)

	Util.PlaySound(NetSounds.Select, 0.025)

	Util.tween(button.Parent.Center, ti, { Size = UDim2.fromScale(1.1, 1.1), ImageColor3 = Color3.new(1) })
	Util.tween(button.Parent.YouAreHere, ti, { Size = UDim2.fromScale(1.1, 1.1) })
	UpdateLayerDescription(tonumber(button.Parent.Name), button.Parent:GetAttribute("LayerKey"))
end

local function ButtonLeft(button)
	local ti = TweenInfo.new(0.2)
	Util.tween(button.Parent.Center, ti, { Size = UDim2.fromScale(1, 1), ImageColor3 = Color3.new(1, 1, 1) })
	Util.tween(button.Parent.YouAreHere, ti, { Size = UDim2.fromScale(1, 1) })
end

local function ConnectButtons()
	for _, buttonFrame in ipairs(Floors:GetChildren()) do
		local button = buttonFrame.Button :: TextButton

		local enter, leave = MouseOver.MouseEnterLeaveEvent(button)
		enter:Connect(function()
			ButtonEntered(button)
		end)
		leave:Connect(function()
			ButtonLeft(button)
		end)
	end
end

function Elevator:Init()
	UI.Parent = Player.PlayerGui
	UI.Enabled = false
	ConnectButtons()

	glitchTimer.OnTimerStepped:Connect(function()
		local length = CurrentDisplayedKey:len()

		local baseString = ""

		for _ = 1, length do
			local r = math.random(65, 90)
			baseString = baseString .. string.char(r)
		end

		FloorDesc.LayerKeyName.Text = baseString
	end)

	RunService.RenderStepped:Connect(function(dt)
		c += dt
		if c >= math.pi * 2 then
			c = 0
		end
		local xAngle = math.rad(math.sin(c)) * 10
		local yAngle = math.rad(math.sin(c + 1)) * 10

		local mouse = UserInputService:GetMouseLocation()

		local xposition = mouse.X
		local xsize = Camera.ViewportSize.X
		local xnormalizedPosition = ((-xposition / xsize) + 0.5)

		local yposition = mouse.Y
		local ysize = Camera.ViewportSize.Y
		local ynormalizedPosition = ((-yposition / ysize) + 0.5)

		-- camera.CFrame = camera.CFrame:Lerp(
		-- 	cameraPart.CFrame
		-- 		* CFrame.Angles(
		-- 			math.rad(ynormalizedPosition),
		-- 			math.rad(xnormalizedPosition),
		-- 			math.rad(xnormalizedPosition)
		-- 		)
		-- 		* CFrame.Angles(xAngle, yAngle, xAngle),
		-- 	0.25
		-- )

		-- Edges.Position = Edges.Position:Lerp(
		-- 	UDim2.fromScale(0.5 + ((xnormalizedPosition + xAngle) / 40), 0.5 + ((ynormalizedPosition + yAngle) / 40)),
		-- 	0.1
		-- )]

		Frame.Position = Frame.Position:Lerp(
			UDim2.fromScale(0.5 + ((xnormalizedPosition + xAngle) / 40), 0.5 + ((ynormalizedPosition + yAngle) / 40)),
			0.1
		)

		Edges.Edges_0.Position = Edges.Edges_0.Position:Lerp(
			UDim2.fromScale(0.5 + ((xnormalizedPosition + xAngle) / 30), 0.5 + ((ynormalizedPosition + yAngle) / 30)),
			0.1
		)

		Edges.Edges_1.Position = Edges.Edges_1.Position:Lerp(
			UDim2.fromScale(0.5 + ((xnormalizedPosition + xAngle) / 20), 0.5 + ((ynormalizedPosition + yAngle) / 20)),
			0.1
		)
	end)
end

function Elevator:Start()
	--Start Code
end

--// Main //--
return Elevator
