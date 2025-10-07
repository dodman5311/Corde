--// Services

local AchievementService = game:GetService("AchievementService")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local Inventory = {
	InventoryOpen = false,
	DROPPED_ITEM_LIFETIME = 30,
} -- {Name = "", Desc = "", Value = 1, InUse = false, Use = "Action"}

--// Instances
local player = Players.LocalPlayer
local client = script.Parent

local assets = ReplicatedStorage.Assets
local models = assets.Models
local gui = assets.Gui
local sounds = assets.Sounds

local UI = StarterGui.Inventory
local currentSelectedSlot
local camera = workspace.CurrentCamera

--// Modules
local Achievements = require(script.Parent.Achievements)
local Types = require(ReplicatedStorage.Shared.Types)
local UIAnimationService = require(client.UIAnimationService)
local acts = require(client.Acts)
local cameraService = require(client.Camera)
local globalInputService = require(client.GlobalInputService)
local itemsList = require(ReplicatedStorage.Shared.Items)
local loader = require(ReplicatedStorage.Packages[".pesde"]["sleitnick_loader@2.0.0"].loader)
local mouseOver = require(client.MouseOver)
local scales = require(client.Scales)
local signal = require(ReplicatedStorage.Packages.Signal)
local timer = require(client.Timer)
local util = require(client.Util)

type item = Types.item
type holdingObject = {
	Action: string?,
	SlotFrame: Frame?,
	Connection: RBXScriptConnection?,
}

--// Values
local currentNoteIndex = 0
local currentNoteItem: item
local rng = Random.new()
local inAction = false
local holdingObject: holdingObject = {
	Action = nil,
	SlotFrame = nil,
	Connection = nil,
}

local hasRead = {}

Inventory.ItemRemoved = signal.new()
Inventory.ItemAdded = signal.new()
Inventory.SlotValueChanged = signal.new()
Inventory.ItemUsed = signal.new()
Inventory.InvetoryToggled = signal.new()

Inventory.statusPumpTimer = timer:new("HealthPump", 1)

local InventorySize = 8
local STORAGE_SIZE = 12

--// Functions
function Inventory:ShowNotification(itemName: string, notificationMessage: string, color: Color3?)
	local newNotification = gui.Notification:Clone()
	newNotification.Parent = player.PlayerGui.HUD.Notifications

	newNotification.Text = itemName .. " " .. notificationMessage
	newNotification.TextColor3 = color or Color3.fromRGB(255, 175, 45)
	Debris:AddItem(newNotification, 6)

	local ti = TweenInfo.new(3, Enum.EasingStyle.Quart, Enum.EasingDirection.In, 0, false, 3)
	util.tween(newNotification, ti, { TextTransparency = 1 })
end

function Inventory:SearchForItem(itemName: string)
	if not itemName then
		return
	end

	for slot, item in pairs(self) do
		if not string.match(slot, "slot_") then
			continue
		end

		if item.Name ~= itemName then
			continue
		end

		return item, slot
	end
end

-- function Inventory:SearchForMatch(valueTable: {})
-- 	if not valueTable then
-- 		return
-- 	end

-- 	for slot, item in pairs(self) do
-- 		if not string.match(slot, "slot_") then
-- 			continue
-- 		end

-- 		local isMatch = true

-- 		for property, value in ipairs(valueTable) do
-- 			if item[property] ~= value then
-- 				isMatch = false
-- 			end
-- 		end

-- 		if not isMatch then
-- 			continue
-- 		end

-- 		return item, slot
-- 	end
-- end

function Inventory:CheckSlot(slot: string | number): item?
	if tonumber(slot) then
		slot = "slot_" .. slot
	end
	return self[slot]
end

function Inventory:GetFirstEmptySlot(): string? -- returns slot index, (String)
	for slotIndex = 1, InventorySize do
		if self:CheckSlot("slot_" .. slotIndex) then
			continue
		end

		return "slot_" .. slotIndex
	end

	return
end

local combineActions = {
	AddValue = function(item: item, itemToCombine: item, combineData)
		if item.InUse or itemToCombine.InUse then
			return
		end

		for _ = itemToCombine.Value, combineData.MaxValue - 1 do
			if item.Value == 0 then
				break
			end

			itemToCombine.Value += 1
			item.Value -= 1
		end

		util.PlaySound(sounds.LoadBullets, 0.1, 0.9)
	end,

	AddItem = function(item: item, itemToCombine: item, combineData)
		if item.InUse or itemToCombine.InUse then
			return
		end

		Inventory:AddItem(itemsList[combineData.Item])

		util.PlaySound(sounds.LoadBullets, 0.1, 0.9)
	end,
	Remove = function(item: item)
		Inventory:RemoveItem(item.Name)
	end,
	RemoveOnEmpty = function(item: item)
		if item.Value <= 0 then
			Inventory:RemoveItem(item.Name)
		end
	end,
	RemoveAll = function(item: item, itemToCombine: item)
		Inventory:RemoveItem(item.Name)
		Inventory:RemoveItem(itemToCombine.Name)
	end,
}

function Inventory:CombineSlots(slot, slotToCombineWith)
	local item: item = self[slot]
	local itemToCombine: item = self[slotToCombineWith]

	if not item or not slotToCombineWith or not itemToCombine or item == itemToCombine then
		return
	end

	local combineData = item["CombineData"] and item.CombineData[itemToCombine.Name]

	if not combineData then
		combineData = itemToCombine["CombineData"] and itemToCombine.CombineData[item.Name]

		local preItem = item -- switch primary and secondary items
		item = itemToCombine
		itemToCombine = preItem

		if not combineData then
			return
		end
	end

	combineActions[combineData.Action](item, itemToCombine, combineData)

	if not combineData["Result"] then
		return true
	end

	combineActions[combineData.Result](item, itemToCombine, combineData)

	return true
