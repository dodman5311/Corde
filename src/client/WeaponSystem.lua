local module = {
	weaponUnequipped = true,
	hasKilled = false,
} -- {Name = "Weapon", Value = {Type = 1}, Value = 1, InUse = false}

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Client = player.PlayerScripts.Client
local camera = workspace.CurrentCamera

local Timer = require(script.Parent.Timer)
local Types = require(ReplicatedStorage.Shared.Types)
local actionPrompt = require(Client.ActionPrompt)
local acts = require(Client.Acts)
local cameraService = require(Client.Camera)
local cameraShaker = require(Client.CameraShaker)
local globalInputService = require(Client.GlobalInputService)
local haptics = require(Client.Haptics)
local inventory = require(Client.Inventory)
local projectiles = require(Client.Projectiles)
local sequences = require(Client.Sequences)
local signal = require(ReplicatedStorage.Packages.Signal)
local spring = require(Client.Spring)
local uiAnimationService = require(Client.UIAnimationService)
local util = require(Client.Util)

local currentWeapon: Types.weapon?
local fireKeyDown = false
local readyKeyDown = false

local assets = ReplicatedStorage.Assets
local sounds = assets.Sounds
local models = assets.Models

local UNHOLSTER_TIME = 0.2

local HUD

local fireSound = Instance.new("Sound")
fireSound.Parent = script
fireSound.RollOffMaxDistance = 15
fireSound.SoundGroup = SoundService.SoundEffects

local reloadSound = Instance.new("Sound")
reloadSound.Parent = script
reloadSound.RollOffMaxDistance = 10
reloadSound.SoundGroup = SoundService.SoundEffects

local accuracyReduction = spring.new(0)
accuracyReduction.Damper = 0.875

accuracyReduction.Speed = 5
accuracyReduction.Target = 0

local rng = Random.new()
local checkChamberTimer = Timer:new("checkChamberInput", 0.5)

module.onWeaponToggled = signal.new()
local rp = RaycastParams.new()

local function showWeapon(weaponType)
	local character = player.Character
	if not character then
		return
	end

	local torso = character.Torso
	local reload = torso.UI.Reload
	local fire = torso.UI.Fire

	if weaponType == 1 then
		fire.Image.Image = "rbxassetid://17514692550"
		reload.Image.Image = "rbxassetid://17514696043"
		reload.Image.Size = UDim2.fromScale(16, 2)
		reload.Image:SetAttribute("Frames", 24)

		torso.Muzzle.Position = Vector3.new(-2.2, 0, -0.35)

		module.weaponUnequipped = false

		uiAnimationService.StopAnimation(reload)
	elseif weaponType == 2 then
		fire.Image.Image = "rbxassetid://17522906857"
		reload.Image.Image = "rbxassetid://17522906978"
		reload.Image.Size = UDim2.fromScale(16, 1)
		reload.Image:SetAttribute("Frames", 16)

		torso.Muzzle.Position = Vector3.new(-2, 0, -0.45)

		module.weaponUnequipped = false

		uiAnimationService.StopAnimation(reload)
	elseif weaponType == 3 then
		fire.Image.Image = "rbxassetid://17514692550"
		reload.Image.Image = "rbxassetid://17514696043"
		reload.Image.Size = UDim2.fromScale(16, 2)
		reload.Image:SetAttribute("Frames", 24)

		torso.Muzzle.Position = Vector3.new(-2.2, 0, -0.35)

		module.weaponUnequipped = false

		uiAnimationService.StopAnimation(reload)
	else
		fire.Image.Image = ""
		reload.Image.Image = "rbxassetid://17569341211"
		reload.Image.Size = UDim2.fromScale(8, 1)
		reload.Image:SetAttribute("Frames", 8)

		module.weaponUnequipped = true
	end

	module.onWeaponToggled:Fire(weaponType)
end

