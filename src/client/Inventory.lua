local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Inventory = {

} -- {Name = "", Desc = "", Value = 1, InUse = false, Use = "Action"}

local player = Players.LocalPlayer

local signal = require(ReplicatedStorage.Packages.Signal)
local UIAnimationService = require(script.Parent.UIAnimationService)
local util = require(script.Parent.Util)
local acts = require(script.Parent.Acts)
local mouseOver = require(script.Parent.MouseOver)

Inventory.ItemRemoved = signal.new()
Inventory.ItemAdded = signal.new()
Inventory.ItemAddedToSlot = signal.new()
Inventory.ItemUsed = signal.new()

local rng = Random.new()

local UITemplate = ReplicatedStorage.Inventory
local UI

function Inventory:SearchForItem(itemName)
    for slot,item in pairs(self) do
        if not string.match(slot, "slot_") then
            continue
        end

        if item.Name ~= itemName then
            continue
        end

        return item, slot
    end
end

function Inventory:CheckSlot(slot)
    return self[slot]
end

function Inventory:ChangeSlot(slot, slotToChangeTo)
    local item = self[slot]
    if not item then
        return
    end

    if slotToChangeTo == "slot_13" and typeof(item.Desc) ~= "table" then
        return "NotWeapon"
    end

    if self[slotToChangeTo] then
        self[slot] = self[slotToChangeTo]
        self.ItemAddedToSlot:Fire(slot, self[slotToChangeTo])
    else
        self[slot] = nil
    end 

    self[slotToChangeTo] = item
    self.ItemAddedToSlot:Fire(slotToChangeTo, item)
end

function Inventory:AddItem(item)
    for i = 1,12 do
        if self["slot_" .. i] then
            continue
        end

        self["slot_" .. i] = item
        self.ItemAdded:Fire(item, "slot_" .. i)
        self.ItemAddedToSlot:Fire("slot_" .. i, item)

        return true
    end
end

function Inventory:AddWeapon(item)

    if not item then return end

    if self.slot_13 then
        self:DropItem(self.slot_13.Name)
    end

    self.slot_13 = item
    self.ItemAdded:Fire(item, "slot_13")
    self.ItemAddedToSlot:Fire("slot_13")

    return true
end

function Inventory:RemoveItem(ItemOrSlot)
    local item, slot

    if Inventory[ItemOrSlot] then
        item = Inventory[ItemOrSlot]
        slot = ItemOrSlot
    else
        item, slot = self:SearchForItem(ItemOrSlot)
    end

    if not item then
        return
    end

    self.ItemRemoved:Fire(item, slot)
    self[slot] = nil

    return item, slot
end

function Inventory:DropItem(ItemOrSlot)

    if not ItemOrSlot then
        return
    end

    local item, slot = self:RemoveItem(ItemOrSlot)

    if not item then
        return
    end

    local droppedItem = ReplicatedStorage.DroppedItem:Clone()
    local character = player.Character

    local data = require(droppedItem.Container)

    table.insert(data, item)

    droppedItem.Parent = workspace
    droppedItem.Name = item.Name
    droppedItem.CFrame = character:GetPivot()
    droppedItem.AssemblyLinearVelocity = (character:GetPivot() * CFrame.Angles(0,math.rad(rng:NextNumber(-20,20)),0)).LookVector * rng:NextNumber(10,20)
end

function Inventory:pickupFromContainer(object)
    if not object or not object:FindFirstChild("Container") then
        return
    end

    local containerData = require(object.Container)

    local toRemove = {}

    for i,v in ipairs(containerData) do
        if not self:AddItem(v) then
            break
        end

        table.insert(toRemove, v)
    end

    for _,v in ipairs(toRemove) do
        table.remove(containerData, table.find(containerData, v))
    end

    if object:GetAttribute("RemoveOnEmpty") and #containerData == 0 then
        object:Destroy()
    end
end 

local function setUpSlots()
    for _,slotUi in ipairs(UI.Inventory.Slots:GetChildren()) do
        if not slotUi:IsA('Frame') then continue end

        local item = Inventory[slotUi.Name]

        if item then
            slotUi.Frame.Image.Image = item.Icon
            slotUi.ItemName.Text = item.Name
            slotUi.Value.Text = item.Value

            if item.InUse then
                slotUi.Value.TextColor3 = Color3.fromRGB(255, 185, 35)
            else
                slotUi.Value.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
        else

            slotUi.Frame.Image.Image = ""
            slotUi.ItemName.Text = "Vacant"
            slotUi.Value.Text = ""

        end
    end
end

local function getRecoil(stats)
    return (stats.Recoil * stats.RecoilSpeed) / (stats.RateOfFire / 60)
end

