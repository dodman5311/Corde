local module = {
	weaponUnequipped = true,
	hasKilled = false,
} -- {Name = "Weapon", Value = {Type = 1}, Value = 1, InUse = false}

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Client = player.PlayerScripts.Client
local camera = workspace.CurrentCamera

local uiAnimationService = require(Client.UIAnimationService)
local inventory = require(Client.Inventory)
local acts = require(Client.Acts)
local util = require(Client.Util)
local spring = require(Client.Spring)
local actionPrompt = require(Client.ActionPrompt)
local projectiles = require(Client.Projectiles)
local sequences = require(Client.Sequences)
local cameraService = require(Client.Camera)
local cameraShaker = require(Client.CameraShaker)
local haptics = require(Client.Haptics)
local signal = require(ReplicatedStorage.Packages.Signal)
local globalInputService = require(Client.GlobalInputService)

local currentWeapon
local fireKeyDown = false
local readyKeyDown = false

local assets = ReplicatedStorage.Assets
local sounds = assets.Sounds
local gui = assets.Gui
local models = assets.Models

local UI = gui.HUD
UI.Parent = player.PlayerGui

local fireSound = Instance.new("Sound")
fireSound.Parent = script
local reloadSound = Instance.new("Sound")
reloadSound.Parent = script

local accuracyReduction = spring.new(0)
accuracyReduction.Damper = 0.875

accuracyReduction.Speed = 5
accuracyReduction.Target = 0

local rng = Random.new()

module.onWeaponUnequipped = signal.new()

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
		module.onWeaponUnequipped:Fire()
	end
end

function module.toggleHolstered(value)
	local character = player.Character
	if not character or not currentWeapon or acts:checkAct("Reloading") then
		return
	end

	if value and module.weaponUnequipped then
		if acts:checkAct("Interacting") then
			return
		end

		showWeapon(currentWeapon.Value.Type)
		util.PlaySound(sounds.Unholster, script, 0.075)

		acts:createTempAct("Holstering", function()
			task.wait(0.2)
		end)
	elseif not readyKeyDown and not module.weaponUnequipped then
		showWeapon(0)
		util.PlaySound(sounds.Holster, script, 0.075)

		acts:createTempAct("Holstering", function()
			task.wait(0.1)
		end)
	end
end

function module.equipWeapon(weapon)
	if not weapon then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	if currentWeapon then
		currentWeapon.InUse = false
		if currentWeapon.Value["CurrentMag"] then
			currentWeapon.Value.CurrentMag.InUse = false
		end
	end

	local weaponData = weapon.Value
	local torso = character.Torso
	local reload = torso.UI.Reload

	uiAnimationService.StopAnimation(reload)

	showWeapon(0)

	fireSound.SoundId = weaponData.FireSound
	fireSound.Volume = weaponData.Volume
	reloadSound.SoundId = weaponData.ReloadSound

	currentWeapon = weapon
	acts:removeAct("Firing")

	weapon.InUse = true

	if weaponData.CurrentMag and not util.SearchDictionary(inventory, weaponData.CurrentMag) then
		weaponData.CurrentMag.InUse = false
		weaponData.CurrentMag = nil
	end

	if weaponData.CurrentMag then
		weaponData.CurrentMag.InUse = true
	end

	util.PlaySound(sounds.GunEquip, script, 0.15)
end

local function processCrosshair()
	local mousePosition = player:GetAttribute("CursorLocation")

	--local mousePosition = Vector2.new(mousePosition.X, mousePosition.Y)
	local mouseUnit = mousePosition / camera.ViewportSize
	local mouseDistance = (mouseUnit - Vector2.new(0.5, 0.5)).Magnitude * 2.65

	local size = 1 + mouseDistance

	local spread = (currentWeapon and not module.weaponUnequipped) and currentWeapon.Value.Spread or 0
	size = (mouseDistance * (spread + accuracyReduction.Position))

	local crosshair = UI.Crosshair
	size *= 0.025

	crosshair.Position = UDim2.fromOffset(mousePosition.X, mousePosition.Y)
	crosshair.Size = UDim2.fromScale(size, size)

	local cursor = UI.Cursor

	cursor.Position = UDim2.fromOffset(mousePosition.X, mousePosition.Y)
end

local function useAmmo()
	if not currentWeapon then
		return
	end

	local weaponData = currentWeapon.Value

	if not weaponData.CurrentMag or weaponData.CurrentMag.Value <= 0 then
		return
	end

	weaponData.CurrentMag.Value -= 1

	return true
end

local function getNextMag()
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

	for slot, item in pairs(inventory) do
		if
			not string.match(slot, "slot_")
			or item.Name ~= searchFor
			or item == weaponData.CurrentMag
			or item.Value <= 0
		then
			continue
		end

		foundMag = item
	end

	return foundMag
end