end

function Inventory:ChangeSlot(slot, slotToChangeTo)
	local item: item = self[slot]
	if not item or not slotToChangeTo then
		return
	end

	if slotToChangeTo == "Weapon_Slot" and typeof(item.Value) ~= "table" then
		return
	end

	if self[slotToChangeTo] then
		self[slot] = self[slotToChangeTo]
		self.SlotValueChanged:Fire(slot, self[slotToChangeTo])
	else
		self[slot] = nil
		self.SlotValueChanged:Fire(slot)
	end

	self[slotToChangeTo] = item
	self.SlotValueChanged:Fire(slotToChangeTo, self[slotToChangeTo])
end

function Inventory:AddItem(item: item)
	local slotToAddTo = self:GetFirstEmptySlot()

	if not slotToAddTo then
		self:ShowNotification("", "INVENTORY FULL", Color3.new(1))
		return
	end

	local newItem = table.clone(item)
	self:ShowNotification(item.Name, "Added to inventory")

	self[slotToAddTo] = newItem
	self.ItemAdded:Fire(newItem, slotToAddTo)
	self.SlotValueChanged:Fire(slotToAddTo, self[slotToAddTo])

	return newItem, slotToAddTo
end

function Inventory:RemoveItem(ItemNameOrSlot)
	if not ItemNameOrSlot then
		return
	end

	local item: item, slot

	if Inventory[ItemNameOrSlot] then
		item = Inventory[ItemNameOrSlot]
		slot = ItemNameOrSlot
	else
		item, slot = self:SearchForItem(ItemNameOrSlot)
	end

	if not item then
		return
	end

	self:ShowNotification(item.Name, "Removed from inventory")
	self.ItemRemoved:Fire(item, slot)
	self[slot] = nil
	self.SlotValueChanged:Fire(slot)

	return item, slot
end

function Inventory:DropItem(index) -- index can be an item table, item name, or slot index
	if not index then
		return
	end

	local item: item
	local slot

	if typeof(index) == "table" then
		item = index
	else
		item, slot = self:SearchForItem(index)
	end

	if not item or item.CanArchive then
		return
	end

	self:RemoveItem(slot)

	local droppedItem = models.DroppedItem:Clone()
	local character = player.Character

	local data = require(droppedItem.Container)

	table.insert(data, item)

	droppedItem.Parent = workspace
	droppedItem.Name = item.Name
	droppedItem.CFrame = character:GetPivot()
	droppedItem.AssemblyLinearVelocity = (character:GetPivot() * CFrame.Angles(0, math.rad(rng:NextNumber(-30, 30)), 0)).LookVector
		* rng:NextNumber(30, 60)
	droppedItem:SetAttribute("DroppedAt", os.clock())

	Debris:AddItem(droppedItem, Inventory.DROPPED_ITEM_LIFETIME)
end

function Inventory:pickupFromContainer(object)
	if not object or not object:FindFirstChild("Container") then
		return
	end

	local containerData = require(object.Container)

	local toRemove = {}

	for _, item: item in ipairs(containerData) do
		local newItem, slot = self:AddItem(item)
		if not newItem then
			util.PlaySound(sounds.InventoryFull)
			break
		end
		table.insert(toRemove, item)

		if util.getSetting("Gameplay", "Auto Read Notes") and item.Use == "Read" then
			Inventory.OpenInventory()
			Inventory:UseItem(UI.Inventory.Slots:FindFirstChild(slot))
		end
	end

	if #toRemove > 0 then
		util.PlaySound(sounds.ItemAdded, 0.05)
	end

	for _, item in ipairs(toRemove) do
		table.remove(containerData, table.find(containerData, item))
	end

	if object:GetAttribute("RemoveOnEmpty") and #containerData == 0 then
		object:Destroy()
	end
end

local function assignItemColor(slotUi, item)
	if item.InUse then
		slotUi.Value.TextColor3 = Color3.fromRGB(255, 185, 35)
		slotUi.ItemName.TextColor3 = Color3.fromRGB(255, 185, 35)
	else
		slotUi.Value.TextColor3 = Color3.fromRGB(255, 255, 255)
		slotUi.ItemName.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
end

local function setUpSlots(slotParent, isOpening)
	for _, slotUi in ipairs(slotParent:GetChildren()) do
		if not slotUi:IsA("Frame") then
			continue
		end

		local item: item = Inventory[slotUi.Name]

		if isOpening then
			slotUi.Select.Visible = false
			slotUi.Glow.Visible = false
			slotUi.Size = UDim2.fromScale(0.9, 0.075)
		end

		if item then
			slotUi:SetAttribute("ImageId", item.Icon)
			slotUi.ItemName.Text = item.Name
			slotUi.ItemName.TextTransparency = 0

			slotUi.Value.Text = typeof(item.Value) == "number" and item.Value or ""

			if slotUi.Select.Visible then
				continue
			end

			assignItemColor(slotUi, item)
		else
			slotUi:SetAttribute("ImageId", "")
			slotUi.ItemName.Text = "Vacant"
			slotUi.ItemName.TextTransparency = 0.7
			slotUi.Value.Text = ""
		end
	end
end

local function getRecoil(stats)
	return stats.Recoil ---(stats.Recoil * stats.RecoilSpeed) / math.clamp((stats.RateOfFire / 60), stats.RecoilSpeed, 100)
end

