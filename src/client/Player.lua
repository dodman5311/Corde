local module = {
	HUNGER_RATE = 0.1,
	SPRINTING_HUNGER_MULT = 2,
	RAM_RECOVERY_RATE = 0.035,
	IsSprinting = false,
}

local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local moveDirection = Vector2.zero
local logPlayerDirection = 0

local camera = workspace.CurrentCamera
local Client = player.PlayerScripts.Client

local uiAnimationService = require(Client.UIAnimationService)
local inventory = require(Client.Inventory)
local util = require(Client.Util)
local weapons = require(Client.WeaponSystem)
local acts = require(Client.Acts)
local lastHeartbeat = os.clock()
local interact = require(Client.Interact)
local cameraService = require(Client.Camera)
local globalInputService = require(Client.GlobalInputService)

local assets = ReplicatedStorage.Assets
local sounds = assets.Sounds
local models = assets.Models

local logHealth = 0
local logLv = Vector3.zero
local logMousePos = Vector3.zero
local cursorLocation = Vector2.zero

local thumbstick1Pos = Vector3.zero
local thumbstick2Pos = Vector3.zero
local thumbstickLookPos = Vector2.new(1, 1)
local thumbCursorGoal = Vector2.zero

local MOVEMENT_THRESHOLD = 0.5
local THUMBSTICK_THRESHOLD = 0.125
local CURSOR_INTERPOLATION = 0.05
local THUMBSTICK_SNAP_POWER = 0.5
local SNAP_DISTANCE = interact.INTERACT_DISTANCE * 1.65

local WALK_SPEED = 3
local SPRINT_SPEED = 4

local function spawnCharacter()
	local presetCharacter = models.Character
	local character: Model = presetCharacter:Clone()

	player.Character = character
	character.Parent = workspace

	logHealth = character:GetAttribute("Health")

	character:GetAttributeChangedSignal("Health"):Connect(function()
		if character:GetAttribute("Health") <= 0 then
			character:SetAttribute("Health", 0)

			module.toggleSprint(false)
			player.Character = nil
			character:Destroy()

			task.delay(2, function()
				spawnCharacter()
			end)
		end

		if logHealth > character:GetAttribute("Health") then
			util.getRandomChild(sounds.Pain):Play()
		end

		logHealth = character:GetAttribute("Health")
	end)
end

function module:DamagePlayer(damage: number, damageType: string)
	if player.Character:GetAttribute("Hunger") <= 0 then
		damage *= 2
	end

	player.Character:SetAttribute("Health", player.Character:GetAttribute("Health") - damage)
	player.Character:SetAttribute("LastDamageType", damageType)
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

local function getClosestInteractable()
	local character = player.Character
	if not character then
		return
	end

	local closest = math.huge
	local closestDistanceToPlayer = 0
	local closestInteractable
	local pos = Vector2.zero

	for _, interactable in ipairs(CollectionService:GetTagged("Interactable")) do
		local distanceToplayer = (interactable:GetPivot().Position - character:GetPivot().Position).Magnitude
		if distanceToplayer > SNAP_DISTANCE then
			continue
		end

		local vector, onScreen = camera:WorldToViewportPoint(interactable:GetPivot().Position)
		if not onScreen then
			continue
		end

		vector = Vector2.new(vector.X, vector.Y)
		local distanceToCursor = (vector - thumbCursorGoal).Magnitude

		if distanceToCursor < closest then
			closest = distanceToCursor
			closestInteractable = interactable
			closestDistanceToPlayer = distanceToplayer
			pos = vector
		end
	end

	return closestInteractable, closestDistanceToPlayer, pos
end

local function processGamepadCursorSnap()
	if thumbstick2Pos.Magnitude >= THUMBSTICK_THRESHOLD or acts:checkAct("InNet") then
		return
	end
	local interactable, distanceToPlayer, vector = getClosestInteractable()
	if not interactable then
		return
	end

	local inter = (math.abs(distanceToPlayer - SNAP_DISTANCE) * CURSOR_INTERPOLATION) * THUMBSTICK_SNAP_POWER

	cursorLocation = cursorLocation:Lerp(vector, inter)
end

