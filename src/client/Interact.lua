local module = {
	INTERACT_DISTANCE = 4,
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local mouseTarget = Instance.new("ObjectValue")
mouseTarget.Parent = player
mouseTarget.Name = "MouseTarget"

local assets = ReplicatedStorage.Assets
local sounds = assets.Sounds

local camera = workspace.CurrentCamera

local cursorUi

local Client = player.PlayerScripts.Client
local uiAnimationService = require(Client.UIAnimationService)
local inventory = require(Client.Inventory)
local dialogue = require(Client.Dialogue)
local acts = require(Client.Acts)
local actionPrompt = require(Client.ActionPrompt)
local timer = require(Client.Timer)
local util = require(Client.Util)
local globalInputService = require(Client.GlobalInputService)
local objectsView = require(Client.ObjectsView)
local objectFunctions = require(Client.ObjectFucntions)

local interactTimer = timer:new("PlayerInteractionTimer", 0.5)
local rng = Random.new()

local function checkSightline(object: Instance): boolean
	if acts:checkAct("InObjectView") then
		return true
	elseif not object then
		return false
	end

	local character = player.Character
	if not character then
		return false
	end

	local characterPosition = character:GetPivot().Position
	local objectPosition = object:GetPivot().Position

	local rp = RaycastParams.new()
	rp.FilterDescendantsInstances = { character, object }

	local raycast = workspace:Raycast(characterPosition, objectPosition - characterPosition, rp)

	return not raycast
end

local function getMouseHit()
	local cursorLocation = player:GetAttribute("CursorLocation")

	local ray = camera:ViewportPointToRay(cursorLocation.X, cursorLocation.Y)
	local direction = ray.Direction * 600
	local endPoint = ray.Origin + direction
	local hit = CFrame.new(endPoint)

	local raycast = workspace:Raycast(ray.Origin, direction)

	if not raycast then
		return hit
	end

	return CFrame.new(raycast.Position), raycast.Instance
end

local function showInteract(object, cursor)
	cursor.Parent.Center.Visible = false

	cursor.Image.Position = UDim2.fromScale(0, 0)
	cursor.CursorBlue.Image.Position = UDim2.fromScale(0, 0)
	cursor.CursorRed.Image.Position = UDim2.fromScale(0, 0)
	cursor.Visible = true

	cursor.ItemName.Text = object.Name
	cursor.ItemNameRed.Text = object.Name
	cursor.ItemNameBlue.Text = object.Name

	uiAnimationService.PlayAnimation(cursor, 0.025, false, true)
	uiAnimationService.PlayAnimation(cursor.CursorBlue, 0.025, false, true)
	uiAnimationService.PlayAnimation(cursor.CursorRed, 0.025, false, true).OnEnded:Once(function()
		cursor.ItemName.Visible = true
		cursor.ItemNameRed.Visible = true
		cursor.ItemNameBlue.Visible = true
	end)

	cursor.KeyPrompt.Visible = globalInputService.inputType == "Gamepad"
	cursor.KeyPrompt.Image = globalInputService.inputIcons[globalInputService.gamepadType].ButtonA

	cursor.Locked.Visible = object:GetAttribute("Locked")
end

local function hideInteract(cursor)
	cursor.Parent.Center.Visible = true

	cursor.Visible = false
	cursor.Image.Position = UDim2.fromScale(0, 0)
	cursor.CursorBlue.Image.Position = UDim2.fromScale(0, 0)
	cursor.CursorRed.Image.Position = UDim2.fromScale(0, 0)

	cursor.ItemName.Visible = false
	cursor.ItemNameRed.Visible = false
	cursor.ItemNameBlue.Visible = false

	interactTimer:Cancel()
end

local INTEREST_ICON_SPEED = 0.045

local function showInterest(cursor)
	cursor.Parent.Center.Visible = false
	cursor.Image.Position = UDim2.fromScale(0, 0)
	cursor.CursorBlue.Image.Position = UDim2.fromScale(0, 0)
	cursor.CursorRed.Image.Position = UDim2.fromScale(0, 0)
	cursor.Visible = true

	local a1 = uiAnimationService.PlayAnimation(cursor, INTEREST_ICON_SPEED)
	local a2 = uiAnimationService.PlayAnimation(cursor.CursorBlue, INTEREST_ICON_SPEED)
	local a3 = uiAnimationService.PlayAnimation(cursor.CursorRed, INTEREST_ICON_SPEED)

	a1:OnFrameRached(3):Connect(function()
		a1:Pause()
		a2:Pause()
		a3:Pause()
	end)
end

local function hideInterest(cursor)
	cursor.Parent.Center.Visible = true

	uiAnimationService.PlayAnimation(cursor, INTEREST_ICON_SPEED, false, false, 3)
	uiAnimationService.PlayAnimation(cursor.CursorBlue, INTEREST_ICON_SPEED, false, false, 3)
	uiAnimationService.PlayAnimation(cursor.CursorRed, INTEREST_ICON_SPEED, false, false, 3).OnEnded:Connect(function()
		cursor.Visible = false
	end)
end

local function showLocked(cursor: Frame)
	task.spawn(function()
		for _ = 1, 10 do
			cursor.Position = UDim2.fromScale(rng:NextNumber(-0.025, 0.025), rng:NextNumber(-0.025, 0.025))
			task.wait(0.025)
		end

		cursor.Position = UDim2.fromScale(0, 0)
	end)
end

local function checkMouseTargetInteractable(value)
	if not cursorUi then
		return
	end

	local interactUi = cursorUi.Cursor.Interact
	local interestUi = cursorUi.Cursor.Interest

	if value and value:HasTag("Interactable") and checkSightline(value) then
		if value:HasTag("Interest") then
			showInterest(interestUi)
		else
			showInteract(value, interactUi)
		end
	else
		hideInteract(interactUi)
		hideInterest(interestUi)
	end
end

mouseTarget.Changed:Connect(checkMouseTargetInteractable)

function module.UseObject(object)
	if object:FindFirstChild("Module") then
		local objectModule = require(object.Module)
		return objectModule.Use()
	end

	local use = object:GetAttribute("Use")
	if not use then
		return
	end

	return objectFunctions[use](object)
end

local function runTimer(actionName: string, interactionTime: number, func, ...)
	interactTimer.Function = func
	interactTimer.Parameters = { ... }
	interactTimer.WaitTime = interactionTime

	interactTimer:Run()
	actionPrompt.showActionTimer(interactTimer, actionName)
end

local function attemptInteract(object: Instance)
	if not checkSightline(object) then
		return
	end

	if object:GetAttribute("Locked") then
		if object:FindFirstChild("LockedSide") and checkSightline(object.LockedSide) then
			dialogue:EnterDialogue(object.LockedSide)
			return
		end

		local key = object:GetAttribute("Key")
		if key and (key == "" or inventory:RemoveItem(key)) then
			util.PlaySound(sounds.Unlock)
			object:SetAttribute("Locked", false)

			showInteract(object, cursorUi.Cursor.Interact)
			return
		end

		util.PlaySound(sounds.Locked)
		showLocked(cursorUi.Cursor.Interact)
	else
		util.PlaySound(sounds.Interacting, script, 0.05, 0.5)
		runTimer("Interacting", 0.5, module.UseObject, object)
	end
end

local function pickupContainer()
	util.PlaySound(sounds.Collecting, script, 0.05, 0.5)
	runTimer("Collecting", 0.5, function()
		inventory:pickupFromContainer(mouseTarget.Value)
	end)
end

local function InteractiWithObject(object: Instance)
	if objectsView:EnterView(object) or not object:HasTag("Interactable") then
		return
	end

	if object:HasTag("Container") then
		pickupContainer()
	elseif object:HasTag("NPC") or object:HasTag("Interest") then
		dialogue:EnterDialogue(mouseTarget.Value)
	else
		attemptInteract(object)
	end
end

globalInputService.CreateNewInput("Interact", function(state)
	local object = mouseTarget.Value

	if state ~= Enum.UserInputState.Begin or not object or acts:checkAct("Interacting") then
		return
	end

	InteractiWithObject(object)
end, Enum.KeyCode.F, Enum.KeyCode.ButtonA)

local function processCrosshair()
	if not player.Character then
		mouseTarget.Value = nil
		return
	end

	local hit, target = getMouseHit()

	local characterPosition = player.Character:GetPivot().Position
	local v2CharacterPosition = Vector2.new(characterPosition.X, characterPosition.Z)
	local v2CursorPosition = Vector2.new(hit.Position.X, hit.Position.Z)

	local distanceToMouse = (v2CharacterPosition - v2CursorPosition).Magnitude

	if distanceToMouse > module.INTERACT_DISTANCE and not acts:checkAct("InObjectView") then
		mouseTarget.Value = nil
	else
		mouseTarget.Value = target and (target:FindFirstAncestorOfClass("Model") or target)
	end
end

function module.Init()
	cursorUi = player.PlayerGui.Cursor
	RunService.RenderStepped:Connect(processCrosshair)
end

interactTimer.OnEnded:Connect(function()
	acts:removeAct("Interacting")
end)

return module