function module.toggleHolstered(value)
	local character = player.Character
	if not character or not currentWeapon or acts:checkAct("Reloading", "CheckingChamber") then
		return
	end

	if value and module.weaponUnequipped then
		if acts:checkAct("Interacting") then
			return
		end

		showWeapon(currentWeapon.Value.Type)

		globalInputService.inputActions["Fire Weapon"]:Enable()
		util.PlayFrom(character, sounds.Unholster, 0.075)

		acts:createTempAct("Holstering", function()
			task.wait(UNHOLSTER_TIME)
		end)
	elseif not readyKeyDown and not module.weaponUnequipped then
		showWeapon(0)

		globalInputService.inputActions["Fire Weapon"]:Disable()
		util.PlayFrom(character, sounds.Holster, 0.075)

		acts:createTempAct("Holstering", function()
			task.wait(0.1)
		end)
	end
end

function module.unequipWeapon()
	if not currentWeapon then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	currentWeapon.InUse = false
	if currentWeapon.Value["CurrentMag"] then
		currentWeapon.Value.CurrentMag.InUse = false
	end

	local torso = character.Torso
	local reload = torso.UI.Reload

	uiAnimationService.StopAnimation(reload)
	showWeapon(0)

	currentWeapon = nil
	acts:removeAct("Firing")
end

function module.equipWeapon(weapon)
	if not weapon then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	module.unequipWeapon()

	local weaponData = weapon.Value

	fireSound.SoundId = weaponData.FireSound
	fireSound.Volume = weaponData.Volume
	reloadSound.SoundId = weaponData.ReloadSound

	currentWeapon = weapon

	weapon.InUse = true

	if weaponData.CurrentMag and not util.SearchDictionary(inventory, weaponData.CurrentMag) then
		weaponData.CurrentMag.InUse = false
		weaponData.CurrentMag = nil
	end

	if weaponData.CurrentMag then
		weaponData.CurrentMag.InUse = true
	end

	util.PlayFrom(character, sounds.GunEquip, 0.15)
end

local function processCrosshair()
	local mousePosition = player:GetAttribute("CursorLocation")

	--local mousePosition = Vector2.new(mousePosition.X, mousePosition.Y)
	local mouseUnit = mousePosition / camera.ViewportSize
	local mouseDistance = (mouseUnit - Vector2.new(0.5, 0.5)).Magnitude * 2.65

	local size = 1 + mouseDistance

	local spread = (currentWeapon and not module.weaponUnequipped) and currentWeapon.Value.Spread or 0
	size = (mouseDistance * (spread + accuracyReduction.Position))

	local crosshair = HUD.Crosshair
	size *= 0.025

	crosshair.Position = UDim2.fromOffset(mousePosition.X, mousePosition.Y)
	crosshair.Size = UDim2.fromScale(size, size)

	if spread == 0 then
		for _, dot: Frame in ipairs(util:GetMatchingChildren(crosshair, { ClassName = "Frame" })) do
			dot.BackgroundTransparency = 1
		end
	else
		for _, dot: Frame in ipairs(util:GetMatchingChildren(crosshair, { ClassName = "Frame" })) do
			dot.BackgroundTransparency = size * 1.5
		end
	end
end

local function useAmmo()
	if not currentWeapon then
		return
	end

	local weaponData = currentWeapon.Value

	if not weaponData.CurrentMag or weaponData.CurrentMag.Value <= 0 then
		return
	end

	local logBulletCount = weaponData.BulletCount
	if weaponData.UseAmmoForBulletCount then
		weaponData.BulletCount = math.clamp(logBulletCount, 0, weaponData.CurrentMag.Value)
		task.defer(function()
			weaponData.BulletCount = logBulletCount
		end)
	end

	weaponData.CurrentMag.Value -= weaponData.UseAmmoForBulletCount and weaponData.BulletCount or 1

	return true
end

local function getNextMag(isInUse)
	if not currentWeapon then
		return
	end
	local weaponData = currentWeapon.Value

	if currentWeapon.Value.Type == 1 then
		searchFor = "Rifle Mag"
	elseif currentWeapon.Value.Type == 2 then
		searchFor = "Pistol Mag"
	elseif currentWeapon.Value.Type == 3 then
		searchFor = "Shotgun Mag"
	end

	local foundMag

	for slot, item: Types.item in pairs(inventory) do
		if
			not string.match(slot, "slot_")
			or item.Name ~= searchFor
			or item == weaponData.CurrentMag
			or item.Value <= 0
			or (isInUse and not item.InUse)
		then
			continue
		end

		foundMag = item
	end

	return foundMag