local function reload(itemToUse)
	if not currentWeapon or not player.Character then
		return
	end

	local weaponData = currentWeapon.Value

	if acts:checkAct("Firing", "Reloading", "Interacting") then
		return
	end

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
	reloadSound:Play()

	torso.UI.Fire.Visible = false
	uiAnimationService.PlayAnimation(torso.UI.Reload, reloadTime / 24).OnEnded:Once(function()
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

local rp = RaycastParams.new()

local function registerShot(result, health)
	local hitModel = result.Instance:FindFirstAncestorOfClass("Model")

	if health and health <= 0 and not module.hasKilled and hitModel:HasTag("Friendly") then
		module.hasKilled = true
		task.delay(0.1, function()
			sequences:beginSequence("noMercy")
		end)
	end
end

local function createBullet(weaponData)
	local character = player.Character
	if not player.Character then
		return
	end

	local torso = character.Torso

	local projectileSpread = weaponData.Spread + accuracyReduction.Position
	local newProjectile =
		projectiles.createFromPreset(torso.Muzzle.WorldCFrame, projectileSpread, "Bullet", currentWeapon.Value.Damage)
	newProjectile.HitEvent:Once(registerShot)

	rp.FilterType = Enum.RaycastFilterType.Exclude
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

local function fireWeapon(input)
	local character = player.Character
	if not character or not currentWeapon or acts:checkAct("Reloading", "Firing", "Holstering", "Interacting") then
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

	util.PlaySound(fireSound, script, 0.1)

	torso.Muzzle.Flash.Enabled = true
	task.delay(0.04, function()
		torso.Muzzle.Flash.Enabled = false
	end)

	local shell: Part = models.Shell:Clone()
	Debris:AddItem(shell, 5)

	shell.CanCollide = true
	shell.Parent = workspace.Ignore

	shell.CFrame = torso.Chamber.WorldCFrame
	shell.AssemblyLinearVelocity = (torso.Chamber.WorldCFrame * CFrame.Angles(0, math.rad(rng:NextNumber(-20, 20)), 0)).LookVector
		* rng:NextNumber(10, 20)
	shell.AssemblyAngularVelocity = Vector3.new(0, rng:NextNumber(-25, -5), 0)

	--accuracyReduction.Speed = weaponData.RecoilSpeed
	--accuracyReduction.Target = weaponData.Recoil
	accuracyReduction:Impulse(weaponData.Recoil)

	local cameraRecoilMagnitude = (weaponData.Recoil / 100) * 5
	local cameraRecoil = cameraRecoilMagnitude / 10

	local cameraRecoilInstance = cameraShaker.CameraShakeInstance.new(cameraRecoilMagnitude, 6.5, 0, cameraRecoil)
	cameraRecoilInstance.PositionInfluence = Vector3.one * 0.2
	cameraRecoilInstance.RotationInfluence = Vector3.new(0, 0, 3)

	cameraService.shaker:Shake(cameraRecoilInstance)

	haptics.hapticPulse(input, Enum.VibrationMotor.Large, cameraRecoil, cameraRecoil / 1.5, "GunFire")

	task.wait(60 / currentWeapon.Value.RateOfFire)

	acts:removeAct("Firing")
end

inventory.ItemAddedToSlot:Connect(function(slot, item)
	if slot ~= "slot_13" then
		return
	end

	module.equipWeapon(item)
end)

inventory.ItemUsed:Connect(function(use, item)
	if use == "Reload" then
		if not currentWeapon then
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

function module.Init()
	task.delay(0.01, function()
		module.equipWeapon(inventory:CheckSlot("slot_13"))
	end)

	UserInputService.MouseIconEnabled = false

	RunService.RenderStepped:Connect(processCrosshair)
end

local function fireKeyToggle(state, input)
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
			sounds.GunClick:Play()
		end
	elseif state == Enum.UserInputState.End then
		fireKeyDown = false
	end
end

local function readyKeyToggle(state, input)
	if state == Enum.UserInputState.Begin then
		if acts:checkAct("Paused") then
			return
		end

		readyKeyDown = input
		module.toggleHolstered(true)
	elseif state == Enum.UserInputState.End then
		readyKeyDown = false
		module.toggleHolstered(readyKeyDown)
	end
end

inventory.InvetoryToggled:Connect(function(value)
	if not value then
		return
	end

	fireKeyToggle(Enum.UserInputState.End)
	readyKeyToggle(Enum.UserInputState.End)
end)

local function reloadInput(state)
	if state ~= Enum.UserInputState.Begin then
		return
	end

	reload()
end

globalInputService.CreateNewInput("Reload", reloadInput, Enum.KeyCode.R, Enum.KeyCode.ButtonR1)
globalInputService.CreateNewInput("ToggleFire", fireKeyToggle, Enum.KeyCode.ButtonR2, Enum.UserInputType.MouseButton1)
globalInputService.CreateNewInput("ToggleReady", readyKeyToggle, Enum.KeyCode.ButtonL2, Enum.UserInputType.MouseButton2)

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
