local module = {
	HasNet = false,
}

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local assets = ReplicatedStorage.Assets
local sounds = assets.Sounds.NET
local gui = assets.Gui

local camera = workspace.CurrentCamera
local currentActivePoint = Instance.new("ObjectValue")
local lastActivePoint

local UI = gui.NET
UI.Parent = player.PlayerGui

local Client = player.PlayerScripts.Client
local uiAnimationService = require(Client.UIAnimationService)
local acts = require(Client.Acts)
local actionPrompt = require(Client.ActionPrompt)
local util = require(Client.Util)
local hackingFunctions = require(Client.HackingFunctions)
local globalInputService = require(Client.GlobalInputService)
local inventory = require(Client.Inventory)

local ti = TweenInfo.new(0.25)

local currentInputIndex = 1

local function getKeyCodeFromNumber(number: number | string)
	if tonumber(number) == 1 then
		return globalInputService.inputType ~= "Gamepad" and Enum.KeyCode.One or Enum.KeyCode.DPadUp
	elseif tonumber(number) == 2 then
		return globalInputService.inputType ~= "Gamepad" and Enum.KeyCode.Two or Enum.KeyCode.DPadLeft
	elseif tonumber(number) == 3 then
		return globalInputService.inputType ~= "Gamepad" and Enum.KeyCode.Three or Enum.KeyCode.DPadDown
	elseif tonumber(number) == 4 then
		return globalInputService.inputType ~= "Gamepad" and Enum.KeyCode.Four or Enum.KeyCode.DPadRight
	end
end

local function completePoint(point: BillboardGui)
	local hackUi = point.HackPrompt
	local ti = TweenInfo.new(0.5, Enum.EasingStyle.Quart)

	point:RemoveTag("ActiveNetPoint")
	hackUi.Visible = true
	point.NetLine.Enabled = false

	util.tween(hackUi, ti, { Size = UDim2.fromScale(1.2, 1.2), GroupTransparency = 1 }, false, function()
		point:Destroy()
	end)
end

local function showPointPromt(point: BillboardGui)
	if not point:HasTag("ActiveNetPoint") then
		return
	end

	util.PlaySound(sounds.Select, nil, 0.025)

	local hackUi = point.HackPrompt
	local ti = TweenInfo.new(0.25)

	currentInputIndex = 1

	hackUi.ActionName.Visible = false
	hackUi.ItemName.Visible = false
	hackUi.ActionName.Text = `Action: <font color="rgb(255,240,0)">{point.Adornee:GetAttribute("HackAction")}</font>`
	hackUi.ItemName.Text = point.Adornee.Name

	for _, v in ipairs(hackUi:GetChildren()) do
		if string.match(v.Name, "Keystroke_") then
			local key = math.random(1, 4)
			v:SetAttribute("Key", key)
			v.TextTransparency = 1

			v.Text = globalInputService.inputType == "Gamepad" and "" or key

			v.Size = UDim2.fromScale(0.1, 0.075)
			v.TextColor3 = Color3.new(1, 1, 1)

			v.Prompt.ImageTransparency = 1
			v.Prompt.Visible = globalInputService.inputType == "Gamepad"

			if key == 1 then
				v.Prompt.Image = globalInputService.inputIcons.Misc.Up
			elseif key == 2 then
				v.Prompt.Image = globalInputService.inputIcons.Misc.Left
			elseif key == 3 then
				v.Prompt.Image = globalInputService.inputIcons.Misc.Down
			elseif key == 4 then
				v.Prompt.Image = globalInputService.inputIcons.Misc.Right
			end
		end
	end

	hackUi.Keystroke_1.TextColor3 = Color3.fromRGB(255, 240, 0)
	hackUi.Keystroke_1.Prompt.ImageTransparency = 1

	hackUi.Image.Position = UDim2.fromScale(0, 0)

	local animation = uiAnimationService.PlayAnimation(hackUi, 0.045, false, true)

	animation:OnFrameRached(4):Connect(function()
		if not hackUi.Parent then
			return
		end

		util.tween(
			{ hackUi.Keystroke_1, hackUi.Keystroke_2, hackUi.Keystroke_3, hackUi.Keystroke_4 },
			ti,
			{ TextTransparency = 0 }
		)
		util.tween(
			{ hackUi.Keystroke_2.Prompt, hackUi.Keystroke_3.Prompt, hackUi.Keystroke_4.Prompt },
			ti,
			{ ImageTransparency = 0.75 }
		)
		util.tween({ hackUi.Keystroke_1.Prompt }, ti, { ImageTransparency = 0 })

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

local function hidePointPromt(point: BillboardGui?)
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

	for _, netPoint: BillboardGui in ipairs(CollectionService:GetTagged("ActiveNetPoint")) do -- raycast
		local object: BasePart | Model = netPoint.Adornee

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

	for _, netPoint: BillboardGui in ipairs(validPoints) do
		local object: BasePart | Model = netPoint.Adornee
		local netLine: Beam = netPoint.NetLine
		local netLineAttachment: Attachment? = netLine.Attachment1

		netLine.Attachment0 = character.PrimaryPart.RootAttachment
		netPoint.NetLine.Enabled = true

		if not netLineAttachment then -- if no
			netLineAttachment = Instance.new("Attachment")
			netLineAttachment.Parent = character.PrimaryPart

			netLine.Attachment1 = netLineAttachment
		end

		netLineAttachment.WorldCFrame = object:GetPivot()

		if netPoint == closestPoint then
			netLine.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.5),
				NumberSequenceKeypoint.new(0.8, 0.5),
				NumberSequenceKeypoint.new(0.801, 1),
				NumberSequenceKeypoint.new(1, 1),
			})
			netLine.Color = ColorSequence.new(Color3.fromRGB(135, 255, 255))
			netLine.Width0 = 0.05
			netLine.Width1 = 0.05
		else
			netLine.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.75),
				NumberSequenceKeypoint.new(0.8, 0.75),
				NumberSequenceKeypoint.new(0.801, 1),
				NumberSequenceKeypoint.new(1, 1),
			})
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

	util.PlaySound(sounds.HackSuccess)
	completePoint(point)

	if hackFunction then
		task.spawn(hackFunction, object, point)
	end

	refreshNetPoints()
