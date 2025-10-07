local module = {
	HUNGER_RATE = 0.5,
	RAM_RECOVERY_RATE = 0.035,
	IsSprinting = false,

	Stats = {},
}

local AppRatingPromptService = game:GetService("AppRatingPromptService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local moveDirection = Vector2.zero
local logPlayerDirection = 0

local camera = workspace.CurrentCamera
local Client = player.PlayerScripts.Client

local Achievements = require(script.Parent.Achievements)
local acts = require(Client.Acts)
local inventory = require(Client.Inventory)
local uiAnimationService = require(Client.UIAnimationService)
local util = require(Client.Util)
local weapons = require(Client.WeaponSystem)
local lastHeartbeat = os.clock()
local Types = require(ReplicatedStorage.Shared.Types)
local areas = require(Client.Areas)
local cameraService = require(Client.Camera)
local cameraShaker = require(Client.CameraShaker)
local controller = require(player.PlayerScripts.PlayerModule):GetControls()
local dialogue = require(Client.Dialogue)
local globalInputService = require(Client.GlobalInputService)
local haptics = require(Client.Haptics)
local interact = require(Client.Interact)
local net = require(ReplicatedStorage.Packages.Net)
local sequences = require(Client.Sequences)

local assets = ReplicatedStorage.Assets
local sounds = assets.Sounds
local models = assets.Models

local HUD = StarterGui.HUD
HUD.Parent = player:WaitForChild("PlayerGui")

local cursor = StarterGui.Cursor
cursor.Parent = player.PlayerGui

local currentStimEquipped
local logHealth = 0
local logLv = Vector3.zero
local logMousePos = Vector3.zero
local cursorLocation = Vector2.zero

local thumbstick1Pos = Vector3.zero
local thumbstick2Pos = Vector3.zero
local thumbstickLookPos = Vector2.zero
local thumbCursorGoal = Vector2.zero

-- Mobile joysticks --

local lastTouchUp = os.clock()
local lastTouchDown = os.clock()

local mobileJoystickPosition = Vector3.zero
local movementJoystickAction = globalInputService.CreateInputAction("MovementMobileJoystick", function(state, input)
	mobileJoystickPosition = Vector3.new(input.Position.X, 0, -input.Position.Y)
end, Enum.KeyCode.Unknown, nil, "Joystick")

local movementJoystick: globalInputService.GuiJoystick = movementJoystickAction:GetMobileInput()

movementJoystick.ActivationButton.Size = UDim2.fromScale(0.4, 0.5)
movementJoystick.ActivationButton.AnchorPoint = Vector2.new(0, 1)
movementJoystick.ActivationButton.Position = UDim2.fromScale(0, 0.9)

movementJoystick.StickImage = "rbxassetid://132521821681421"
movementJoystick.RimImage = "rbxassetid://128397619482738"
movementJoystick.ImageType = Enum.ResamplerMode.Pixelated
movementJoystick.Size = 0.25
movementJoystick.PositionType = "AtTouch"
movementJoystick.Visibility = "Dynamic"
movementJoystick.KeyCode = Enum.KeyCode.Thumbstick1

----

local lookJoystickAction = globalInputService.CreateInputAction("LookMobileJoystick", function(state, input)
	-- if state == Enum.UserInputState.Begin then
	-- 	if os.clock() - lastTouchUp <= 0.15 then --and os.clock() - lastTouchDown <= 0.25 then
	-- 		--weapons.readyKeyToggle(state, input)
	-- 	end
	-- 	lastTouchDown = os.clock()
	-- elseif state == Enum.UserInputState.End then
	-- 	--weapons.readyKeyToggle(state, input)
	-- 	lastTouchUp = os.clock()
	-- end

	if globalInputService.inputActions["Fire Weapon"].IsEnabled() then
		--weapons.fireKeyToggle(state, input)

		if state == Enum.UserInputState.Begin then
			--print(lastTouchUp - lastTouchDown)
			if os.clock() - lastTouchUp <= 0.15 then
				weapons.fireKeyToggle(state, input)
			end

			lastTouchDown = os.clock()
		elseif state == Enum.UserInputState.End then
			if os.clock() - lastTouchDown <= 0.15 then
				weapons.fireKeyToggle(Enum.UserInputState.Begin, input)
			end

			weapons.fireKeyToggle(state, input)
			lastTouchUp = os.clock()
		end
	end
end, Enum.KeyCode.Unknown, nil, "Joystick")

local lookJoystick: globalInputService.GuiJoystick = lookJoystickAction:GetMobileInput()

lookJoystick.ActivationButton.Size = UDim2.fromScale(0.4, 0.5)
lookJoystick.ActivationButton.AnchorPoint = Vector2.new(1, 1)
lookJoystick.ActivationButton.Position = UDim2.fromScale(1, 0.9)

lookJoystick.StickImage = "rbxassetid://132521821681421"
lookJoystick.RimImage = "rbxassetid://128397619482738"
lookJoystick.ImageType = Enum.ResamplerMode.Pixelated
lookJoystick.Size = 0.4
lookJoystick.PositionType = "AtCenter"
lookJoystick.Visibility = "Static"
lookJoystick.KeyCode = Enum.KeyCode.Thumbstick2

weapons.onWeaponToggled:Connect(function(value)
	lookJoystick.ReturnToZero = value == 0

	if value == 0 then
		lookJoystick.StickImage = "rbxassetid://132521821681421"
	else
		lookJoystick.StickImage = "rbxassetid://109944710788886"
	end
end)

----------------------

local MOVEMENT_THRESHOLD = 0.5
local THUMBSTICK_THRESHOLD = 0.25
local CURSOR_INTERPOLATION = 0.05
local SNAP_DISTANCE = interact.INTERACT_DISTANCE

local OBJECTVIEW_GAMEPAD_SENSITIVITY = 3

local WALK_SPEED = 2.75
local SPRINT_SPEED = 3.85

local function checkEquippedStem(healthPercent: number)
	if not healthPercent then
		return
	end

	healthPercent *= 100

	if not currentStimEquipped or not currentStimEquipped.InUse then
		return
	end

	if healthPercent > currentStimEquipped.Value.ActivateValue then
		return
	end

	currentStimEquipped.InUse = false
	module.ConsumeItem(currentStimEquipped, "Heal")
end

local function showHealthAmountFeedback(timeScale, healthPercent)
	local damageUi = HUD.DamageEffects
	local ti = TweenInfo.new(timeScale, Enum.EasingStyle.Linear)

	damageUi.Vignette.ImageTransparency = healthPercent
	HUD.Glitch.Image.ImageTransparency = healthPercent * 2

	util.tween(damageUi.Vignette, ti, { ImageTransparency = healthPercent * 2 }, false, function()
		local ti2 = TweenInfo.new(6, Enum.EasingStyle.Quart, Enum.EasingDirection.In, 0, false, 8)
		util.tween({ damageUi.Vignette, HUD.Glitch.Image }, ti2, { ImageTransparency = healthPercent + 0.5 })
		util.tween(sounds.Heartbeat, ti2, { Volume = 0 })
	end, Enum.PlaybackState.Completed)
end

local function playerDamaged(character, healthPercent, damageDealt)
	local damageUi = HUD.DamageEffects
	local invertedHealthPercent = math.abs(healthPercent - 1)

	local timeScale = 0.5 + invertedHealthPercent
	local ti = TweenInfo.new(timeScale, Enum.EasingStyle.Linear)

	local glitchToPlay
	local damageSoundFolder

	character:SetAttribute("Hunger", character:GetAttribute("Hunger") - damageDealt / 2.5)

	if healthPercent >= 0.65 then
		glitchToPlay = damageUi.Glitch_HighHealth
		damageSoundFolder = sounds.DamageSounds.HighHealth
	elseif healthPercent >= 0.35 then
		glitchToPlay = damageUi.Glitch_MedHealth
		damageSoundFolder = sounds.DamageSounds.MedHealth
	else
		glitchToPlay = damageUi.Glitch_LowHealth
		damageSoundFolder = sounds.DamageSounds.LowHealth
	end

	util.PlayFrom(character, util.getRandomChild(sounds.Pain))
	util.PlayFrom(character, util.getRandomChild(sounds.Blood), 0.1).Volume = invertedHealthPercent
	util.PlayFrom(character, util.getRandomChild(damageSoundFolder), 0.1)

	local damageShakeInstance = cameraShaker.CameraShakeInstance.new(invertedHealthPercent * 10, 25, 0, timeScale / 1.5)
	damageShakeInstance.PositionInfluence = Vector3.one * 0.5
	damageShakeInstance.RotationInfluence = Vector3.new(0, 0, 2)

	cameraService.shaker:Shake(damageShakeInstance)
	haptics.hapticPulse(
		globalInputService:GetInputSource().LastGamepadInput,
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

	util.tween(sounds.Heartbeat, ti, { Volume = math.clamp((invertedHealthPercent - 0.5) * 2, 0, 1) })

	showHealthAmountFeedback(timeScale, healthPercent)

	if not character.Parent then
		return
	end

	checkEquippedStem(healthPercent)
end

local function playerHealed(character, healthPercent)
	if not character.Parent then
		return
	end

	local healUi = HUD.HealEffect
	local damageUi = HUD.DamageEffects

	local ti = TweenInfo.new(0.1)
	local ti_0 = TweenInfo.new(2, Enum.EasingStyle.Quart)
	local ti2 = TweenInfo.new(3, Enum.EasingStyle.Quart)

	util.tween(healUi, ti, { ImageTransparency = 0 }, false, function()
		util.tween(healUi, ti_0, { ImageTransparency = 1 })
	end)

	util.tween({ damageUi.Vignette, HUD.Glitch.Image }, ti2, { ImageTransparency = healthPercent + 0.5 })
	util.tween(sounds.Heartbeat, ti2, { Volume = 0 })
end

local function placePlayerBody(character)
	local newBody = models.DeadPlayer:Clone()
	newBody.Parent = workspace
	newBody:PivotTo(character:GetPivot())

	local body: Part = newBody.Body
	body.AssemblyLinearVelocity = body.CFrame.LookVector * -50

	local deathSound = util.getRandomChild(sounds.Female_Death)
	local bloodSound = util.getRandomChild(sounds.Blood)

	util.PlayFrom(character, deathSound, 0.05, 0.2)
	util.PlayFrom(character, bloodSound, 0.15)
end

local function playerDied(character)
	if currentStimEquipped and currentStimEquipped.Value.ActivateValue == 0 then
		return
	end

	globalInputService.actionGroups.PlayerControl:Disable()
	Achievements:AwardAchievement(Achievements.Ids.SeriousExceptionError)

	character:SetAttribute("Health", 0)
	cameraService.followViewDistance.current = 0

	module.toggleSprint(false)
	placePlayerBody(character)

	sequences:beginSequence("deathScreen")
	sequences.OnEnded:Once(function()
		net:RemoteEvent("RejoinPlace"):FireServer()
	end)

	player.Character = nil
	sounds.Steps:Stop()
	character:Destroy()
end

local function getHealthPercentage(character)
	if not character then
		return
	end

	return character:GetAttribute("Health") / character:GetAttribute("MaxHealth")
end

function module.spawnCharacter(saveData: Types.GameState?)
	local presetCharacter = models.Character
	local character: Model = presetCharacter:Clone()

	player.Character = character
	if saveData then
		character:PivotTo(CFrame.new(saveData.PlayerStats.Position))
		character:SetAttribute("Health", saveData.PlayerStats.Health)
	end
	character.Parent = workspace
	showHealthAmountFeedback(0, character:GetAttribute("Health") / character:GetAttribute("MaxHealth"))

	logHealth = character:GetAttribute("Health")

	character:GetAttributeChangedSignal("Health"):Connect(function()
		local health = character:GetAttribute("Health")
		local healthPercent = getHealthPercentage(character)
		local change = logHealth - health

		if health < logHealth then
			playerDamaged(character, healthPercent, change)
		elseif health > logHealth then
			playerHealed(character, healthPercent)
		end

		if health <= 0 then
			playerDied(character)
		end

		logHealth = health
	end)

	return character
end

function module:ChangePlayerHealth(amount: number, changeType: "Set" | "Add" | "Subtract"?): number
	changeType = changeType or "Set"

	local currentHealth = player.Character:GetAttribute("Health")
	local maxHealth = player.Character:GetAttribute("MaxHealth")

	if changeType == "Set" then
		player.Character:SetAttribute("Health", math.clamp(amount, 0, maxHealth))
	elseif changeType == "Add" then
		player.Character:SetAttribute("Health", math.clamp(currentHealth + amount, 0, maxHealth))
	elseif changeType == "Subtract" then
		player.Character:SetAttribute("Health", math.clamp(currentHealth - amount, 0, maxHealth))
	end

	return player.Character:GetAttribute("Health")
end

function module:DamagePlayer(damage: number, damageType: string)
	if player:GetAttribute("GodMode") then
		return
	end

	if workspace:GetAttribute("Difficulty") == 0 then -- @Difficulty handle damage taken
		damage *= 0.75
	elseif workspace:GetAttribute("Difficulty") == 2 then
		damage *= 1.75
	end

	if player.Character:GetAttribute("Hunger") <= 0 then
		damage *= 2
	end

	self:ChangePlayerHealth(damage, "Subtract")
	player.Character:SetAttribute("LastDamageType", damageType)
end

function module:EnableHacking()
	if player.Character then
		player.Character:SetAttribute("HasNet", true)
	end
end

function module.ConsumeItem(item, use)
	if not player.Character then
		return
	end

	if item.Value.Hunger then
		player.Character:SetAttribute("Hunger", player.Character:GetAttribute("Hunger") + item.Value.Hunger)
	end

	if item.Value.Health then
		module:ChangePlayerHealth(item.Value.Health, "Add")
	end

	util.PlaySound(sounds[use], 0.05)
	inventory:RemoveItem(item.Name)
end

local function updateCursorUi(cursorLocation)
	local cursorFrame = cursor.Cursor

	cursorFrame.Position = UDim2.fromOffset(cursorLocation.X, cursorLocation.Y)
end

local function getClosestInteractable()
	local character = player.Character
	if not character or interact.Disabled:Check() then
		return
	end

	local closest = math.huge
	local closestDistanceToPlayer = 0
	local closestInteractable
	local pos = Vector2.zero

	for _, interactable in ipairs(CollectionService:GetTagged("Interactable")) do
		if not interactable:FindFirstAncestor("Workspace") then
			continue
		end

		local distanceToplayer = (interactable:GetPivot().Position - interact.MouseHitLocation).Magnitude --character:GetPivot().Position).Magnitude
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
	if
		thumbstick2Pos.Magnitude >= THUMBSTICK_THRESHOLD
		or thumbstick1Pos.Magnitude >= THUMBSTICK_THRESHOLD
		or acts:checkAct("InNet")
	then
		return
	end
	local interactable, distanceToCursor, vector = getClosestInteractable()

	if not interactable then
		return
	end

	local inter = (math.abs(distanceToCursor - SNAP_DISTANCE) * CURSOR_INTERPOLATION)
		* util.getSetting("Accessibility", "Gamepad Assistance Strength")

	cursorLocation = cursorLocation:Lerp(vector, inter)
end

local function updateCursorLocation()
	if globalInputService:GetInputSource().Type == "Keyboard" then
		cursorLocation = UserInputService:GetMouseLocation()
	else
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

	if acts:checkAct("InDialogue") then
		interact.MouseHitLocation = logMousePos
	else
		logMousePos = interact.MouseHitLocation
	end

	local lookPoint = Vector3.new(interact.MouseHitLocation.X, characterPosition.Y, interact.MouseHitLocation.Z)

	gyro.CFrame = CFrame.lookAt(characterPosition, lookPoint)

	local yOrientation = character.PrimaryPart.Orientation.Y
	local sway = logPlayerDirection - yOrientation
	local torsoMotor = character.PrimaryPart.Torso
	local legs = character.Legs

	torsoMotor.C1 = torsoMotor.C1:Lerp(CFrame.new(0, 0, 0) * CFrame.Angles(0, -math.rad(sway * 3), 0), 0.4)

	local difference = (logLv - character:GetPivot().LookVector).Magnitude
	if difference >= 0.3 then
		util.PlayFrom(character, util.getRandomChild(sounds.Movement), 0.1)
	end

	logPlayerDirection = yOrientation
	logLv = character:GetPivot().LookVector

	local legPoint = characterPosition + module.moveUnit

	if module.moveUnit.Magnitude == 0 then
		legPoint = (character:GetPivot() * CFrame.new(0, 0, -1)).Position
	end

	legs.Gyro.CFrame = CFrame.lookAt(characterPosition, legPoint) * CFrame.Angles(0, math.rad(90), 0)
end

local function updateDirection(vector)
	if vector then
		moveDirection = vector
	end

	local character = player.Character
	if not character then
		return
	end

	local frame = character.Legs.UI.Frame
	local arms = character.Torso.UI.Reload

	if moveDirection.Magnitude > 0 and not acts:checkAct("Paused") then
		if uiAnimationService.CheckPlaying(frame) then
			return
		end

		uiAnimationService.PlayAnimation(frame, 0.5 / character:GetAttribute("Walkspeed"), true)

		if weapons.weaponUnequipped then
			uiAnimationService.PlayAnimation(arms, 0.5 / character:GetAttribute("Walkspeed"), true)
		end

		util.PlayingSounds[sounds.Steps] = character
		sounds.Steps:Resume()
	else
		util.PlayingSounds[sounds.Steps] = nil
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

local function updateGamepadCursorData(key)
	if key.KeyCode == Enum.KeyCode.Thumbstick2 then
		thumbstick2Pos = key.Position
	elseif key.KeyCode == Enum.KeyCode.Thumbstick1 then
		thumbstick1Pos = key.Position
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
		local direction = thumbstickLookPos.Magnitude > 0 and thumbstickLookPos.Unit * 0.2 or thumbstickLookPos
		thumbstickLookPos = direction
	else
		thumbstickLookPos = Vector2.zero
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
			character.ShadowBox.Sprint.Enabled = false
			return
		end

		sounds.Steps.PlaybackSpeed = 1.35
		sounds.Steps.RollOffMaxDistance = 5
		sounds.Steps.Volume = 0.75
		weapons.readyKeyToggle(Enum.UserInputState.End)
	else
		sounds.Steps.Volume = 0.5
		sounds.Steps.RollOffMaxDistance = 2.5
		sounds.Steps.PlaybackSpeed = 1.15
		character.ShadowBox.Sprint.Enabled = false
	end

	module.IsSprinting = value

	character:SetAttribute("Walkspeed", value and SPRINT_SPEED or WALK_SPEED)
	uiAnimationService.StopAnimation(character.Legs.UI.Frame)

	updateDirection()
end

local function checkIsSprinting()
	local character = player.Character
	if not character then
		return
	end

	local sprinting = module.IsSprinting
		and moveDirection.Magnitude > 0
		and character.PrimaryPart.AssemblyLinearVelocity.Magnitude > 3
	character.ShadowBox.Sprint.Enabled = sprinting

	return sprinting
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

	module.moveUnit = moveDirection.Magnitude > 0 and Vector3.new(moveDirection.X, 0, moveDirection.Y).Unit
		or Vector3.zero

	local moveToPoint = module.moveUnit * character:GetAttribute("Walkspeed")
	local walkVelocity = character.WalkVelocity

	if cameraService.mode == "FirstPerson" then
		walkVelocity.VectorVelocity = Vector3.zero
	else
		walkVelocity.VectorVelocity = walkVelocity.VectorVelocity:Lerp(moveToPoint, 0.1)
	end
end

local function updateMovementInput()
	updatePlayerMovement()
	updatePlayerDirection()

	local moveVector = Vector3.zero

	if globalInputService:GetInputSource().Type == "Touch" then
		--local mobileMovementAction = globalInputService.inputActions["MobileMovement"]
		--moveVector = mobileMovementAction:GetMobileInput().Position
		moveVector = mobileJoystickPosition
	else
		moveVector = controller:GetMoveVector() -- movement
	end

	if
		moveVector.Magnitude < MOVEMENT_THRESHOLD
		or not globalInputService.actionGroups["PlayerControl"].IsEnabled
		or acts:checkAct("InDialogue")
		or (not player:GetAttribute("MovementEnabled"))
	then
		moveVector = Vector3.zero
	end

	updateDirection(Vector2.new(moveVector.X, moveVector.Z))
end

local function updateStats()
	if player.Character and not acts:checkAct("Paused") then
		if player.Character:GetAttribute("Hunger") < 0 then
			player.Character:SetAttribute("Hunger", 0)
			module.toggleSprint(false)
		elseif player.Character:GetAttribute("Hunger") > 100 then
			player.Character:SetAttribute("Hunger", 100)
		end

		local modifiedHungerRate = module.HUNGER_RATE
		if workspace:GetAttribute("Difficulty") == 0 then -- @Difficulty reduce hunger loss
			modifiedHungerRate = module.HUNGER_RATE / 2
		end

		if not checkIsSprinting() then
			if workspace:GetAttribute("Difficulty") == 2 then -- @Difficulty hunger goes down over time
				modifiedHungerRate = module.HUNGER_RATE / 3
			else
				modifiedHungerRate = 0
			end
		end

		if player.Character:GetAttribute("Hunger") > 0 and modifiedHungerRate > 0 then
			local rate = (os.clock() - lastHeartbeat) * modifiedHungerRate
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
end

function module.StartGame(saveData: Types.GameState?, character: Model)
	cameraService.followViewDistance.current = cameraService.followViewDistance.default

	if saveData then
		character:SetAttribute("Hunger", saveData.PlayerStats.Hunger)
		character:SetAttribute("HasNet", saveData.PlayerStats.HasNet)
	end
end

function module.Init()
	UserInputService.InputChanged:Connect(updateGamepadCursorData)
	lookJoystick.InputChanged:Connect(updateGamepadCursorData)
	movementJoystick.InputChanged:Connect(updateGamepadCursorData)

	HUD.Enabled = true
	uiAnimationService.PlayAnimation(HUD.Glitch, 0.04, true).OnStepped:Connect(function()
		HUD.Glitch.Visible = math.random(1, 2) ~= 1

		if math.random(1, 3) == 1 then
			HUD.Glitch.Image.ImageColor3 = Color3.fromRGB(math.random(0, 255), math.random(0, 255), math.random(0, 255))
		else
			HUD.Glitch.Image.ImageColor3 = Color3.new(1, 1, 1)
		end
	end)
end

local sprintInputAction = globalInputService.CreateInputAction(
	"Sprint",
	updateSprinting,
	util.getSetting("Keybinds", "Sprint"),
	util.getSetting("Gamepad", "Sprint"),
	"Button"
)

globalInputService.AddToActionGroup("PlayerControl", sprintInputAction)

sprintInputAction:SetImage("rbxassetid://137872272618939")
sprintInputAction:SetPosition(UDim2.fromScale(-0.25, 0.385))

RunService.Heartbeat:Connect(function()
	updateMovementInput()
	updateStats()
end)

local itemFunctions = {
	Eat = module.ConsumeItem,
	Heal = module.ConsumeItem,
	ToggleFlashlight = function(item)
		item.InUse = not item.InUse

		if item.InUse then
			util.PlaySound(sounds.FlashlightOn)
		else
			util.PlaySound(sounds.FlashlightOff)
		end

		player.Character:FindFirstChild("Flashlight", true).Enabled = item.InUse
	end,
	InstallNet = function(item)
		if areas.currentArea and areas.currentArea.Name == "MirrorArea" then
			module:EnableHacking()
			inventory:RemoveItem(item.Name)
			sequences:beginSequence("InstallModule")
		else
			dialogue:SayFromPlayer("I need a *mirror to install this correctly.")
		end
	end,
	EquipStem = function(item)
		if currentStimEquipped then
			currentStimEquipped.InUse = false
		end

		currentStimEquipped = item
		currentStimEquipped.InUse = true

		checkEquippedStem(getHealthPercentage(player.Character))
	end,
}

inventory.ItemUsed:Connect(function(use, item)
	if not player.Character then
		return
	end

	if not use or not itemFunctions[use] then
		return
	end
	itemFunctions[use](item, use)
end)

interact.Disabled.Changed:Connect(function(value)
	cursor.Enabled = not (globalInputService:GetInputSource().Type ~= "Keyboard" and value)
end)

player:SetAttribute("CursorLocation", Vector2.zero)
player:SetAttribute("MovementEnabled", true)

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

dialogue.DialogueActionSignal:Connect(function(actionName, ...)
	module[actionName](module, ...)
end)

return module