local function setUpWeapon()
	local weapon: item = Inventory["Weapon_Slot"]

	local weaponUi = UI.Inventory.Weapon

	local accuracy = weaponUi.AccuracyBar
	local damage = weaponUi.DamageBar
	local firerate = weaponUi.FireRateBar
	local recoil = weaponUi.RecoilBar
	local stoppingPower = weaponUi.StoppingPowerBar
	local display = weaponUi.WeaponDisplay

	if not weapon then
		accuracy.Bar.Size = UDim2.fromScale(0, 1)
		accuracy.Value.Text = 0

		damage.Bar.Size = UDim2.fromScale(0, 1)
		damage.Value.Text = 0

		firerate.Bar.Size = UDim2.fromScale(0, 1)
		firerate.Value.Text = 0

		recoil.Bar.Size = UDim2.fromScale(0, 1)
		recoil.Value.Text = 0

		stoppingPower.Bar.Size = UDim2.fromScale(0, 1)
		stoppingPower.Value.Text = 0.0

		weaponUi.ItemName.Text = "Vacant"
		display.Visible = false
		UI.Inventory.WeaponImage.Visible = true
	else
		local weaponData = weapon.Value

		accuracy.Bar.Size = UDim2.fromScale(math.abs(weaponData.Spread - 20) / 20, 1)
		accuracy.Value.Text = (math.abs(weaponData.Spread - 20) / 20) * 100

		damage.Bar.Size = UDim2.fromScale(weaponData.Damage * weaponData.BulletCount / 100, 1)
		damage.Value.Text = weaponData.Damage

		if weaponData.BulletCount > 1 then
			damage.Value.Text = weaponData.Damage .. "x" .. weaponData.BulletCount
		end

		firerate.Bar.Size = UDim2.fromScale(weaponData.RateOfFire / 1000, 1)
		firerate.Value.Text = weaponData.RateOfFire

		recoil.Bar.Size = UDim2.fromScale(getRecoil(weaponData) / 100, 1)
		recoil.Value.Text = math.round(getRecoil(weaponData) * 10) / 10

		stoppingPower.Bar.Size = UDim2.fromScale(weaponData.StoppingPower / 1, 1)
		stoppingPower.Value.Text = weaponData.StoppingPower

		weaponUi.ItemName.Text = weapon.Name
		display.Image = weaponData.DisplayImage
		display.Visible = true
		UI.Inventory.WeaponImage.Visible = false
	end
end

local function compareWeapon(baseWeapon: item)
	local weapon: item? = Inventory["Weapon_Slot"]

	local weaponUi = UI.Inventory.WeaponCompare

	local accuracy = weaponUi.AccuracyBar
	local damage = weaponUi.DamageBar
	local firerate = weaponUi.FireRateBar
	local recoil = weaponUi.RecoilBar
	local stoppingPower = weaponUi.StoppingPowerBar

	local weaponData = {
		Type = 1,
		RateOfFire = 1,
		ReloadTime = 100,
		Damage = 0,
		BulletCount = 0,
		FireMode = 0,
		Spread = 20,
		StoppingPower = 0,
		Recoil = 0,
		RecoilSpeed = 0,
	}

	if weapon then
		weaponData = weapon.Value
	end

	local baseWeaponData = baseWeapon.Value

	accuracy.Bar.Size = UDim2.fromScale(math.abs(baseWeaponData.Spread - 20) / 20, 1)
	if baseWeaponData.Spread > weaponData.Spread then
		accuracy.Bar.BackgroundColor3 = Color3.new(1)
	elseif baseWeaponData.Spread < weaponData.Spread then
		accuracy.Bar.BackgroundColor3 = Color3.new(0, 1)
	else
		accuracy.Bar.BackgroundColor3 = Color3.new(1, 1, 1)
	end

	damage.Bar.Size = UDim2.fromScale((baseWeaponData.Damage * baseWeaponData.BulletCount) / 100, 1)
	if baseWeaponData.Damage * baseWeaponData.BulletCount > weaponData.Damage * weaponData.BulletCount then
		damage.Bar.BackgroundColor3 = Color3.new(0, 1)
	elseif baseWeaponData.Damage * baseWeaponData.BulletCount < weaponData.Damage * weaponData.BulletCount then
		damage.Bar.BackgroundColor3 = Color3.new(1)
	else
		damage.Bar.BackgroundColor3 = Color3.new(1, 1, 1)
	end

	firerate.Bar.Size = UDim2.fromScale(baseWeaponData.RateOfFire / 1000, 1)
	if baseWeaponData.RateOfFire > weaponData.RateOfFire then
		firerate.Bar.BackgroundColor3 = Color3.new(0, 1)
	elseif baseWeaponData.RateOfFire < weaponData.RateOfFire then
		firerate.Bar.BackgroundColor3 = Color3.new(1)
	else
		firerate.Bar.BackgroundColor3 = Color3.new(1, 1, 1)
	end

	recoil.Bar.Size = UDim2.fromScale(getRecoil(baseWeaponData) / 100, 1)
	if getRecoil(baseWeaponData) > getRecoil(weaponData) then
		recoil.Bar.BackgroundColor3 = Color3.new(1)
	elseif getRecoil(baseWeaponData) < getRecoil(weaponData) then
		recoil.Bar.BackgroundColor3 = Color3.new(0, 1)
	else
		recoil.Bar.BackgroundColor3 = Color3.new(1, 1, 1)
	end

	stoppingPower.Bar.Size = UDim2.fromScale(baseWeaponData.StoppingPower / 1, 1)
	if baseWeaponData.StoppingPower > weaponData.StoppingPower then
		stoppingPower.Bar.BackgroundColor3 = Color3.new(0, 1)
	elseif baseWeaponData.StoppingPower < weaponData.StoppingPower then
		stoppingPower.Bar.BackgroundColor3 = Color3.new(1)
	else
		stoppingPower.Bar.BackgroundColor3 = Color3.new(1, 1, 1)
	end