local function updatePlayerDirection()
	if globalInputService.inputType == "Gamepad" then
		thumbCursorGoal = ((thumbstickLookPos / 3) + Vector2.new(0.5, 0.5)) * camera.ViewportSize
		cursorLocation = cursorLocation:Lerp(thumbCursorGoal, CURSOR_INTERPOLATION)
		processGamepadCursorSnap()
	end

	player:SetAttribute("CursorLocation", cursorLocation)

	local character = player.Character
	if not character or acts:checkAct("Paused") then
		return
	end
	local gyro = character:FindFirstChild("Gyro")
	if not gyro then
		return
	end

	local characterPosition = character:GetPivot().Position

	local mousePosition = getMouseHit().Position

	if acts:checkAct("InDialogue") then
		mousePosition = logMousePos
	else
		logMousePos = mousePosition
	end

	local lookPoint = Vector3.new(mousePosition.X, characterPosition.Y, mousePosition.Z)

	gyro.CFrame = CFrame.lookAt(characterPosition, lookPoint)

	local yOrientation = character.PrimaryPart.Orientation.Y
	local sway = logPlayerDirection - yOrientation
	local torsoMotor = character.PrimaryPart.Torso
	local legs = character.Legs

	torsoMotor.C1 = torsoMotor.C1:Lerp(CFrame.new(0, 0, 0) * CFrame.Angles(0, -math.rad(sway * 3), 0), 0.4)

	local difference = (logLv - character:GetPivot().LookVector).Magnitude
	if difference >= 0.3 then
		util.PlaySound(util.getRandomChild(sounds.Movement), script, 0.1)
	end

	logPlayerDirection = yOrientation
	logLv = character:GetPivot().LookVector

	local lookPoint = characterPosition + module.moveUnit

	if module.moveUnit.Magnitude == 0 then
		lookPoint = (character:GetPivot() * CFrame.new(0, 0, -1)).Position
	end

	legs.Gyro.CFrame = CFrame.lookAt(characterPosition, lookPoint) * CFrame.Angles(0, math.rad(90), 0)
end

local function updateDirection(inputState, vector)
	if inputState == Enum.UserInputState.Begin then
		moveDirection += vector
	elseif inputState == Enum.UserInputState.End then
		moveDirection -= vector
	elseif vector then
		moveDirection = vector
	end

	moveDirection = Vector2.new(math.clamp(moveDirection.X, -1, 1), math.clamp(moveDirection.Y, -1, 1))

	local character = player.Character
	if not character then
		return
	end

	local frame = character.Legs.UI.Frame
	local arms = character.Torso.UI.Reload

	if moveDirection.Magnitude > 0 then
		if uiAnimationService.CheckPlaying(frame) then
			return
		end

		uiAnimationService.PlayAnimation(frame, 0.5 / character:GetAttribute("Walkspeed"), true)

		if weapons.weaponUnequipped then
			uiAnimationService.PlayAnimation(arms, 0.5 / character:GetAttribute("Walkspeed"), true)
		end

		sounds.Steps:Resume()
	else
		sounds.Steps:Pause()
		uiAnimationService.StopAnimation(frame)

		if weapons.weaponUnequipped then
			uiAnimationService.StopAnimation(arms)
		end
	end
end

sounds.Steps.DidLoop:Connect(function()
	sounds.Steps.PlaybackSpeed = Random.new():NextNumber(1.2, 1.3)
	if module.IsSprinting then
		sounds.Steps.PlaybackSpeed += 0.2
	end
end)

local function updateCursorData(key)
	if key.KeyCode == Enum.KeyCode.Thumbstick2 then
		thumbstick2Pos = key.Position
	elseif key.KeyCode == Enum.KeyCode.Thumbstick1 then
		thumbstick1Pos = key.Position
	elseif key.UserInputType == Enum.UserInputType.MouseMovement then
		cursorLocation = UserInputService:GetMouseLocation()
	end

	if key.KeyCode ~= Enum.KeyCode.Thumbstick2 and key.KeyCode ~= Enum.KeyCode.Thumbstick1 then
		return
	end

	if thumbstick2Pos.Magnitude >= THUMBSTICK_THRESHOLD then
		thumbstickLookPos = Vector2.new(thumbstick2Pos.X, -thumbstick2Pos.Y)
	elseif thumbstick1Pos.Magnitude >= THUMBSTICK_THRESHOLD then
		local thumbPos = (thumbstick1Pos / 10) * 3
		thumbstickLookPos = Vector2.new(thumbPos.X, -thumbPos.Y)
	end
end

local function movePlayer(state, key)
	if acts:checkAct("InDialogue") then
		moveDirection = Vector2.new(0, 0)
		updateDirection(state, Vector2.new(0, 0))
		return
	end

	if key.KeyCode == Enum.KeyCode.W then
		updateDirection(state, Vector2.new(0, -1))
	elseif key.KeyCode == Enum.KeyCode.S then
		updateDirection(state, Vector2.new(0, 1))
	elseif key.KeyCode == Enum.KeyCode.A then
		updateDirection(state, Vector2.new(-1, 0))
	elseif key.KeyCode == Enum.KeyCode.D then
		updateDirection(state, Vector2.new(1, 0))
	elseif key.KeyCode == Enum.KeyCode.Thumbstick1 then
		local position = Vector2.new(key.Position.X, -key.Position.Y)

		if position.Magnitude < MOVEMENT_THRESHOLD then
			position = Vector2.zero
		end

		updateDirection(state, position)
		--updateCursorData(key)
	end
