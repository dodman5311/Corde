export type item = {
	Name: "string",
	Desc: "string",
	Value: any,
	Icon: "string",
	Use: "Eat" | "Read" | "EquipWeapon" | "Reload",
	InUse: boolean,
	CombineData: {},
	CanArchive: boolean?,
}

--// Services

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
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

local UITemplate = gui.Inventory
local UI
local currentSelectedSlot
local camera = workspace.CurrentCamera

--// Modules
local signal = require(ReplicatedStorage.Packages.Signal)
local UIAnimationService = require(client.UIAnimationService)
local util = require(client.Util)
local acts = require(client.Acts)
local mouseOver = require(client.MouseOver)
local cameraService = require(client.Camera)
local globalInputService = require(client.GlobalInputService)
local timer = require(client.Timer)
local itemsList = require(ReplicatedStorage.Shared.Items)

--// Values
local currentNoteIndex = 0
local currentNoteItem: item
local rng = Random.new()
local inAction = false
local holdingObject = {
	Action = "",
	Object = nil,
	Connection = nil,
}

Inventory.ItemRemoved = signal.new()
Inventory.ItemAdded = signal.new()
Inventory.SlotValueChanged = signal.new()
Inventory.ItemUsed = signal.new()
Inventory.InvetoryToggled = signal.new()

Inventory.statusPumpTimer = timer:new("HealthPump", 1)

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

function Inventory:CheckSlot(slot: string | number)
	if tonumber(slot) then
		slot = "slot_" .. slot
	end
	return self[slot]
end

function Inventory:GetFirstEmptySlot(): string -- returns slot index, (String)
	for slotIndex = 1, 12 do
		if self:CheckSlot("slot_" .. slotIndex) then
			continue
		end

		return "slot_" .. slotIndex
	end
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

	if slotToChangeTo == "slot_13" and typeof(item.Value) ~= "table" then
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

	return newItem
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

	for _, v in ipairs(containerData) do
		if not self:AddItem(v) then
			util.PlaySound(sounds.InventoryFull)
			break
		end
		table.insert(toRemove, v)
	end

	if #toRemove > 0 then
		util.PlaySound(sounds.ItemAdded, 0.05)
	end

	for _, v in ipairs(toRemove) do
		table.remove(containerData, table.find(containerData, v))
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

local function setUpSlots(isOpening)
	for _, slotUi in ipairs(UI.Inventory.Slots:GetChildren()) do
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
	local weapon: item = Inventory["slot_13"]

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
	local weapon: item? = Inventory["slot_13"]

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

	if globalInputService.inputType == "Gamepad" then
		GuiService:Select(UI.Inventory.Slots)
	end
end

local function clearKeyPrompts()
	for _, child in ipairs(UI.Note.Message:GetChildren()) do -- clear previous prompts
		if child.Name == "Keyprompt" then
			child:Destroy()
		end
	end
end

local function showNoteKeyprompts(note: item)
	if not note.Value.Message.KeyPrompts then
		return
	end

	for _, prompt in ipairs(note.Value.Message.KeyPrompts) do
		if prompt.Index ~= currentNoteIndex then
			continue
		end

		local newPrompt: ImageLabel = gui.Keyprompt:Clone()
		newPrompt.Image:AddTag("KeyPrompt")
		newPrompt.Image:SetAttribute("Key", prompt.Key)
		newPrompt.Image:SetAttribute("Button", prompt.Button)
		newPrompt.Parent = UI.Note.Message

		newPrompt.Image.Position = UDim2.fromScale(1, prompt.YPosition)
		newPrompt.Text = prompt.PreText
		newPrompt.TextSize = UI.Note.Message.TextSize
	end

	globalInputService:CheckKeyPrompts()
end