end

local function showHungerResult(foodItem: item)
	local hungerAfter = UI.Inventory.HungerAfter
	local hungerAfterGrad = hungerAfter.UIGradient

	local character = player.Character
	if not character or not Inventory.InventoryOpen then
		return
	end

	local hunger = character:GetAttribute("Hunger")
	local newHungerValue = hunger + foodItem.Value.Hunger
	local invertedHungerValue = math.clamp(math.abs((hunger / 100) - 1), 0.001, 0.989)
	local invertedNewHungerValue = math.clamp(math.abs((newHungerValue / 100) - 1), 0.001, 0.989)

	local sequence = NumberSequence.new {
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(invertedNewHungerValue, 1),
		NumberSequenceKeypoint.new(invertedNewHungerValue + 0.01, 0),
		NumberSequenceKeypoint.new(invertedHungerValue, 0),
		NumberSequenceKeypoint.new(invertedHungerValue + 0.01, 1),
		NumberSequenceKeypoint.new(1, 1),
	}

	hungerAfterGrad.Transparency = sequence
	hungerAfter.Visible = true
end

local function closeNote()
	local noteUi = UI.Note
	if not noteUi.Visible then
		return
	end
	Inventory.noteNavigation:Disable()

	currentNoteItem = nil
	util.tween(noteUi, TweenInfo.new(0.25, Enum.EasingStyle.Linear), { GroupTransparency = 1 }, false, function()
		noteUi.Visible = false
	end, Enum.PlaybackState.Completed)

	globalInputService:SelectGui(UI.Inventory.Slots)
end

local function clearKeyPrompts()
	for _, child in ipairs(UI.Note.Message:GetChildren()) do -- clear previous prompts
		if child.Name == "Keyprompt" then
			child:Destroy()
		end
	end
end

local function showNoteKeyprompts(note: item)
	if typeof(note.Value.Message[1]) == "string" then
		return
	end

	local keyprompts = note.Value.Message[1]

	for _, prompt in ipairs(keyprompts) do
		local key, button, preText, yPos, index = table.unpack(prompt)

		if index ~= currentNoteIndex then
			continue
		end

		local newPrompt: ImageLabel = gui.Keyprompt:Clone()
		newPrompt.Image:AddTag("KeyPrompt")

		if key == "InputName" then
			newPrompt.Image:SetAttribute("InputName", button)
		else
			newPrompt.Image:SetAttribute("Key", key)
			newPrompt.Image:SetAttribute("Button", button)
		end

		newPrompt.Parent = UI.Note.Message

		newPrompt.Image.Position = UDim2.fromScale(1, yPos)
		newPrompt.Text = preText
		newPrompt.TextSize = UI.Note.Message.TextSize
	end

	globalInputService:CheckKeyPrompts()
end

local function nextNotePage(note: item, indexChange: number)
	if not note then
		return
	end

	local size = #note.Value.Message

	if typeof(note.Value.Message[1]) ~= "string" then
		size -= 1
	end

	local noteUi = UI.Note
	currentNoteIndex = math.clamp(currentNoteIndex + indexChange, 0, size + 1)
	util.PlaySound(sounds.Paper, 0.075)

	if currentNoteIndex > size then
		closeNote()
		return
	elseif currentNoteIndex == size then
		noteUi.Message.Page.Text = `<<  {currentNoteIndex} / {size}    `
	elseif currentNoteIndex == 0 then
		noteUi.Message.Page.Text = `    {currentNoteIndex} / {size}  >>`
	else
		noteUi.Message.Page.Text = `<<  {currentNoteIndex} / {size}  >>`
	end

	clearKeyPrompts()

	if currentNoteIndex == 1 then
		util.tween(
			noteUi.NoteImage,
			TweenInfo.new(0.25, Enum.EasingStyle.Linear),
			{ ImageColor3 = Color3.new(0.1, 0.1, 0.1) }
		)
	elseif currentNoteIndex == 0 then
		util.tween(
			noteUi.NoteImage,
			TweenInfo.new(0.25, Enum.EasingStyle.Linear),
			{ ImageColor3 = Color3.new(1, 1, 1) }
		)
		noteUi.Message.Text = ""
		return
	end

	if typeof(note.Value.Message[1]) ~= "string" then
		noteUi.Message.Text = note.Value.Message[currentNoteIndex + 1]
	else
		noteUi.Message.Text = note.Value.Message[currentNoteIndex]
	end

	showNoteKeyprompts(note)
end

local function openNote(note: item)
	clearKeyPrompts()
	Inventory.noteNavigation:Enable()
	currentNoteItem = note

	local noteUi = UI.Note
	local message: TextLabel = noteUi.Message
	noteUi.Visible = true

	noteUi.NoteImage.ImageColor3 = Color3.new(1, 1, 1)
	noteUi.NoteImage.Image = note.Value.Image

	message.TextSize = math.floor(message.AbsoluteSize.X / 50)

	currentNoteIndex = 0
	nextNotePage(note, 0)

	util.tween(UI.Note, TweenInfo.new(0.5, Enum.EasingStyle.Linear), { GroupTransparency = 0 })

	if globalInputService:GetInputSource().Type == "Gamepad" then
		GuiService.SelectedObject = nil
	end
end

local function hideDescription()
	local infoFrame = UI.Inventory.Info

	infoFrame.Visible = false
	UIAnimationService.StopAnimation(infoFrame.BackgroundImage)
	UI.Inventory.WeaponCompare.Visible = false
	UI.Inventory.HungerAfter.Visible = false
