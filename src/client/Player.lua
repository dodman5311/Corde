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
local cameraShaker = require(Client.CameraShaker)
local haptics = require(Client.Haptics)
local globalInputService = require(Client.GlobalInputService)

local assets = ReplicatedStorage.Assets
local sounds = assets.Sounds
local models = assets.Models
local gui = assets.Gui

local HUD = gui.HUD
HUD.Parent = player.PlayerGui

local cursor = gui.Cursor
cursor.Parent = player.PlayerGui

local logHealth = 0
local logLv = Vector3.zero
local logMousePos = Vector3.zero
local cursorLocation = Vector2.zero

local thumbstick1Pos = Vector3.zero
local thumbstick2Pos = Vector3.zero
local thumbstickLookPos = Vector2.zero
local thumbCursorGoal = Vector2.zero

local MOVEMENT_THRESHOLD = 0.5
local THUMBSTICK_THRESHOLD = 0.25
local CURSOR_INTERPOLATION = 0.05
local THUMBSTICK_SNAP_POWER = 0.5
local SNAP_DISTANCE = interact.INTERACT_DISTANCE * 1.5

local OBJECTVIEW_GAMEPAD_SENSITIVITY = 3

local WALK_SPEED = 2.75
local SPRINT_SPEED = 3.75

local function playerDamaged(character, healthPercent)
	local damageUi = HUD.DamageEffects
	local invertedHealthPercent = math.abs(healthPercent - 1)

	local timeScale = 0.5 + invertedHealthPercent
	local ti = TweenInfo.new(timeScale, Enum.EasingStyle.Linear)

	local glitchToPlay
	local damageSoundFolder

	if healthPercent >= 0.65 then
		glitchToPlay = damageUi.Glitch_HighHealth
		damageSoundFolder = sounds.DamageSounds.HighHealth
	elseif healthPercent >= 0.35 then
		glitchToPlay = damageUi.Glitch_MedHealth
		damageSoundFolder = sounds.DamageSounds.MedHealth
	else
		print("LOW")
		glitchToPlay = damageUi.Glitch_LowHealth
		damageSoundFolder = sounds.DamageSounds.LowHealth
	end

	util.getRandomChild(sounds.Pain):Play()
	util.PlaySound(util.getRandomChild(sounds.Blood), script, 0.1).Volume = invertedHealthPercent
	util.PlaySound(util.getRandomChild(damageSoundFolder), script, 0.1)

	local damageShakeInstance = cameraShaker.CameraShakeInstance.new(invertedHealthPercent * 10, 25, 0, timeScale / 1.5)
	damageShakeInstance.PositionInfluence = Vector3.one * 0.5
	damageShakeInstance.RotationInfluence = Vector3.new(0, 0, 2)

	cameraService.shaker:Shake(damageShakeInstance)
	haptics.hapticPulse(
		globalInputService["LastGamepadInput"],
		Enum.VibrationMotor.Large,
		invertedHealthPercent * 10,
		timeScale / 2,
		"DamageTaken"
	)

	glitchToPlay.Visible = true
	uiAnimationService
		.PlayAnimation(glitchToPlay, timeScale / glitchToPlay.Image:GetAttribute("Frames")).OnEnded
		:Once(function()
			glitchToPlay.Visible = false
		end)

	damageUi.Vignette.ImageTransparency = healthPercent
	HUD.Glitch.Image.ImageTransparency = healthPercent * 2
	util.tween(sounds.Heartbeat, ti, { Volume = math.clamp((invertedHealthPercent - 0.5) * 2, 0, 1) })

	util.tween(damageUi.Vignette, ti, { ImageTransparency = healthPercent * 2 }, false, function()
		local ti2 = TweenInfo.new(6, Enum.EasingStyle.Quart, Enum.EasingDirection.In, 0, false, 8)
		util.tween({ damageUi.Vignette, HUD.Glitch.Image }, ti2, { ImageTransparency = invertedHealthPercent + 0.75 })
		util.tween(sounds.Heartbeat, ti2, { Volume = 0 })
	end, Enum.PlaybackState.Completed)

	if not character.Parent then
		return
	end
end