local function nextNotePage(note: item, indexChange: number)
	if not note then
		return
	end

	local noteUi = UI.Note
	currentNoteIndex = math.clamp(currentNoteIndex + indexChange, 0, #note.Value.Message + 1)
	util.PlaySound(sounds.Paper, 0.075)

	if currentNoteIndex > #note.Value.Message then
		closeNote()
		return
	elseif currentNoteIndex == #note.Value.Message then
		noteUi.Message.Page.Text = `<<  {currentNoteIndex} / {#note.Value.Message}    `
	elseif currentNoteIndex == 0 then
		noteUi.Message.Page.Text = `    {currentNoteIndex} / {#note.Value.Message}  >>`
	else
		noteUi.Message.Page.Text = `<<  {currentNoteIndex} / {#note.Value.Message}  >>`
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

	noteUi.Message.Text = note.Value.Message[currentNoteIndex]
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

	if globalInputService.inputType == "Gamepad" then
		GuiService.SelectedObject = nil
	end
end

local function hideDescription()
	local infoFrame = UI.Inventory.Info

	infoFrame.Visible = false
	UIAnimationService.StopAnimation(infoFrame.BackgroundImage)
	UI.Inventory.WeaponCompare.Visible = false
end

local function refreshGui(isOpening)
	setUpSlots(isOpening)
	setUpWeapon()
	UI.Inventory.WeaponCompare.Visible = false
end

local function emptyWeaponSlot()
	if acts:checkAct("Reloading") then
		return
	end

	util.PlayFrom(player.Character, sounds.Unequip)

	Inventory:ChangeSlot("slot_13", Inventory:GetFirstEmptySlot())
	refreshGui()
end

local function useItem(slotUi)
	if slotUi.Name == "Weapon" then
		emptyWeaponSlot()
		return
	end
	local item: item = Inventory[slotUi.Name]

	if not item or acts:checkAct("Reloading") then
		return
	end

	if item.Use == "EquipWeapon" then
		Inventory:ChangeSlot(slotUi.Name, "slot_13")
	elseif item.Use == "Read" then
		openNote(item)
	else
		Inventory.ItemUsed:Fire(item.Use, item, slotUi.Name)
	end

	task.delay(0.05, refreshGui)
end

local function createGuiSlots()
	for slotIndex = 2, 12 do
		local newSlot = UI.Inventory.Slots.slot_1:Clone()
		newSlot.Name = "slot_" .. slotIndex
		newSlot.Parent = UI.Inventory.Slots
	end
end

local function showFrameDescription(frame)
	local infoFrame = UI.Inventory.Info

	infoFrame.Visible = true
	infoFrame.BackgroundImage.Visible = false

	infoFrame.DescriptionIndex.Text = frame.Name
	infoFrame.Description.Text = frame:GetAttribute("Description")
end

local function showItemDesciption(item: item)
	if not item then
		return
	end
	local infoFrame = UI.Inventory.Info
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
	end

	showItemDesciption(item)
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
	holdingObject.Object = slotUi

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

local optionFunctions = {
	Use = function(slotUi)
		useItem(slotUi)
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
	local slotNumber = tonumber(string.sub(slotUi.Name, 6, -1))

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

	local button: TextButton = slotUi.Button

	button.MouseButton2Click:Connect(function()
		useItem(slotUi)
		closeOptionsMenu()
	end)

	button.MouseButton1Click:Connect(function()
		UIAnimationService.StopAnimation(UI.MoveObject)
		UI.MoveObject.Visible = false

		if holdingObject.Connection then
			holdingObject.Connection:Disconnect()
		end

		if not holdingObject.Object then
			openOptionsMenu(slotUi)

			return
		end

		if holdingObject.Action == "Move" then
			util.PlaySound(sounds.OptionClick).PlaybackSpeed = 0.8
			Inventory:ChangeSlot(holdingObject.Object.Name, slotUi.Name)
		elseif holdingObject.Action == "Combine" then
			if Inventory:CombineSlots(holdingObject.Object.Name, slotUi.Name) then
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
			useItem(slotUi)
		end

		refreshGui()
	end)
end

local function initGui()
	UI = UITemplate
	UI.Parent = player.PlayerGui
	UI.Enabled = false

	createGuiSlots()

	-- set up note
	UI.Note.GroupTransparency = 1

	local nextButton: TextButton = UI.Note.Next
	local prevButton: TextButton = UI.Note.Prev
	local exitButton: TextButton = UI.Note.Exit
	local weaponDisplay = UI.Inventory.Weapon.WeaponDisplay

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
		showItemDesciption(Inventory:CheckSlot(13))
	end)

	weaponDisplay.MouseLeave:Connect(hideDescription)

	weaponDisplay.SelectionGained:Connect(function()
		util.PlaySound(sounds.InventoryHover)
		task.wait(0.05)
		showItemDesciption(Inventory:CheckSlot(13))
	end)

	weaponDisplay.SelectionLost:Connect(hideDescription)

	for _, frame: Frame in ipairs(CollectionService:GetTagged("DescriptionFrame")) do
		local mouseEnter, mouseLeave = mouseOver.MouseEnterLeaveEvent(frame)

		mouseEnter:Connect(function()
			showFrameDescription(frame)
		end)

		mouseLeave:Connect(hideDescription)
	end

	for _, slotUi in ipairs(UI.Inventory.Slots:GetChildren()) do
		connectSlotButton(slotUi)
	end
end

function Inventory.OpenInventory()
	Inventory.InvetoryToggled:Fire(true)

	globalInputService.inputs["N.E.T"]:Disable()
	globalInputService.inputs["Ready Weapon"]:Disable()
	globalInputService.inputs.Interact:Disable()

	Inventory.InventoryInteract:Enable()

	if not acts:checkAct("InDialogue") then
		cameraService.followViewDistance.current = 1
	end

	util.PlaySound(sounds.InventoryOpen)
	sounds.InventoryAmbience:Play()

	acts:createAct("InventoryOpening")
	Inventory.InventoryOpen = true

	local ti = TweenInfo.new(0.25)
	local ti_0 = TweenInfo.new(0.75, Enum.EasingStyle.Quint)

	refreshGui(true)

	UI.Inventory.Size = UDim2.fromScale(0.925, 0.925)
	UI.Inventory.Visible = false
	UI.Enabled = true

	util.tween(Lighting.InventoryBlur, ti, { Size = 18 })

	--task.wait(0.2)
	util.tween(UI.Inventory, ti_0, { Size = UDim2.fromScale(0.975, 0.975) })
	util.flickerUi(UI.Inventory, 0.01, 6)

	acts:removeAct("InventoryOpening")

	if globalInputService.inputType == "Gamepad" then
		GuiService:Select(UI.Inventory.Slots)
	end
end

function Inventory.CloseInventory()
	globalInputService.inputs["N.E.T"]:Enable()
	globalInputService.inputs["Ready Weapon"]:Enable()
	globalInputService.inputs.Interact:Enable()

	Inventory.InventoryInteract:Disable()
	closeNote()

	if not acts:checkAct("InDialogue") then
		cameraService.followViewDistance.current = cameraService.followViewDistance.default
	end

	util.PlaySound(sounds.InventoryClose)
	sounds.InventoryAmbience:Stop()

	local ti = TweenInfo.new(0.5)

	util.flickerUi(UI.Inventory, 0.01, 6)

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
		useItem(GuiService.SelectedObject.Parent)
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

function Inventory.StartGame()
	Inventory.ToggleInventoryInput:Enable()
end

function Inventory.Init()
	Inventory.noteNavigation = globalInputService.CreateNewInput(
		"NoteNavigation",
		noteNavigationInput,
		{ Enum.KeyCode.Down, Enum.KeyCode.Up, Enum.KeyCode.Left, Enum.KeyCode.Right },
		{ Enum.KeyCode.DPadDown, Enum.KeyCode.DPadUp, Enum.KeyCode.DPadLeft, Enum.KeyCode.DPadRight }
	)
	Inventory.InventoryInteract =
		globalInputService.CreateNewInput("InventoryInteraction", inventoryInteract, Enum.KeyCode.ButtonX)

	Inventory.ToggleInventoryInput = globalInputService.CreateNewInput(
		"Inventory",
		toggleInventoryKey,
		util.getSetting("Keybinds", "Inventory"),
		{ util.getSetting("Gamepad", "Inventory"), Enum.KeyCode.ButtonB }
	)

	Inventory.InventoryInteract:Disable()
	Inventory.noteNavigation:Disable()
	Inventory.ToggleInventoryInput:Disable()

	initGui()
end

--// Main //--
Inventory.statusPumpTimer.Function = pumpHealthStatus
RunService.Heartbeat:Connect(updatePlayerStatus)

return Inventory