end

local function refreshGui(isOpening)
	setUpSlots(UI.Inventory.Slots, isOpening)
	setUpSlots(UI.Storage.Slots_Storage, isOpening)
	setUpSlots(UI.Storage.Slots_Inventory, isOpening)
	setUpWeapon()
	UI.Inventory.WeaponCompare.Visible = false
end

local function emptyWeaponSlot()
	if acts:checkAct("Reloading") then
		return
	end

	util.PlayFrom(player.Character, sounds.Unequip)

	Inventory:ChangeSlot("Weapon_Slot", Inventory:GetFirstEmptySlot())
	refreshGui()
end

local function getSlotIndexFromUi(slotUi: Frame): number?
	return tonumber(string.sub(slotUi.Name, 6))
end

local function createGuiSlot(parent, index)
	local newSlot = UI.Slot_Template:Clone()
	newSlot.Name = "slot_" .. index
	newSlot.Parent = parent
	newSlot.Visible = true
end

local function createGuiSlots()
	print(InventorySize)

	for slotIndex = 1, InventorySize do
		createGuiSlot(UI.Inventory.Slots, slotIndex)
	end

	for slotIndex = 1, InventorySize do
		createGuiSlot(UI.Storage.Slots_Inventory, slotIndex)
	end

	local nextIndex = InventorySize + 1
	for slotIndex = nextIndex, nextIndex + STORAGE_SIZE do
		createGuiSlot(UI.Storage.Slots_Storage, slotIndex)
	end
end

local function showFrameDescription(frame)
	local infoFrame = UI.Inventory.Info

	infoFrame.Visible = true
	infoFrame.BackgroundImage.Visible = false

	infoFrame.DescriptionIndex.Text = frame.Name
	infoFrame.Description.Text = frame:GetAttribute("Description")
end

local function showItemDesciption(item: item?, infoFrameParent)
	if not item then
		return
	end
	local infoFrame = infoFrameParent.Info
	infoFrame.Visible = true

	infoFrame.DescriptionIndex.Text = item.Name
	infoFrame.Description.Text = item.Desc

	infoFrame.BackgroundImage.Visible = true
	infoFrame.BackgroundImage.Image.Image = item.Icon
	UIAnimationService.PlayAnimation(infoFrame.BackgroundImage, 0.1, true)
end

local function slotUiHovered(slotUi)
	local item: item = Inventory[slotUi.Name]
	local ti = TweenInfo.new(0.25, Enum.EasingStyle.Quart)

	if not item then
		return
	end

	util.PlaySound(sounds.InventoryHover)

	slotUi.Select.Visible = true
	slotUi.Glow.Visible = true
	slotUi.ItemName.TextColor3 = Color3.new()
	slotUi.Value.TextColor3 = Color3.new()

	util.tween(slotUi, ti, { Size = UDim2.fromScale(0.925, 0.1) })

	task.wait()

	if item.Use == "EquipWeapon" then
		UI.Inventory.WeaponCompare.Visible = true
		compareWeapon(item)
	elseif item.Use == "Eat" then
		showHungerResult(item)
	end

	showItemDesciption(item, slotUi.Parent.Parent)
end

local function slotUiExited(slotUi)
	hideDescription()
	slotUi.Select.Visible = false
	slotUi.Glow.Visible = false
	slotUi.ItemName.TextColor3 = Color3.new(1, 1, 1)

	local ti = TweenInfo.new(0.5, Enum.EasingStyle.Quint)
	util.tween(slotUi, ti, { Size = UDim2.fromScale(0.9, 0.075) })

	local item: item = Inventory[slotUi.Name]
	if item then
		assignItemColor(slotUi, item)
	end
end

local function holdSlot(slotUi: Frame, action: "Move" | "Combine")
	if holdingObject.Connection then
		holdingObject.Connection:Disconnect()
	end

	holdingObject.Action = action
	holdingObject.SlotFrame = slotUi

	UI.MoveObject.Image.Image = slotUi:GetAttribute("ImageId")
	UIAnimationService.PlayAnimation(UI.MoveObject, 0.075, true)
	UI.MoveObject.Visible = true

	holdingObject.Connection = RunService.RenderStepped:Connect(function()
		local mousePosition = UserInputService:GetMouseLocation()

		UI.MoveObject.Position = UDim2.fromOffset(mousePosition.X, mousePosition.Y)

		if UI.Enabled then
			return
		end

		UIAnimationService.StopAnimation(UI.MoveObject)
		UI.MoveObject.Visible = false
	end)
end

function Inventory:UseItem(slotUi)
	if getSlotIndexFromUi(slotUi) > InventorySize then
		util.PlaySound(sounds.Deny)
		return
	end

	if slotUi.Name == "Weapon" then
		emptyWeaponSlot()
		return
	end
	local item: item = Inventory[slotUi.Name]

	if not item or acts:checkAct("Reloading") then
		return
	end

	if item.Use == "EquipWeapon" then
		Inventory:ChangeSlot(slotUi.Name, "Weapon_Slot")
	elseif item.Use == "Read" then
		openNote(item)
	else
		Inventory.ItemUsed:Fire(item.Use, item, slotUi.Name)
	end

	slotUiExited(slotUi)
	task.delay(0.05, refreshGui)
end

local optionFunctions = {
	Use = function(slotUi)
		Inventory:UseItem(slotUi)
	end,
	Drop = function(slotUi)
		Inventory:DropItem(slotUi.ItemName.Text)
		refreshGui()
	end,
	Move = function(slotUi)
		holdSlot(slotUi, "Move")
	end,
	Combine = function(slotUi)
		holdSlot(slotUi, "Combine")
	end,
}

