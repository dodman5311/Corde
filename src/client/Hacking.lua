local module = {}

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer

local assets = ReplicatedStorage.Assets
local sounds = assets.Sounds.NET
local gui = assets.Gui

local camera = workspace.CurrentCamera
local currentActivePoint = Instance.new("ObjectValue")
local lastActivePoint

local UI = StarterGui.NET
UI.Parent = player.PlayerGui

local Client = player.PlayerScripts.Client
local actionPrompt = require(Client.ActionPrompt)
local acts = require(Client.Acts)
local globalInputService = require(Client.GlobalInputService)
local hackingFunctions = require(Client.HackingFunctions)
local inventory = require(Client.Inventory)
local uiAnimationService = require(Client.UIAnimationService)
local util = require(Client.Util)

local ti = TweenInfo.new(0.25)

local currentInputIndex = 1
local currentInput = ""

local keyboard = {
	Enum.KeyCode.One,
	Enum.KeyCode.Two,
	Enum.KeyCode.Three,
	Enum.KeyCode.Four,
}
local gamepad = {
	Enum.KeyCode.DPadUp,
	Enum.KeyCode.DPadLeft,
	Enum.KeyCode.DPadDown,
	Enum.KeyCode.DPadRight,
}

local function getNumberFromSequence(point)
	return tonumber(string.sub(point:GetAttribute("Sequence"), currentInputIndex, currentInputIndex))
end

local function getNumberFromKeyCode(keycode: Enum.KeyCode)
	local list = globalInputService:GetInputSource().Type == "Gamepad" and gamepad or keyboard
	return table.find(list, keycode)
end

local function deregisterPoint(point)
	point:RemoveTag("ActiveNetPoint")
	point.HackPrompt.Visible = true
	point.NetLine.Enabled = false
end

local function completePoint(point)
	local hackUi = point.HackPrompt
	local ti = TweenInfo.new(0.5, Enum.EasingStyle.Quart)

	util.PlaySound(sounds.HackSuccess)

	deregisterPoint(point)

	util.tween(hackUi, ti, { Size = UDim2.fromScale(1.2, 1.2), GroupTransparency = 1 }, false, function()
		point:Destroy()
	end)
end

local function failNetPoint(point)
	local hackUi = point.HackPrompt
	local ti = TweenInfo.new(0.5, Enum.EasingStyle.Quart)
	local ti_0 = TweenInfo.new(0.5, Enum.EasingStyle.Elastic)

	util.PlaySound(sounds.HackFailure)

	deregisterPoint(point)

	hackUi.Position = UDim2.fromScale(0.4, 0.5)

	util.tween(hackUi, ti_0, { Position = UDim2.fromScale(0.5, 0.5) })
	util.tween(hackUi, ti, { GroupTransparency = 1 }, false, function()
		point:Destroy()
	end)
end

local function createKeyLabel(point)
	local number = getNumberFromSequence(point)

	local keyLabel = gui.Keystroke:Clone()
	keyLabel.Parent = point.HackPrompt
	keyLabel.ImageTransparency = 1

	keyLabel:SetAttribute("Key", keyboard[number].Name)
	keyLabel:SetAttribute("Button", gamepad[number].Name)

	if point:GetAttribute("SequenceHidden") then
		keyLabel:SetAttribute("Key", "Unknown")
		keyLabel:SetAttribute("Button", "Unknown")
	end

	keyLabel:AddTag("KeyPrompt")
	globalInputService:CheckKeyPrompts()
	return keyLabel
end

local function showPointPromt(point)
	if not point:HasTag("ActiveNetPoint") then
		return
	end

	util.PlaySound(sounds.Select, 0.025)

	local hackUi = point.HackPrompt
	local ti = TweenInfo.new(0.25)

	currentInputIndex = 1
	currentInput = ""

	hackUi.ActionName.Visible = false
	hackUi.ItemName.Visible = false
	hackUi.ActionName.Text = `Action: <font color="rgb(255,240,0)">{point.Adornee:GetAttribute("HackAction")}</font>`
	hackUi.ItemName.Text = point.Adornee.Name

	local keyLabel = createKeyLabel(point)

	hackUi.Image.Position = UDim2.fromScale(0, 0)

	local animation = uiAnimationService.PlayAnimation(hackUi, 0.045, false, true)

	animation:OnFrameRached(4):Once(function()
		if not hackUi.Parent then
			return
		end

		util.tween({ keyLabel }, ti, { ImageTransparency = 0 })

		util.flickerUi(hackUi.ItemName, 0.035, 5, true)
		util.flickerUi(hackUi.ActionName, 0.035, 5)

		if not hackUi.Parent then
			return
		end

		hackUi.ActionName.Visible = true
		hackUi.ItemName.Visible = true
	end)

	point.HackPrompt.Visible = true
	point.Point.Visible = false

	actionPrompt.showEnergyUsage(point.Adornee:GetAttribute("RamUsage"))
end