end

local function unload()
	if acts:checkAct("Firing", "Reloading", "Interacting") or not currentWeapon then
		return
	end

	local weaponData = currentWeapon.Value

	if weaponData.CurrentMag then
		weaponData.CurrentMag.InUse = false
		weaponData.CurrentMag = nil
	end

	util.PlaySound(sounds.Unload, 0.1)
end

local function reload(itemToUse)
	if not currentWeapon or not player.Character or acts:checkAct("Firing", "Reloading", "Interacting") then
		return
	end

	local weaponData = currentWeapon.Value

	local foundMag = itemToUse or getNextMag()
	if not foundMag then
		return
	end

	if module.weaponUnequipped then
		module.toggleHolstered(true)
		acts:waitForAct("Holstering")
	end

	local reloadTime = currentWeapon.Value.ReloadTime

	local torso = player.Character.Torso

	acts:createAct("Reloading", "Interacting")

	util.PlayFrom(player.Character, reloadSound)

	local frames = 24
	if currentWeapon.Value.Type == 2 then
		frames = 16
	end

	torso.UI.Fire.Visible = false
	uiAnimationService.PlayAnimation(torso.UI.Reload, reloadTime / frames).OnEnded:Once(function()
		torso.UI.Fire.Visible = true
	end)

	actionPrompt.showAction(reloadTime, "Reloading")

	if weaponData.CurrentMag then
		weaponData.CurrentMag.InUse = false
	end

	foundMag.InUse = true

	task.wait(reloadTime)
	task.delay(0.1, module.toggleHolstered, false)

	weaponData.CurrentMag = foundMag
	acts:removeAct("Reloading", "Interacting")
end

local function checkChamber() -- @TODO Make compatable with rifle and shotgun
	if not currentWeapon or not player.Character or acts:checkAct("Firing", "Reloading", "Interacting") then
		return
	end
	if module.weaponUnequipped then
		task.spawn(module.toggleHolstered, true)
	end

	acts:createAct("CheckingChamber", "Interacting")

	task.wait(UNHOLSTER_TIME)

	local mag = currentWeapon.Value.CurrentMag

	local images = {
		full = "rbxassetid://108066626327817",
		empty = "rbxassetid://100968223712377",
	}

	local ti = TweenInfo.new(0.25)

	if mag and mag.Value > 0 then
		HUD.ChamberCheck.Image.Image = images.full
	else
		HUD.ChamberCheck.Image.Image = images.empty
	end

	actionPrompt.showAction(2, "Checking Chamber")

	util.PlayFrom(player.Character, sounds.ChamberCheck.Pistol.Back, 0.025)

	util.tween(HUD.ChamberCheck.Image, ti, { ImageTransparency = 0 })
	local animation = uiAnimationService.PlayAnimation(HUD.ChamberCheck, 0.05)
	animation:OnFrameRached(4):Wait()
	animation:Pause()
	task.wait(1)

	util.PlayFrom(player.Character, sounds.ChamberCheck.Pistol.Forward, 0.025)

	animation:Resume()
	animation.OnEnded:Wait()
	util.tween(HUD.ChamberCheck.Image, ti, { ImageTransparency = 1 })

	task.delay(0.1, module.toggleHolstered, false)
	acts:removeAct("CheckingChamber", "Interacting")
end

local function inflictPower(model: Model)
	if not currentWeapon then
		return
	end

	local weaponData = currentWeapon.Value

	local walkVelocity: LinearVelocity = model:FindFirstChild("WalkVelocity")
	if walkVelocity then
		walkVelocity.VectorVelocity = walkVelocity.VectorVelocity:Lerp(Vector3.zero, weaponData.StoppingPower)
	end

	local newForce = Instance.new("LinearVelocity")
	newForce.Parent = model
	newForce.MaxForce = 11000
	newForce.Attachment0 = model.PrimaryPart.RootAttachment
	newForce.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
	newForce.VectorVelocity = Vector3.new(0, 0, weaponData.StoppingPower)
	Debris:AddItem(newForce, 0.1)

	task.delay(0.1, function()
		local walkVelocity: LinearVelocity = model:FindFirstChild("WalkVelocity")
		if walkVelocity then
			walkVelocity.VectorVelocity = walkVelocity.VectorVelocity:Lerp(Vector3.zero, weaponData.StoppingPower)
		end

		newForce:Destroy()
	end)