local function setUpWeapon()
    local weapon = Inventory['slot_13']

    local weaponUi = UI.Inventory.Weapon

    local accuracy = weaponUi.AccuracyBar
    local damage = weaponUi.DamageBar
    local firerate = weaponUi.FireRateBar
    local recoil = weaponUi.RecoilBar
    local stoppingPower = weaponUi.StoppingPowerBar

    if not weapon then
        accuracy.Bar.Size = UDim2.fromScale(0,1)
        accuracy.Value.Text = 0

        damage.Bar.Size = UDim2.fromScale(0,1)
        damage.Value.Text = 0

        firerate.Bar.Size = UDim2.fromScale(0,1)
        firerate.Value.Text = 0

        recoil.Bar.Size = UDim2.fromScale(0,1)
        recoil.Value.Text = 0

        stoppingPower.Bar.Size = UDim2.fromScale(0,1)
        stoppingPower.Value.Text = 0.0

        weaponUi.ItemName.Text = "Vacant"
    else
        local weaponData = weapon.Desc

        accuracy.Bar.Size = UDim2.fromScale(math.abs(weaponData.Spread - 10) / 10,1)
        accuracy.Value.Text = math.abs(weaponData.Spread - 10)

        damage.Bar.Size = UDim2.fromScale(weaponData.Damage / 100,1)
        damage.Value.Text = weaponData.Damage

        firerate.Bar.Size = UDim2.fromScale(weaponData.RateOfFire / 1000,1)
        firerate.Value.Text = weaponData.RateOfFire

        recoil.Bar.Size = UDim2.fromScale(getRecoil(weaponData) / 50,1)
        recoil.Value.Text = math.round(getRecoil(weaponData) * 10) / 10

        stoppingPower.Bar.Size = UDim2.fromScale(weaponData.StoppingPower / 1,1)
        stoppingPower.Value.Text = weaponData.StoppingPower

        weaponUi.ItemName.Text = weapon.Name
    end
end

local function compareWeapon(baseWeapon)
    local weapon = Inventory['slot_13']

    local weaponUi = UI.Inventory.WeaponCompare

    local accuracy = weaponUi.AccuracyBar
    local damage = weaponUi.DamageBar
    local firerate = weaponUi.FireRateBar
    local recoil = weaponUi.RecoilBar
    local stoppingPower = weaponUi.StoppingPowerBar

    local weaponData = {
        Type = 1;
        RateOfFire = 1;
        ReloadTime = 100;
        Damage = 0;
        FireMode = 0;
        Spread = 0;
        StoppingPower = 0;
        Recoil = 0;
        RecoilSpeed = 0;
    }

    if weapon then
        weaponData = weapon.Desc
    end

    local baseWeaponData = baseWeapon.Desc

    accuracy.Bar.Size = UDim2.fromScale(math.abs(baseWeaponData.Spread - 10) / 10,1)
    if baseWeaponData.Spread > weaponData.Spread then
        accuracy.Bar.BackgroundColor3 = Color3.new(1)
    elseif baseWeaponData.Spread < weaponData.Spread then
        accuracy.Bar.BackgroundColor3 = Color3.new(0, 1)
    else
        accuracy.Bar.BackgroundColor3 = Color3.new(1,1,1)
    end
    
    damage.Bar.Size = UDim2.fromScale(baseWeaponData.Damage / 100,1)
    if baseWeaponData.Damage > weaponData.Damage then
        damage.Bar.BackgroundColor3 = Color3.new(0, 1)
    elseif baseWeaponData.Damage < weaponData.Damage then
        damage.Bar.BackgroundColor3 = Color3.new(1)
    else
        damage.Bar.BackgroundColor3 = Color3.new(1,1,1)
    end

    firerate.Bar.Size = UDim2.fromScale(baseWeaponData.RateOfFire / 1000,1)
    if baseWeaponData.RateOfFire > weaponData.RateOfFire then
        firerate.Bar.BackgroundColor3 = Color3.new(0, 1)
    elseif baseWeaponData.RateOfFire < weaponData.RateOfFire then
        firerate.Bar.BackgroundColor3 = Color3.new(1)
    else
        firerate.Bar.BackgroundColor3 = Color3.new(1,1,1)
    end

    recoil.Bar.Size = UDim2.fromScale(getRecoil(baseWeaponData) / 50,1)
    if getRecoil(baseWeaponData) > getRecoil(weaponData) then
        recoil.Bar.BackgroundColor3 = Color3.new(1)
    elseif getRecoil(baseWeaponData) < getRecoil(weaponData) then
        recoil.Bar.BackgroundColor3 = Color3.new(0, 1)
    else
        recoil.Bar.BackgroundColor3 = Color3.new(1,1,1)
    end

    stoppingPower.Bar.Size = UDim2.fromScale(baseWeaponData.StoppingPower / 1,1)
    if baseWeaponData.StoppingPower > weaponData.StoppingPower then
        stoppingPower.Bar.BackgroundColor3 = Color3.new(0, 1)
    elseif baseWeaponData.StoppingPower < weaponData.StoppingPower then
        stoppingPower.Bar.BackgroundColor3 = Color3.new(1)
    else
        stoppingPower.Bar.BackgroundColor3 = Color3.new(1,1,1)
    end

end

local function refreshGui()
    setUpSlots()
    setUpWeapon()
    UI.Inventory.WeaponCompare.Visible = false
end