local function closeOptionsMenu()
	if not currentSelectedSlot then
		return
	end
	inAction = false

	currentSelectedSlot.ZIndex = 1
	local ti = TweenInfo.new(0.3, Enum.EasingStyle.Quart)

	local actionsFrame = currentSelectedSlot:FindFirstChild("ActionsFrame")
	if not actionsFrame then
		return
	end

	util.tween(actionsFrame.Actions, ti, { Position = UDim2.fromScale(0, -1) }, false, function()
		actionsFrame:Destroy()
	end)

	currentSelectedSlot = nil
end

local function openOptionsMenu(slotUi)
	if currentSelectedSlot == slotUi then
		closeOptionsMenu()
		return
	else
		closeOptionsMenu()
	end

	if not Inventory[slotUi.Name] then
		return
	end

	local actionsFrame = gui.ActionsFrame:Clone()
	local enterAction, leaveAction = mouseOver.MouseEnterLeaveEvent(actionsFrame)
	local item: item = Inventory[slotUi.Name]

	local ti = TweenInfo.new(0.25, Enum.EasingStyle.Quart)
	local ti_0 = TweenInfo.new(0.1, Enum.EasingStyle.Quart)
	local ti_1 = TweenInfo.new(0.25, Enum.EasingStyle.Quint)
	local slotNumber = getSlotIndexFromUi(slotUi)

	actionsFrame.Parent = slotUi
	currentSelectedSlot = slotUi
	slotUi.ZIndex = 2
	slotUi.Button.NextSelectionDown = actionsFrame.Actions.Use
	actionsFrame.Actions.Use.NextSelectionUp = slotUi.Button
	util.tween(actionsFrame.Actions, ti, { Position = UDim2.fromScale(0, 0) })
	actionsFrame.Actions.Drop.Visible = not item.CanArchive

	enterAction:Connect(function()
		inAction = true
	end)

	leaveAction:Connect(function()
		inAction = false
	end)

	for _, optionButton: ImageButton in ipairs(actionsFrame.Actions:GetChildren()) do
		if not optionButton:IsA("ImageButton") then
			continue
		end

		local mouseEnterOption, mouseLeaveOption = mouseOver.MouseEnterLeaveEvent(optionButton)
		mouseEnterOption:Connect(function()
			local sound = util.PlaySound(sounds.OptionClick)
			sound.PlaybackSpeed = 0.65
			sound.Volume = 0.1
			optionButton.ImageColor3 = Color3.fromRGB(255, 240, 193)
			util.tween(optionButton, ti_0, { Size = UDim2.fromScale(1.05, 0.25) })
		end)

		mouseLeaveOption:Connect(function()
			optionButton.ImageColor3 = Color3.new(1, 1, 1)
			util.tween(optionButton, ti_1, { Size = UDim2.fromScale(1, 0.235) })
		end)

		optionButton.MouseButton1Click:Connect(function()
			if acts:checkAct("Reloading") then
				return
			end

			util.PlaySound(sounds.OptionClick)
			closeOptionsMenu()
			optionFunctions[optionButton.Name](slotUi)
		end)
	end

	local slot_1 = UI.Inventory.Slots:FindFirstChild("slot_" .. slotNumber + 1)
	local slot_2 = UI.Inventory.Slots:FindFirstChild("slot_" .. slotNumber + 2)
	local slot_3 = UI.Inventory.Slots:FindFirstChild("slot_" .. slotNumber + 3)

	actionsFrame.Actions.Use.NextSelectionRight = slotUi.Button
	actionsFrame.Actions.Move.NextSelectionRight = slot_1 and slot_1.Button
	actionsFrame.Actions.Combine.NextSelectionRight = slot_2 and slot_2.Button
	actionsFrame.Actions.Drop.NextSelectionRight = slot_3 and slot_3.Button
end

local function connectSlotButton(slotUi)
	if not slotUi:IsA("Frame") then
		return
	end

	local button: ImageButton = slotUi.Button
	local slotNumberIndex = getSlotIndexFromUi(slotUi)

	button.MouseEnter:Connect(function()
		if inAction then
			return
		end
		slotUiHovered(slotUi)
	end)

	button.MouseLeave:Connect(function()
		slotUiExited(slotUi)
	end)

	button.SelectionGained:Connect(function()
		if inAction then
			return
		end
		slotUiHovered(slotUi)
	end)

	button.SelectionLost:Connect(function()
		slotUiExited(slotUi)
	end)

	button.MouseButton2Click:Connect(function()
		Inventory:UseItem(slotUi)
		closeOptionsMenu()
	end)

	button.MouseButton1Click:Connect(function()
		UIAnimationService.StopAnimation(UI.MoveObject)
		UI.MoveObject.Visible = false

		if holdingObject.Connection then
			holdingObject.Connection:Disconnect()
		end

		if not holdingObject.SlotFrame then
			openOptionsMenu(slotUi)
			return
		end

		if holdingObject.Action == "Move" then
			local item = Inventory:CheckSlot(holdingObject.SlotFrame.Name)

			if item and item.InUse and slotNumberIndex > InventorySize then
				util.PlaySound(sounds.Deny)
			else
				local clickSound = util.PlaySound(sounds.OptionClick)
				clickSound.PlaybackSpeed = 0.8
				Inventory:ChangeSlot(holdingObject.SlotFrame.Name, slotUi.Name)
			end
		elseif holdingObject.Action == "Combine" then
			if Inventory:CombineSlots(holdingObject.SlotFrame.Name, slotUi.Name) then
				util.PlaySound(sounds.Confirm)
			else
				util.PlaySound(sounds.Deny)
			end
		end

		holdingObject = {}
		refreshGui()
	end)

	button.InputBegan:Connect(function(input)
		if acts:checkAct("Reloading") then
			return
		end

		if input.KeyCode == Enum.KeyCode.Q then
			Inventory:DropItem(slotUi.ItemName.Text)
			refreshGui()
		end

		if input.KeyCode == Enum.KeyCode.Return then
			Inventory:UseItem(slotUi)
		end

		refreshGui()
	end)