local function hidePointPromt(point)
	if not point or not point.Parent then
		return
	end

	if not point:HasTag("ActiveNetPoint") then
		return
	end

	point.HackPrompt.Visible = false
	point.Point.Visible = true
	actionPrompt.hideEnergyUsage()
end

local function placeNetPoint(object: Instance)
	local newNetPoint: BillboardGui = gui.NetPoint:Clone()
	newNetPoint.Parent = object --player.PlayerGui
	newNetPoint:AddTag("ActiveNetPoint")
	newNetPoint.Adornee = object

	if object:GetAttribute("Sequence") then
		newNetPoint:SetAttribute("Sequence", object:GetAttribute("Sequence"))
		newNetPoint:SetAttribute("SequenceHidden", true)
	else
		local sequence = ""

		for _ = 1, 4 do
			sequence = sequence .. tostring(math.random(1, 4))
		end

		newNetPoint:SetAttribute("Sequence", sequence)
	end

	newNetPoint.Enabled = true
end

local function placeNetPoints()
	for _, object in ipairs(CollectionService:GetTagged("Hackable")) do
		if not object:FindFirstAncestor("Workspace") then
			continue
		end
		placeNetPoint(object)
	end
end

local function clearNetPoints()
	for _, object in ipairs(CollectionService:GetTagged("ActiveNetPoint")) do
		if object.NetLine.Attachment1 then
			object.NetLine.Attachment1:Destroy()
		end

		object:Destroy()
	end
end

local function refreshNetPoints()
	clearNetPoints()
	placeNetPoints()
end

-- local function checkSightline(object: Instance): boolean
-- 	if acts:checkAct("InObjectView") then
-- 		return true
-- 	elseif not object then
-- 		return false
-- 	end

-- 	local character = player.Character
-- 	if not character then
-- 		return false
-- 	end

-- 	local characterPosition = character:GetPivot().Position
-- 	local objectPosition = object:GetPivot().Position

-- 	local rp = RaycastParams.new()
-- 	rp.FilterDescendantsInstances = { character, object }

-- 	local raycast = workspace:Raycast(characterPosition, objectPosition - characterPosition, rp)

-- 	return not raycast
-- end

local function getValidNetPoints()
	local character = player.Character
	if not character then
		return
	end

	local closest, closestPoint = math.huge, nil
	local validPoints = {}

	for _, netPoint in ipairs(CollectionService:GetTagged("ActiveNetPoint")) do -- raycast
		local object = netPoint.Adornee

		local vector, onScreen = camera:WorldToViewportPoint(object:GetPivot().Position)
		if not onScreen then
			netPoint.NetLine.Enabled = false
			continue
		end

		-- if not checkSightline(object) then
		-- 	netPoint.NetLine.Enabled = false
		-- 	continue
		-- end

		table.insert(validPoints, netPoint)

		local distanceToCursor = (Vector2.new(vector.X, vector.Y) - player:GetAttribute("CursorLocation")).Magnitude

		if distanceToCursor < closest then
			closest = distanceToCursor
			closestPoint = netPoint
		end
	end

	return validPoints, closestPoint
end

local function drawNetLines(validPoints: {}, closestPoint: BillboardGui)
	local character = player.Character
	if not character then
		return
	end

	for _, netPoint in ipairs(validPoints) do
		local object: BasePart | Model = netPoint.Adornee
		local netLine: Beam = netPoint.NetLine
		local netLineAttachment = netLine.Attachment1

		netLine.Attachment0 = character.PrimaryPart.RootAttachment
		netPoint.NetLine.Enabled = true

		if not netLineAttachment then -- if no
			netLineAttachment = Instance.new("Attachment")
			netLineAttachment.Parent = character.PrimaryPart

			netLine.Attachment1 = netLineAttachment
		end

		netLineAttachment.WorldCFrame = object:GetPivot()

		if netPoint == closestPoint then
			netLine.Transparency = NumberSequence.new {
				NumberSequenceKeypoint.new(0, 0.5),
				NumberSequenceKeypoint.new(0.8, 0.5),
				NumberSequenceKeypoint.new(0.801, 1),
				NumberSequenceKeypoint.new(1, 1),
			}
			netLine.Color = ColorSequence.new(Color3.fromRGB(135, 255, 255))
			netLine.Width0 = 0.05
			netLine.Width1 = 0.05
		else
			netLine.Transparency = NumberSequence.new {
				NumberSequenceKeypoint.new(0, 0.75),
				NumberSequenceKeypoint.new(0.8, 0.75),
				NumberSequenceKeypoint.new(0.801, 1),
				NumberSequenceKeypoint.new(1, 1),
			}
			netLine.Color = ColorSequence.new(Color3.new(1, 1, 1))
			netLine.Width0 = 0.025
			netLine.Width1 = 0.025
		end
	end

	if closestPoint then
		currentActivePoint.Value = closestPoint
	end
end

local function processNet()
	if not acts:checkAct("InNet") then
		return
	end

	local validPoints, closestPoint = getValidNetPoints()
	drawNetLines(validPoints, closestPoint)

	if not player.Character then
		return
	end
	actionPrompt.updateActionValue(player.Character:GetAttribute("RAM"))