function module.spawnCharacter()
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
		end

		if character:GetAttribute("Health") < logHealth then
			playerDamaged(character, character:GetAttribute("Health") / character:GetAttribute("MaxHealth"))
		end

		logHealth = character:GetAttribute("Health")
	end)

	return character
end

function module:DamagePlayer(damage: number, damageType: string)
	if player.Character:GetAttribute("Hunger") <= 0 then
		damage *= 2
	end

	player.Character:SetAttribute("Health", player.Character:GetAttribute("Health") - damage)
	player.Character:SetAttribute("LastDamageType", damageType)
end

local function updateCursorUi(cursorLocation)
	local cursorFrame = cursor.Cursor

	cursorFrame.Position = UDim2.fromOffset(cursorLocation.X, cursorLocation.Y)
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

local function updateCursorLocation()
	if globalInputService.inputType == "Gamepad" then
		if acts:checkAct("InObjectView") then
			cursorLocation += thumbstickLookPos * OBJECTVIEW_GAMEPAD_SENSITIVITY
		else
			thumbCursorGoal = ((thumbstickLookPos / 3) + Vector2.new(0.5, 0.5)) * camera.ViewportSize
			cursorLocation = cursorLocation:Lerp(thumbCursorGoal, CURSOR_INTERPOLATION)
		end

		processGamepadCursorSnap()
	end

	player:SetAttribute("CursorLocation", cursorLocation)
	updateCursorUi(cursorLocation)
end

local function updatePlayerDirection()
	updateCursorLocation()

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
	sounds.Steps.PlaybackSpeed = Random.new():NextNumber(1.1, 1.2)
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
	elseif not acts:checkAct("InObjectView") then
		local character = player.Character
		if not character then
			return
		end

		local playerPos = character:GetPivot() * CFrame.new(0, 0, -4).Position
		local viewportPos = camera:WorldToViewportPoint(playerPos)
		local viewportVector2 = Vector2.new(viewportPos.X, viewportPos.Y)

		thumbstickLookPos = (viewportVector2 / camera.ViewportSize) - Vector2.new(0.5, 0.5)
	else
		thumbstickLookPos = Vector2.zero
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

		sounds.Steps.PlaybackSpeed = 1.35
		weapons.readyKeyToggle(Enum.UserInputState.End)
	else
		sounds.Steps.PlaybackSpeed = 1.15
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

function module.OnSpawn()
	local a = uiAnimationService.PlayAnimation(HUD.Glitch, 0.04, true)

	a.OnStepped:Connect(function()
		HUD.Glitch.Visible = math.random(1, 2) ~= 1

		if math.random(1, 3) == 1 then
			HUD.Glitch.Image.ImageColor3 = Color3.fromRGB(math.random(0, 255), math.random(0, 255), math.random(0, 255))
		else
			HUD.Glitch.Image.ImageColor3 = Color3.new(1, 1, 1)
		end
	end)
end

function module.Init()
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
end

RunService.Heartbeat:Connect(function()
	updatePlayerMovement()
	updatePlayerDirection()

	if player.Character and not acts:checkAct("Paused") then
		if player.Character:GetAttribute("Hunger") < 0 then
			player.Character:SetAttribute("Hunger", 0)
			module.toggleSprint(false)
		elseif player.Character:GetAttribute("Hunger") > 100 then
			player.Character:SetAttribute("Hunger", 100)
		elseif player.Character:GetAttribute("Hunger") > 0 then
			local mult = (module.IsSprinting and moveDirection.Magnitude > 0) and module.SPRINTING_HUNGER_MULT or 1
			local rate = (os.clock() - lastHeartbeat) * (module.HUNGER_RATE * mult)

			player.Character:SetAttribute("Hunger", player.Character:GetAttribute("Hunger") - rate)
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

local function eatItem(item, slot)
	player.Character:SetAttribute("Hunger", player.Character:GetAttribute("Hunger") + item.Value)
	util.PlaySound(sounds.Eat, script, 0.15)
	inventory[slot] = nil
end

inventory.ItemUsed:Connect(function(use, item, slot)
	if not player.Character or use ~= "Eat" then
		return
	end

	eatItem(item, slot)
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
