local HintSystem = {}

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

--// Instances
local player = Players.LocalPlayer
local assets = ReplicatedStorage.Assets
local gui = assets.Gui
local HintsGui = StarterGui.Hints
HintsGui.Parent = player:WaitForChild("PlayerGui")

--// Modules
local GlobalInputService = require(script.Parent.GlobalInputService)
local Util = require(script.Parent.Util)

--// Values
local DEFAULT_DISPLAY_TIME = 5

function getHintPresets()
	return {
		OpenInventory = {
			KeyPrompts = {
				{ "InputName", "Inventory", "Press   ", 0.425 },
			},
			Message = `Press      to open your inventory.`,
			Color = Color3.fromRGB(35, 255, 235),
		},
		CombineItems = {
			Message = "Sometimes two items can be <b>combined</b> together. Experiment with different items you can <b>combine</b>.",
		},
	}
end
--// Functions

local function showNoteKeyprompts(keyPrompts, hintUi)
	if not keyPrompts then
		return
	end

	for _, prompt in ipairs(keyPrompts) do
		local key, button, preText, yPos = table.unpack(prompt)

		local newPrompt = gui.Keyprompt:Clone()
		newPrompt.Image:AddTag("KeyPrompt")

		if key == "InputName" then
			newPrompt.Image:SetAttribute("InputName", button)
		else
			newPrompt.Image:SetAttribute("Key", key)
			newPrompt.Image:SetAttribute("Button", button)
		end

		newPrompt.Parent = hintUi.Box.Message

		newPrompt.Image.Position = UDim2.fromScale(1, yPos)
		newPrompt.Image.Size = UDim2.fromScale(0.225, 0.225)
		newPrompt.Text = preText

		local setSize = RunService.RenderStepped:Connect(function()
			newPrompt.TextSize = hintUi.Box.Message.TextSize
		end)

		newPrompt.Destroying:Once(function()
			setSize:Disconnect()
		end)
	end

	GlobalInputService:CheckKeyPrompts()
end

local function hideHintUiAnimation(hintUi)
	hintUi.Visible = true
	local ti = TweenInfo.new(0.15, Enum.EasingStyle.Linear)

	Util.tween(hintUi.Bar, ti, { Size = UDim2.fromScale(0.01, 0) })
	Util.flickerUi(hintUi.Box, 0.02, 8)
end

local function showHintUiAnimation(hintUi: GuiObject)
	local ti = TweenInfo.new(0.25, Enum.EasingStyle.Quart)

	hintUi.Size = UDim2.fromScale(0, 0)
	hintUi.Box.Message.Visible = false
	hintUi.Visible = true
	Util.tween(hintUi, ti, { Size = UDim2.fromScale(1, 0) }, false, function()
		if not hintUi.Parent then
			return
		end

		Util.tween(hintUi, ti, { Size = UDim2.fromScale(1, 0.2) })
		hintUi.Box.Message.Visible = true
	end)
end

local function destroyHintUi(hintUi: GuiObject)
	hideHintUiAnimation(hintUi)
	hintUi:Destroy()
end

local function createHintUi(): GuiObject
	local newHintUi = gui.HintBox:Clone()
	newHintUi.Name = "ActiveHint"
	newHintUi.Parent = HintsGui.Frame
	showHintUiAnimation(newHintUi)
	return newHintUi
end

function HintSystem:DisplayHint(message: string, displayTime: number?, color: Color3?, keyPrompts: {}?)
	if not Util.getSetting("Gameplay", "Hints") then
		return
	end

	displayTime = displayTime or DEFAULT_DISPLAY_TIME
	color = color or Color3.fromRGB(255, 200, 0)

	local newHintUi = createHintUi()

	newHintUi.Bar.BackgroundColor3 = color
	newHintUi.Box.Message.Text = message

	showNoteKeyprompts(keyPrompts, newHintUi)

	local setSize = RunService.RenderStepped:Connect(function()
		newHintUi.Box.Message.TextSize = math.floor(newHintUi.Box.Message.AbsoluteSize.X / 10.4)
	end)

	newHintUi.Destroying:Once(function()
		setSize:Disconnect()
	end)

	task.delay(displayTime, destroyHintUi, newHintUi)
end

function HintSystem:DisplayPresetHint(hintIndex: string)
	local presets = getHintPresets()
	local preset = presets[hintIndex]
	if not preset then
		return
	end

	self:DisplayHint(preset.Message, preset["DisplayTime"], preset["Color"], preset["KeyPrompts"])
end

--// Main //--
return HintSystem