end

local function initGui()
	UI.Parent = player.PlayerGui
	UI.Enabled = false

	-- set up note
	UI.Note.GroupTransparency = 1

	local nextButton: TextButton = UI.Note.Next
	local prevButton: TextButton = UI.Note.Prev
	local exitButton: TextButton = UI.Note.Exit
	local weaponDisplay = UI.Inventory.Weapon.WeaponDisplay

	local ti = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true)
	util.tween(
		UI.Inventory.HungerAfter,
		ti,
		{ ImageTransparency = 0.75, BackgroundColor3 = Color3.fromRGB(126, 255, 249) }
	)

	nextButton.MouseButton1Click:Connect(function()
		nextNotePage(currentNoteItem, 1)
	end)

	prevButton.MouseButton1Click:Connect(function()
		nextNotePage(currentNoteItem, -1)
	end)

	exitButton.MouseButton1Click:Connect(closeNote)

	weaponDisplay.MouseButton2Click:Connect(emptyWeaponSlot)
	weaponDisplay.MouseEnter:Connect(function()
		util.PlaySound(sounds.InventoryHover)
		task.wait(0.05)
		showItemDesciption(Inventory:CheckSlot("Weapon_Slot"), UI.Inventory)
	end)

	weaponDisplay.MouseLeave:Connect(hideDescription)

	weaponDisplay.SelectionGained:Connect(function()
		util.PlaySound(sounds.InventoryHover)
		task.wait(0.05)
		showItemDesciption(Inventory:CheckSlot("Weapon_Slot"), UI.Inventory)
	end)

	weaponDisplay.SelectionLost:Connect(hideDescription)

	for _, frame: Frame in ipairs(CollectionService:GetTagged("DescriptionFrame")) do
		local mouseEnter, mouseLeave = mouseOver.MouseEnterLeaveEvent(frame)

		mouseEnter:Connect(function()
			showFrameDescription(frame)
		end)

		mouseLeave:Connect(hideDescription)
	end
end

function Inventory.OpenInventory(isStorage: boolean?)
	local ti = TweenInfo.new(0.25)
	local ti_0 = TweenInfo.new(0.75, Enum.EasingStyle.Quint)

	Inventory.InvetoryToggled:Fire(true)

	globalInputService.inputActions["N.E.T"]:Disable()
	globalInputService.inputActions["Ready Weapon"]:Disable()
	globalInputService.inputActions["Interact"]:Disable()

	Inventory.InventoryInteract:Enable()
	scales.activeScales["InteractDisabled"]:Add()

	if not acts:checkAct("InDialogue") then
		cameraService.followViewDistance.current = 1
	end

	util.PlaySound(sounds.InventoryOpen)
	sounds.InventoryAmbience:Play()

	acts:createAct("InventoryOpening")
	Inventory.InventoryOpen = true

	refreshGui(true)

	UI.Inventory.Visible = false
	UI.Storage.Visible = false
	UI.Enabled = true
	util.tween(Lighting.InventoryBlur, ti, { Size = 18 })

	if isStorage then
		UI.Storage.Size = UDim2.fromScale(0.925, 0.925)
		util.tween(UI.Storage, ti_0, { Size = UDim2.fromScale(0.975, 0.975) })
		util.flickerUi(UI.Storage, 0.01, 6)
		globalInputService:SelectGui(UI.Storage.Slots_Inventory)
	else
		UI.Inventory.Size = UDim2.fromScale(0.925, 0.925)
		util.tween(UI.Inventory, ti_0, { Size = UDim2.fromScale(0.975, 0.975) })
		util.flickerUi(UI.Inventory, 0.01, 6)
		globalInputService:SelectGui(UI.Inventory.Slots)
	end

	acts:removeAct("InventoryOpening")
end

function Inventory.CloseInventory()
	globalInputService.inputActions["N.E.T"]:Enable()
	globalInputService.inputActions["Ready Weapon"]:Enable()
	globalInputService.inputActions.Interact:Enable()

	Inventory.InventoryInteract:Disable()
	scales.activeScales["InteractDisabled"]:Remove()
	closeNote()

	if not acts:checkAct("InDialogue") then
		cameraService.followViewDistance.current = cameraService.followViewDistance.default
	end

	util.PlaySound(sounds.InventoryClose)
	sounds.InventoryAmbience:Stop()

	local ti = TweenInfo.new(0.5)

	if UI.Inventory.Visible then
		util.flickerUi(UI.Inventory, 0.01, 6)
	end
	if UI.Inventory.Visible then
		util.flickerUi(UI.Storage, 0.01, 6)
	end

	util.tween(Lighting.InventoryBlur, ti, { Size = 0 })

	UI.Enabled = false

	Inventory.InventoryOpen = false
	Inventory.InvetoryToggled:Fire(false)

	closeOptionsMenu()

	if holdingObject.Connection then
		holdingObject.Connection:Disconnect()
	end

	holdingObject = {}
	UI.MoveObject.Visible = false
end

