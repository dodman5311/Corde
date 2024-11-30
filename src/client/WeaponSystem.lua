local module = {
    weaponUnequipped = true;
} -- {Name = "Weapon", Desc = {Type = 1}, Value = 1, InUse = false}

local ContextActionService = game:GetService("ContextActionService")
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

local currentWeapon
local mouse1Down = false
local mouse = player:GetMouse()

local UI = ReplicatedStorage.Crosshair
UI.Parent = player.PlayerGui

local fireSound = Instance.new("Sound")
fireSound.Parent = script
local reloadSound = Instance.new("Sound")
reloadSound.Parent = script

local accuracyReduction = spring.new(0)
accuracyReduction.Damper = 0.875

local rng = Random.new()

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
    else
        fire.Image.Image = ""
        reload.Image.Image = "rbxassetid://17569341211"
        reload.Image.Size = UDim2.fromScale(8, 1)
        reload.Image:SetAttribute("Frames", 8)

        module.weaponUnequipped = true
    end
end

function module.toggleHolstered()
    local character = player.Character
    if not character or not currentWeapon or acts:checkAct("Reloading", "Firing") then
        return 
    end

    if module.weaponUnequipped then
        showWeapon(currentWeapon.Desc.Type)
        util.PlaySound(ReplicatedStorage.Unholster, script, 0.075)
    else
        showWeapon(0)
        util.PlaySound(ReplicatedStorage.Holster, script, 0.075)
    end

    acts:createTempAct("Holstering", function()
        task.wait(0.15)
    end)
end

function module.equipWeapon(weapon)
    if not weapon then return end

    local character = player.Character
    if not character then
        return 
    end

    if currentWeapon then
        currentWeapon.InUse = false
        if currentWeapon.Desc['CurrentMag'] then
            currentWeapon.Desc.CurrentMag.InUse = false
        end
    end

    local weaponData = weapon.Desc
    local torso = character.Torso
    local reload = torso.UI.Reload
    local fire = torso.UI.Fire

    uiAnimationService.StopAnimation(reload)

    showWeapon(weaponData.Type)

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

    util.PlaySound(ReplicatedStorage.GunEquip, script, 0.15)
end

local function processCrosshair()
    local mousePosition = UserInputService:GetMouseLocation()

	--local mousePosition = Vector2.new(mousePosition.X, mousePosition.Y)
	local mouseUnit = mousePosition / camera.ViewportSize
	local mouseDistance = (mouseUnit - Vector2.new(.5,.5)).Magnitude * 2.65

	local size = 1 + mouseDistance

    local spread = currentWeapon and currentWeapon.Desc.Spread or 0
    size = (mouseDistance * (spread + accuracyReduction.Position))

    local crosshair = UI.Crosshair
    size *= 0.025

    crosshair.Position = UDim2.fromOffset(mousePosition.X, mousePosition.Y)
    crosshair.Size = UDim2.fromScale(size,size)

    local cursor = UI.Cursor

    cursor.Position = UDim2.fromOffset(mousePosition.X, mousePosition.Y)
end

local function useAmmo()
    if not currentWeapon then
        return
    end

    local weaponData = currentWeapon.Desc

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
    local weaponData = currentWeapon.Desc

    local searchFor = "Rifle Mag"
    if currentWeapon.Desc.Type == 2 then
        searchFor = "Pistol Mag"
    end

    local foundMag

    for slot,item in pairs(inventory) do

        if not string.match(slot, "slot_") or item.Name ~= searchFor or item == weaponData.CurrentMag or item.Value <= 0 then
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

    if module.weaponUnequipped then
        module.toggleHolstered()
        return
    end

    local weaponData = currentWeapon.Desc

    if acts:checkAct("Firing", "Reloading") then
        return
    end

    local foundMag = itemToUse or getNextMag()
    if not foundMag then
        return
    end

    local reloadTime = currentWeapon.Desc.ReloadTime 

    local torso = player.Character.Torso

    acts:createAct("Reloading")
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
    
    weaponData.CurrentMag = foundMag

    acts:removeAct("Reloading")