local function useItem(slotUi)
    local item = Inventory[slotUi.Name]

    if (not item) or item.InUse or acts:checkAct("Reloading") then return end

    if item.Use == "EquipWeapon" then
        Inventory:ChangeSlot(slotUi.Name, "slot_13")
    else
        Inventory.ItemUsed:Fire(item.Use, item, slotUi.Name)
    end
  

    task.wait()
    refreshGui()
end

local function initGui()
    local step
    local originalSlot

    UI = UITemplate:Clone()
    UI.Parent = player.PlayerGui
    UI.Enabled = false

    for _,slotUi in ipairs(UI.Inventory.Slots:GetChildren()) do
        if not slotUi:IsA('Frame') then continue end

       local mouseEnter, mouseLeave = mouseOver.MouseEnterLeaveEvent(slotUi)

       mouseEnter:Connect(function()
            UIAnimationService.PlayAnimation(slotUi.Frame, 0.075, true)

            local item = Inventory[slotUi.Name]

            if not item then return end

            if typeof(item.Desc) == "string" then
                UI.Inventory.Description.Text = item.Desc
            else
                UI.Inventory.Description.Text = ""

                UI.Inventory.WeaponCompare.Visible = true
                compareWeapon(item)
            end
       end)

       mouseLeave:Connect(function()
            UIAnimationService.StopAnimation(slotUi.Frame)
            UI.Inventory.Description.Text = ""
            UI.Inventory.WeaponCompare.Visible = false
       end)

       local button:TextButton = slotUi.Button

       button.MouseButton2Click:Connect(function()
            useItem(slotUi)
       end)

       button.MouseButton1Down:Connect(function()
            originalSlot = slotUi

            if step then
                step:Disconnect()
            end

            UI.MoveObject.Image.Image = slotUi.Frame.Image.Image
            UIAnimationService.PlayAnimation(UI.MoveObject, 0.075, true)
            UI.MoveObject.Visible = true

            step = RunService.RenderStepped:Connect(function()
                local mousePosition = UserInputService:GetMouseLocation()
        
                UI.MoveObject.Position = UDim2.fromOffset(mousePosition.X, mousePosition.Y)

                if UI.Enabled then return end

                step:Disconnect()
                UIAnimationService.StopAnimation(UI.MoveObject)
                UI.MoveObject.Visible = false
            end)
       end)

       button.MouseButton1Up:Connect(function()
            UIAnimationService.StopAnimation(UI.MoveObject)
            UI.MoveObject.Visible = false

            if step then
                step:Disconnect()
            end

            if not originalSlot then
                return
            end

            Inventory:ChangeSlot(originalSlot.Name, slotUi.Name)
            refreshGui()
       end)

       button.InputBegan:Connect(function(input)
            if acts:checkAct("Reloading") then
                return
            end

           if input.KeyCode == Enum.KeyCode.Q then
                Inventory:DropItem(slotUi.Name)
           end

           refreshGui()
       end)
    end
end

function Inventory.OpenInventory()
    
    acts:createAct("InventoryOpen", "InventoryOpening")

    UI.SideBars.Image.Position = UDim2.fromScale(0,0)
    UI.Inventory.Visible = false
    UI.SideBars.Visible = true

    local ti = TweenInfo.new(0.25)

    refreshGui()

    UI.Enabled = true

    util.tween(Lighting.InventoryBlur, ti, {Size = 18})
    UIAnimationService.PlayAnimation(UI.SideBars, 0.025, false, true)

    task.wait(0.2)
    util.flickerUi(UI.Inventory, 0.01, 6)

    acts:removeAct("InventoryOpening")
end

function Inventory.CloseInventory()
    
    local ti = TweenInfo.new(0.5)

    util.flickerUi(UI.SideBars, 0.01, 6, true)
    util.flickerUi(UI.Inventory, 0.01, 6)

    util.tween(Lighting.InventoryBlur, ti, {Size = 0})

    UI.Enabled = false

    acts:removeAct("InventoryOpen")
end

function Inventory.Init()
    initGui()
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent or acts:checkAct("InventoryOpening") then
        return
    end

    if input.KeyCode == Enum.KeyCode.E then
        if acts:checkAct("InventoryOpen") then
            Inventory.CloseInventory()
        else
            Inventory.OpenInventory()
        end
    end
end)

RunService.Heartbeat:Connect(function()
    local character = player.Character
    if not character then
        return
    end

    local hungerBar = UI.Inventory.Player.HungerBar
    local heathBar = UI.Inventory.Player.HealthBar
    local armorBar = UI.Inventory.Player.ArmorBar

    hungerBar.Value.Text = math.round(character:GetAttribute("Hunger"))
    hungerBar.Bar.Size = UDim2.fromScale(character:GetAttribute("Hunger") / 100, 1)

    heathBar.Value.Text = math.round(character:GetAttribute("Health"))
    heathBar.Bar.Size = UDim2.fromScale(character:GetAttribute("Health") / 100, 1)

    armorBar.Value.Text = math.round(character:GetAttribute("Armor"))
    armorBar.Bar.Size = UDim2.fromScale(character:GetAttribute("Armor") / 100, 1)
end)

return Inventory