end

local function checkHackGate(point: BillboardGui)
	local object = point.Adornee

	if object:GetAttribute("HackType") ~= "Prompt" then
		-- gate
		return
	end

	doHackAction(object, point)
end

local function checkKeystrokeInput(state, input)
	local character = player.Character
	local point = currentActivePoint.Value

	if
		state ~= Enum.UserInputState.Begin
		or acts:checkAct("Paused")
		or not character
		or not point
		or not point.Parent
	then
		return
	end

	local object = point.Adornee
	local hackUi = currentActivePoint.Value.HackPrompt
	local keystrokeLabel = hackUi:FindFirstChild("Keystroke_" .. currentInputIndex)

	if not keystrokeLabel or input.KeyCode ~= getKeyCodeFromNumber(keystrokeLabel:GetAttribute("Key")) then
		return
	end

	if character:GetAttribute("RAM") < object:GetAttribute("RamUsage") then
		util.PlaySound(sounds.LowRam, nil, 0.025)
		return
	end

	util.PlaySound(sounds.HackInput, nil, 0.05)

	keystrokeLabel.TextColor3 = Color3.new(1, 1, 1)

	util.tween(keystrokeLabel, TweenInfo.new(0.25), { Size = UDim2.fromScale(0.15, 0.15), TextTransparency = 1 })
	util.tween(keystrokeLabel.Prompt, TweenInfo.new(0.25), { ImageTransparency = 1 })

	currentInputIndex += 1

	keystrokeLabel = hackUi:FindFirstChild("Keystroke_" .. currentInputIndex)
	if not keystrokeLabel then
		checkHackGate(currentActivePoint.Value)
		return
	end
	keystrokeLabel.TextColor3 = Color3.fromRGB(255, 240, 0)
	keystrokeLabel.Prompt.ImageTransparency = 0
end

function module:EnterNetMode()
	if not module.HasNet then
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

	util.PlaySound(sounds.NetClose, nil, 0, 0.25)

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

local function pressNeyKey(state)
	if acts:checkAct("Paused") then
		return
	end

	if acts:checkAct("InNet") and state == Enum.UserInputState.End then
		module:ExitNetMode()
	elseif not acts:checkAct("Interacting") and state == Enum.UserInputState.Begin then
		module:EnterNetMode()
	end
end

module.ToggleNetInput =
	globalInputService.CreateNewInput("OpenNET", pressNeyKey, Enum.KeyCode.Tab, Enum.KeyCode.ButtonL1)
globalInputService.CreateNewInput(
	"EnterHackingInput",
	checkKeystrokeInput,
	Enum.KeyCode.One,
	Enum.KeyCode.Two,
	Enum.KeyCode.Three,
	Enum.KeyCode.Four,
	Enum.KeyCode.DPadDown,
	Enum.KeyCode.DPadLeft,
	Enum.KeyCode.DPadRight,
	Enum.KeyCode.DPadUp
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