end

function module.toggleSprint(value)
	local character = player.Character
	if not character then
		module.IsSprinting = false
		return
	end

	if value then
		if character:GetAttribute("Hunger") <= 0 then
			module.IsSprinting = false
			return
		end

		sounds.Steps.PlaybackSpeed = 1.45
		weapons.readyKeyToggle(Enum.UserInputState.End)
	else
		sounds.Steps.PlaybackSpeed = 1.25
	end

	module.IsSprinting = value

	character:SetAttribute("Walkspeed", value and SPRINT_SPEED or WALK_SPEED)
	uiAnimationService.StopAnimation(character.Legs.UI.Frame)

	updateDirection()
end

local function updateSprinting(state)
	if state == Enum.UserInputState.Begin then
		module.toggleSprint(true)
	elseif state == Enum.UserInputState.End then
		module.toggleSprint(false)
	end
end

local function updatePlayerMovement()
	local character = player.Character
	if not character or acts:checkAct("Paused") then
		return
	end

	module.moveUnit = moveDirection.Magnitude ~= 0 and Vector3.new(moveDirection.X, 0, moveDirection.Y).Unit
		or Vector3.zero
	local moveToPoint = module.moveUnit * character:GetAttribute("Walkspeed")

	local walkVelocity = character.WalkVelocity

	if cameraService.mode == "FirstPerson" then
		walkVelocity.VectorVelocity = Vector3.zero
	else
		walkVelocity.VectorVelocity = walkVelocity.VectorVelocity:Lerp(moveToPoint, 0.1)
	end
end

function module.Init()
	spawnCharacter()

	globalInputService.CreateNewInput(
		"Walk",
		movePlayer,
		Enum.KeyCode.W,
		Enum.KeyCode.S,
		Enum.KeyCode.A,
		Enum.KeyCode.D,
		Enum.KeyCode.Thumbstick1
	)

	globalInputService.CreateNewInput("Sprint", updateSprinting, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonR2)

	UserInputService.InputChanged:Connect(updateCursorData)

	RunService:BindToRenderStep("updatePlayerMovement", Enum.RenderPriority.Character.Value, updatePlayerMovement)
	RunService:BindToRenderStep("updatePlayerDirection", Enum.RenderPriority.Character.Value + 1, updatePlayerDirection)
end

RunService.Heartbeat:Connect(function()
	if player.Character and not acts:checkAct("Paused") then
		if player.Character:GetAttribute("Hunger") < 0 then
			player.Character:SetAttribute("Hunger", 0)
			module.toggleSprint(false)
		elseif player.Character:GetAttribute("Hunger") > 100 then
			player.Character:SetAttribute("Hunger", 100)
		elseif player.Character:GetAttribute("Hunger") > 0 then
			local mult = (module.IsSprinting and moveDirection.Magnitude > 0) and module.SPRINTING_HUNGER_MULT or 1

			player.Character:SetAttribute(
				"Hunger",
				player.Character:GetAttribute("Hunger") - ((os.clock() - lastHeartbeat) * (module.HUNGER_RATE * mult))
			)
		end

		if player.Character:GetAttribute("RAM") < 0 then
			player.Character:SetAttribute("RAM", 0)
		elseif player.Character:GetAttribute("RAM") > 1 then
			player.Character:SetAttribute("RAM", 1)
		elseif player.Character:GetAttribute("RAM") < 1 then
			player.Character:SetAttribute(
				"RAM",
				player.Character:GetAttribute("RAM") + ((os.clock() - lastHeartbeat) * module.RAM_RECOVERY_RATE)
			)
		end
	end

	lastHeartbeat = os.clock()
end)

inventory.ItemUsed:Connect(function(use, item, slot)
	if not player.Character or use ~= "Eat" then
		return
	end

	player.Character:SetAttribute("Hunger", player.Character:GetAttribute("Hunger") + item.Value)

	inventory[slot] = nil
end)

player:SetAttribute("CursorLocation", Vector2.zero)
player:SetAttribute("CursorHit", Vector2.zero)
weapons.onWeaponToggled:Connect(function(value)
	if value ~= 0 then
		module.toggleSprint(false)
		return
	end

	local character = player.Character
	if not character then
		return
	end
	uiAnimationService.StopAnimation(character.Legs.UI.Frame)

	updateDirection()
end)

return module