end

local rp = RaycastParams.new()

local function fireWeapon()
    if not player.Character or not currentWeapon or acts:checkAct("Reloading", "Firing", "Holstering") then
        return
    end

    local weaponData = currentWeapon.Desc

    if module.weaponUnequipped then
        module.toggleHolstered()
        return
    end

    if not useAmmo() then
        return
    end

    local character = player.Character
    local torso = character.Torso

    acts:createAct("Firing")

    local projectileSpread = weaponData.Spread + accuracyReduction.Position
    local newProjectile = projectiles.createFromPreset(torso.Muzzle.WorldCFrame, projectileSpread, "Bullet", currentWeapon.Desc.Damage)

    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances = {character, workspace.Ignore}

    local hit = workspace:Raycast((torso.Muzzle.WorldCFrame * CFrame.new(0,0,2)).Position, torso.Muzzle.WorldCFrame.LookVector * 3, rp)

    if hit then
        projectiles.projectileHit(hit, newProjectile)
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

    local shell:Part = ReplicatedStorage.Shell:Clone()
    Debris:AddItem(shell, 5)

    shell.CanCollide = true
    shell.Parent = workspace.Ignore

    shell.CFrame = torso.Chamber.WorldCFrame
    shell.AssemblyLinearVelocity = (torso.Chamber.WorldCFrame * CFrame.Angles(0,math.rad(rng:NextNumber(-20,20)),0)).LookVector * rng:NextNumber(10,20)
    shell.AssemblyAngularVelocity = Vector3.new(0,rng:NextNumber(-25,-5),0)

    accuracyReduction.Speed = weaponData.RecoilSpeed
	accuracyReduction.Target = weaponData.Recoil

    task.wait(60 / currentWeapon.Desc.RateOfFire)

	accuracyReduction.Speed = 7
	accuracyReduction.Target = 0

    acts:removeAct("Firing")
end

inventory.ItemAddedToSlot:Connect(function(slot, item)
    if slot ~= "slot_13" then
        return
    end

    module.equipWeapon(item)
end)

inventory.ItemUsed:Connect(function(use, item, slot)
    if use == "Reload" then

        if not currentWeapon then
            return
        end

        if currentWeapon.Desc.Type == 1 and item.Name ~= "Rifle Mag" then
            return
        elseif currentWeapon.Desc.Type == 2 and item.Name ~= "Pistol Mag" then
            return
        end

        reload(item)
    end
end)

inventory.ItemRemoved:Connect(function(item, slot)

    if not currentWeapon then
        return
    end

    if item == currentWeapon.Desc.CurrentMag then
        item.InUse = false
        currentWeapon.Desc.CurrentMag = nil
    end
end)

function module.Init()
    task.delay(0.01, function()
        module.equipWeapon(inventory:CheckSlot("slot_13"))
    end)
  
    
    
    UserInputService.MouseIconEnabled = false

    RunService.RenderStepped:Connect(processCrosshair)
end 

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        mouse1Down = true
        

        if not currentWeapon then
            return
        end
        local weaponData = currentWeapon.Desc

        if weaponData.FireMode == 1 then
            fireWeapon()
        end

        if (not weaponData.CurrentMag or weaponData.CurrentMag.Value <= 0) and not acts:checkAct("Reloading") then
            ReplicatedStorage.GunClick:Play()
        end
    end
    
    if input.KeyCode == Enum.KeyCode.R then
        reload()
    end
    
    if input.KeyCode == Enum.KeyCode.T then
        module.toggleHolstered()
    end

end)

UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        mouse1Down = false
    end
end)

RunService.Heartbeat:Connect(function()

    if not currentWeapon or not mouse1Down then
        return
    end
    local weaponData = currentWeapon.Desc

    if weaponData.FireMode ~= 2 then
        return
    end

    fireWeapon()
end)

return module