local function noteNavigationInput(state, input)
	if state ~= Enum.UserInputState.Begin then
		return
	end

	if input.KeyCode == Enum.KeyCode.DPadRight then
		nextNotePage(currentNoteItem, 1)
	end

	if input.KeyCode == Enum.KeyCode.DPadLeft then
		nextNotePage(currentNoteItem, -1)
	end

	if input.KeyCode == Enum.KeyCode.DPadUp or input.KeyCode == Enum.KeyCode.DPadDown then
		closeNote()
	end
end

local function toggleInventoryKey(state, input)
	if state ~= Enum.UserInputState.Begin or acts:checkAct("InventoryOpening") then
		return
	end

	if input.KeyCode == Enum.KeyCode.ButtonB then
		if not Inventory.InventoryOpen then
			return
		end
		Inventory.CloseInventory()
		return
	end

	if Inventory.InventoryOpen then
		Inventory.CloseInventory()
	else
		Inventory.OpenInventory()
	end
end

local function inventoryInteract(state, input)
	if state ~= Enum.UserInputState.Begin or not GuiService.SelectedObject then
		return
	end

	if input.KeyCode == Enum.KeyCode.ButtonB then
		Inventory:DropItem(GuiService.SelectedObject.Parent.Name)
		refreshGui()
		closeOptionsMenu()
	end

	if input.KeyCode == Enum.KeyCode.ButtonX then
		Inventory:UseItem(GuiService.SelectedObject.Parent)
		closeOptionsMenu()
	end

	if acts:checkAct("Reloading") then
		return
	end

	refreshGui()
end

local function pumpHealthStatus()
	local character = player.Character
	if not character then
		return
	end

	local health = character:GetAttribute("Health") / 100

	local ti = TweenInfo.new(math.clamp(health, 0.5, 1) / 2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	local healthDisplay = UI.Inventory.PlayerHealth

	healthDisplay.ImageTransparency = 0
	util.tween(healthDisplay, ti, { ImageTransparency = 0.5 })
end

local function updatePlayerStatus()
	local character = player.Character
	if not character or not Inventory.InventoryOpen then
		return
	end

	local hungerDisplay = UI.Inventory.Hunger
	local heathDisplay = UI.Inventory.PlayerHealth

	local health = character:GetAttribute("Health") / 100
	local hunger = character:GetAttribute("Hunger")
	local invertedHungerValue = math.abs((hunger / 100) - 1)

	heathDisplay.ImageColor3 = Color3.new(1):Lerp(Color3.fromRGB(125, 245, 255), health)

	hungerDisplay.UIGradient.Offset = Vector2.new(0, invertedHungerValue)

	Inventory.statusPumpTimer.WaitTime = math.clamp(health, 0.15, 1)
	Inventory.statusPumpTimer:Run()

	hungerDisplay.NoHunger.Visible = hunger <= 0

	if hunger <= 0 then
		hungerDisplay.NoHunger.Position = UDim2.fromScale(rng:NextNumber(0.45, 0.55), rng:NextNumber(0.45, 0.55))
	end
end

function Inventory.PlayerDied()
	Inventory.ToggleInventoryInput:Disable()
end

local function checkForPrepperAchievement(item)
	local door = workspace:FindFirstChild("KeyholeDoor", true)
	if door and item.Name == "M45A1" then
		Achievements:AwardAchievement(Achievements.Ids.PreppersInstinct)
	end
end

function Inventory.StartGame()
	Inventory.ToggleInventoryInput:Enable()

	local difficulty = workspace:GetAttribute("Difficulty")
	InventorySize += math.abs(difficulty - 2) * 2 -- @Difficulty set slots

	local padSize = UDim.new(difficulty * 0.0075, 0)

	local slots = UI.Inventory.Slots
	local storageInvSlots = UI.Storage.Slots_Inventory

	slots.UIListLayout.Padding = padSize
	storageInvSlots.UIListLayout.Padding = padSize

	createGuiSlots()

	for _, slotUi in ipairs(UI.Inventory.Slots:GetChildren()) do
		connectSlotButton(slotUi)
	end

	for _, slotUi in ipairs(UI.Storage.Slots_Inventory:GetChildren()) do
		connectSlotButton(slotUi)
	end

	for _, slotUi in ipairs(UI.Storage.Slots_Storage:GetChildren()) do
		connectSlotButton(slotUi)
	end

	Inventory.ItemAdded:Connect(checkForPrepperAchievement)
end

function Inventory.Init()
	Inventory.noteNavigation = globalInputService.CreateInputAction(
		"NoteNavigation",
		noteNavigationInput,
		{ Enum.KeyCode.Down, Enum.KeyCode.Up, Enum.KeyCode.Left, Enum.KeyCode.Right },
		{ Enum.KeyCode.DPadDown, Enum.KeyCode.DPadUp, Enum.KeyCode.DPadLeft, Enum.KeyCode.DPadRight }
	)
	Inventory.InventoryInteract =
		globalInputService.CreateInputAction("InventoryInteraction", inventoryInteract, Enum.KeyCode.ButtonX)

	Inventory.InventoryInteract:Disable()
	Inventory.noteNavigation:Disable()
	Inventory.ToggleInventoryInput:Disable()

	initGui()
end

--// Main //--

Inventory.ToggleInventoryInput = globalInputService.CreateInputAction(
	"Inventory",
	toggleInventoryKey,
	util.getSetting("Keybinds", "Inventory"),
	{ util.getSetting("Gamepad", "Inventory"), Enum.KeyCode.ButtonB },
	"Button"
)

Inventory.ToggleInventoryInput:SetPosition(UDim2.fromScale(0.75, -0.65))

globalInputService.AddToActionGroup("PlayerControl", Inventory.ToggleInventoryInput)
Inventory.statusPumpTimer.Function = pumpHealthStatus
RunService.Heartbeat:Connect(updatePlayerStatus)

return Inventory