end

local function registerShot(result, health)
	local hitModel = result.Instance:FindFirstAncestorOfClass("Model")

	if not health then
		return
	end

	if health > 0 then
		inflictPower(hitModel)
	elseif not module.hasKilled and hitModel:HasTag("Friendly") then
		module.hasKilled = true
		sequences:beginSequence("noMercy")
	end
end

local function createBullet(weaponData)
	local character = player.Character
	if not player.Character or not currentWeapon then
		return
	end

	local torso = character.Torso

	local damage = currentWeapon.Value.Damage
	if workspace:GetAttribute("Difficulty") == 2 then -- @Difficulty Reduce damage dealt
		damage *= 0.75
	end

	local projectileSpread = weaponData.Spread + accuracyReduction.Position
	local newProjectile = projectiles.createFromPreset(torso.Muzzle.WorldCFrame, projectileSpread, "Bullet", damage)
	newProjectile.HitEvent:Once(registerShot)

	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.CollisionGroup = "Bullet"
	rp.FilterDescendantsInstances = { character, workspace.Ignore }

	local hit = workspace:Raycast(
		(torso.Muzzle.WorldCFrame * CFrame.new(0, 0, 2)).Position,
		torso.Muzzle.WorldCFrame.LookVector * 3,
		rp
	)

	if hit then
		projectiles.projectileHit(hit, newProjectile)
	end
end

local function createShell()
	local character = player.Character
	local torso = character.Torso
	local shell: Part = models.Shell:Clone()

	Debris:AddItem(shell, 5)

	shell.CanCollide = true
	shell.Parent = workspace.Ignore

	shell.CFrame = torso.Chamber.WorldCFrame
	shell.AssemblyLinearVelocity = (torso.Chamber.WorldCFrame * CFrame.Angles(0, math.rad(rng:NextNumber(-20, 20)), 0)).LookVector
		* rng:NextNumber(10, 20)
	shell.AssemblyAngularVelocity = Vector3.new(0, rng:NextNumber(-25, -5), 0)

	local ti = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 3)
	util.tween(shell.SurfaceGui.Frame, ti, { BackgroundTransparency = 1 })
end

local function fireWeapon(input)
	if acts:checkAct("Firing") then
		return
	end

	local character = player.Character
	if
		not character
		or not currentWeapon
		or acts:checkAct("Reloading", "Holstering", "Interacting", "InObjectView")
	then
		fireKeyDown = false
		return
	end

	local weaponData = currentWeapon.Value

	if module.weaponUnequipped then
		--module.toggleHolstered()
		return
	end

	if not useAmmo() then
		return
	end

	local torso = character.Torso

	acts:createAct("Firing")

	for _ = 1, weaponData.BulletCount do
		createBullet(weaponData)
	end

	torso.UI.Reload.Visible = false
	uiAnimationService.PlayAnimation(torso.UI.Fire, 0.045).OnEnded:Once(function()
		torso.UI.Reload.Visible = true
	end)

	util.PlayFrom(player.Character, fireSound, 0.1)

	torso.Muzzle.Flash.Enabled = true
	task.delay(0.04, function()
		torso.Muzzle.Flash.Enabled = false
	end)

	createShell()

	--accuracyReduction.Speed = weaponData.RecoilSpeed
	--accuracyReduction.Target = weaponData.Recoil
	accuracyReduction:Impulse(weaponData.Recoil)

	local cameraRecoilMagnitude = (weaponData.Recoil / 100) * 5
	local cameraRecoil = cameraRecoilMagnitude / 10

	local cameraRecoilInstance = cameraShaker.CameraShakeInstance.new(cameraRecoilMagnitude, 6.5, 0, cameraRecoil)
	cameraRecoilInstance.PositionInfluence = Vector3.one * 0.2
	cameraRecoilInstance.RotationInfluence = Vector3.new(0, 0, 3)

	cameraService.shaker:Shake(cameraRecoilInstance)

	haptics.hapticPulse(input, Enum.VibrationMotor.Small, cameraRecoil, cameraRecoil / 1.5, "GunFire")

	task.wait(60 / currentWeapon.Value.RateOfFire)

	acts:removeAct("Firing")