end

local function doHackAction(object, point: BillboardGui)
	local character = player.Character

	character:SetAttribute("RAM", character:GetAttribute("RAM") - object:GetAttribute("RamUsage"))

	local hackFunction = hackingFunctions[object:GetAttribute("HackAction")]

	completePoint(point)

	if hackFunction then
		task.spawn(hackFunction, object)
	end

	refreshNetPoints()
end

local function checkHackGate(point: BillboardGui)
	local object = point.Adornee

	if point:GetAttribute("Sequence") ~= currentInput then
		failNetPoint(point)
		refreshNetPoints()
		return
	end

	if object:GetAttribute("HackType") ~= "Prompt" then
		-- gate
		return
	end

	doHackAction(object, point)
end

local function enterKeyStroke(point: BillboardGui, input: InputObject)
	local character = player.Character

	if not character then
		return
	end

	local ti = TweenInfo.new(0.25)
	local object = point.Adornee
	local hackUi = currentActivePoint.Value.HackPrompt
	local keystrokeLabel: ImageLabel = hackUi:FindFirstChild("Keystroke")
	local inputNumber = getNumberFromKeyCode(input.KeyCode)
	local number = getNumberFromSequence(point)

	if not point:GetAttribute("SequenceHidden") and (not keystrokeLabel or inputNumber ~= number) then
		return
	end

	if character:GetAttribute("RAM") < object:GetAttribute("RamUsage") then
		util.PlaySound(sounds.LowRam, 0.025)
		return
	end

	util.PlaySound(sounds.HackInput, 0.05)

	keystrokeLabel.Name = "InputUsed"
	keystrokeLabel:SetAttribute("Key", keyboard[inputNumber].Name)
	keystrokeLabel:SetAttribute("Button", gamepad[inputNumber].Name)

	globalInputService:CheckKeyPrompts()

	util.tween(keystrokeLabel, ti, { Size = UDim2.fromScale(0.175, 0.175), ImageTransparency = 1 }, false, function()
		keystrokeLabel:Destroy()
	end)

	currentInputIndex += 1
	currentInput ..= inputNumber

	if not getNumberFromSequence(point) then
		checkHackGate(currentActivePoint.Value)
		return
	end

	local newPoint = createKeyLabel(point)
	newPoint.Size = UDim2.fromScale(0.05, 0.05)

	util.tween({ newPoint }, ti, { ImageTransparency = 0, Size = UDim2.fromScale(0.11, 0.11) })
end

local function checkKeystrokeInput(state, input)
	local point = currentActivePoint.Value

	if state ~= Enum.UserInputState.Begin or acts:checkAct("Paused") or not point or not point.Parent then
		return
	end

	enterKeyStroke(point, input)
end

function module:EnterNetMode()
	if not player.Character or not player.Character:GetAttribute("HasNet") then
		return
	end

	acts:createAct("InNet")
	actionPrompt.showActionPrompt("RAM")
	placeNetPoints()

	util.PlaySound(sounds.NetOpen)

	util.tween(Lighting.NETColor, ti, {
		TintColor = Color3.fromRGB(185, 255, 250),
		Brightness = 0.35,
		Contrast = 1,
		Saturation = -1,
	})
end

function module:ExitNetMode()
	if not acts:checkAct("InNet") then
		return
	end

	acts:removeAct("InNet")
	actionPrompt.hideActionPrompt()
	actionPrompt.hideEnergyUsage()
	clearNetPoints()

	util.PlaySound(sounds.NetClose, 0, 0.25)

	util.tween(Lighting.NETColor, ti, {
		TintColor = Color3.new(1, 1, 1),
		Brightness = 0,
		Contrast = 0,
		Saturation = 0,
	})
end

function module.Init()
	RunService.RenderStepped:Connect(processNet)
end

local function pressNetKey(state)
	if acts:checkAct("Paused") then
		return
	end

	if acts:checkAct("InNet") and state == Enum.UserInputState.End then
		module:ExitNetMode()
	elseif not acts:checkAct("Interacting") and state == Enum.UserInputState.Begin then
		module:EnterNetMode()
	end
end

module.ToggleNetInput = globalInputService.CreateInputAction(
	"N.E.T",
	pressNetKey,
	util.getSetting("Keybinds", "N.E.T"),
	util.getSetting("Gamepad", "N.E.T")
)

globalInputService.AddToActionGroup(
	"PlayerControl",
	module.ToggleNetInput,
	globalInputService.CreateInputAction(
		"EnterHackingInput",
		checkKeystrokeInput,
		{ Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four },
		{ Enum.KeyCode.DPadDown, Enum.KeyCode.DPadLeft, Enum.KeyCode.DPadRight, Enum.KeyCode.DPadUp }
	)
)

inventory.InvetoryToggled:Connect(function(value)
	if not value then
		return
	end

	module:ExitNetMode()
end)

currentActivePoint.Changed:Connect(function(point)
	hidePointPromt(lastActivePoint)
	showPointPromt(point)

	lastActivePoint = point
end)

return module