end

inventory.SlotValueChanged:Connect(function(slot, value)
	if slot ~= "Weapon_Slot" then
		return
	end

	if value then
		module.equipWeapon(value)
	else
		module.unequipWeapon()
	end
end)

inventory.ItemUsed:Connect(function(use, item)
	if use == "Reload" then
		if not currentWeapon then
			return
		end

		if item.InUse then
			unload()
			return
		end

		if currentWeapon.Value.Type == 1 and item.Name ~= "Rifle Mag" then
			return
		elseif currentWeapon.Value.Type == 2 and item.Name ~= "Pistol Mag" then
			return
		elseif currentWeapon.Value.Type == 3 and item.Name ~= "Shotgun Mag" then
			return
		end

		reload(item)
	end
end)

inventory.ItemRemoved:Connect(function(item)
	if not currentWeapon then
		return
	end

	if item == currentWeapon.Value.CurrentMag then
		item.InUse = false
		currentWeapon.Value.CurrentMag = nil
	end
end)

function module.StartGame()
	module.equipWeapon(inventory:CheckSlot("Weapon_Slot"))

	if currentWeapon then
		local mag = getNextMag(true)
		currentWeapon.Value.CurrentMag = getNextMag(true)
		print(mag, currentWeapon.Value.CurrentMag)
	end
end

function module.Init()
	HUD = player.PlayerGui.HUD

	UserInputService.MouseIconEnabled = false

	RunService.RenderStepped:Connect(processCrosshair)
end

function module.fireKeyToggle(state, input)
	if state == Enum.UserInputState.Begin then
		if acts:checkAct("Paused") then
			return
		end

		fireKeyDown = input

		if not currentWeapon then
			return
		end
		local weaponData = currentWeapon.Value

		if weaponData.FireMode == 1 then
			fireWeapon(input)
		end

		if (not weaponData.CurrentMag or weaponData.CurrentMag.Value <= 0) and not acts:checkAct("Reloading") then
			util.PlayFrom(player.Character, sounds.GunClick)
		end
	elseif state == Enum.UserInputState.End then
		fireKeyDown = false
	end
end

function module.readyKeyToggle(state, input)
	if state == Enum.UserInputState.Begin then
		if acts:checkAct("Paused") then
			return
		end

		readyKeyDown = input
		module.toggleHolstered(true)
	elseif state == Enum.UserInputState.End then
		readyKeyDown = false
		module.toggleHolstered(false)
	end
end

inventory.InvetoryToggled:Connect(function(value)
	if not value then
		return
	end

	module.fireKeyToggle(Enum.UserInputState.End)
	module.readyKeyToggle(Enum.UserInputState.End)
end)

local function reloadInput(state)
	if state == Enum.UserInputState.Begin then
		checkChamberTimer.Function = checkChamber
		checkChamberTimer:Run()
	elseif state == Enum.UserInputState.End then
		checkChamberTimer:Cancel()
		reload()
	end
end

globalInputService.AddToActionGroup(
	"PlayerControl",
	globalInputService.CreateInputAction(
		"Reload",
		reloadInput,
		util.getSetting("Keybinds", "Reload"),
		util.getSetting("Gamepad", "Reload")
	),
	globalInputService.CreateInputAction(
		"Fire Weapon",
		module.fireKeyToggle,
		util.getSetting("Keybinds", "Fire Weapon"),
		util.getSetting("Gamepad", "Fire Weapon")
	),
	globalInputService.CreateInputAction(
		"Ready Weapon",
		module.readyKeyToggle,
		util.getSetting("Keybinds", "Ready Weapon"),
		util.getSetting("Gamepad", "Ready Weapon")
	)
)

globalInputService.inputActions["Fire Weapon"]:Disable()

RunService.Heartbeat:Connect(function()
	if not currentWeapon or not fireKeyDown or acts:checkAct("Paused") then
		return
	end
	local weaponData = currentWeapon.Value

	if weaponData.FireMode ~= 2 then
		return
	end

	fireWeapon(fireKeyDown)
end)

return module
