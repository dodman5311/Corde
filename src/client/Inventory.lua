export type item = {
	Name: "string",
	Desc: "string",
	Value: any,
	Icon: "string",
	Use: "Eat" | "Read" | "EquipWeapon" | "Reload",
	InUse: boolean,
}

local Debris = game:GetService("Debris")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Inventory = {
	InventoryOpen = false,
} -- {Name = "", Desc = "", Value = 1, InUse = false, Use = "Action"}

local player = Players.LocalPlayer

local client = script.Parent
local signal = require(ReplicatedStorage.Packages.Signal)
local UIAnimationService = require(client.UIAnimationService)
local util = require(client.Util)
local acts = require(client.Acts)
local mouseOver = require(client.MouseOver)
local camera = require(client.Camera)
local globalInputService = require(client.GlobalInputService)
local hacking = require(client.Hacking)
local timer = require(client.Timer)

local assets = ReplicatedStorage.Assets
local models = assets.Models
local gui = assets.Gui
local sounds = assets.Sounds

local currentNoteIndex = 0
local currentNoteItem: item

Inventory.ItemRemoved = signal.new()
Inventory.ItemAdded = signal.new()
Inventory.ItemAddedToSlot = signal.new()
Inventory.ItemUsed = signal.new()
Inventory.InvetoryToggled = signal.new()

Inventory.statusPumpTimer = timer:new("HealthPump", 1)

local rng = Random.new()

local UITemplate = gui.Inventory
local UI

function Inventory:ShowNotification(itemName, notificationMessage)
	local newNotification = gui.Notification:Clone()
	newNotification.Parent = player.PlayerGui.HUD.Notifications

	newNotification.Text = itemName .. " " .. notificationMessage
	Debris:AddItem(newNotification, 6)

	local ti = TweenInfo.new(3, Enum.EasingStyle.Quart, Enum.EasingDirection.In, 0, false, 3)
	util.tween(newNotification, ti, { TextTransparency = 1 })
end

function Inventory:SearchForItem(itemName)
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

function Inventory:CheckSlot(slot)
	return self[slot]
end

function Inventory:ChangeSlot(slot, slotToChangeTo)
	local item: item = self[slot]
	if not item then
		return
	end

	if slotToChangeTo == "slot_13" and typeof(item.Value) ~= "table" then
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

function Inventory:AddItem(item: item)
	local newItem = table.clone(item)

	for i = 1, 12 do
		if self["slot_" .. i] then
			continue
		end

		self:ShowNotification(item.Name, "Added to inventory")

		self["slot_" .. i] = newItem
		self.ItemAdded:Fire(newItem, "slot_" .. i)
		self.ItemAddedToSlot:Fire("slot_" .. i, newItem)

		return true
	end
end

function Inventory:AddWeapon(item: item)
	if not item then
		return
	end

	if self.slot_13 then
		self:DropItem(self.slot_13.Name)
	end

	self.slot_13 = item
	self.ItemAdded:Fire(item, "slot_13")
	self.ItemAddedToSlot:Fire("slot_13")

	return true
end

function Inventory:RemoveItem(ItemOrSlot)
	local item: item, slot

	if Inventory[ItemOrSlot] then
		item = Inventory[ItemOrSlot]
		slot = ItemOrSlot
	else
		item, slot = self:SearchForItem(ItemOrSlot)
	end

	if not item then
		return
	end

	self:ShowNotification(item.Name, "Removed from inventory")
	self.ItemRemoved:Fire(item, slot)
	self[slot] = nil

	return item, slot
end

function Inventory:DropItem(ItemOrSlot)
	if not ItemOrSlot then
		return
	end

	local item: item = self:RemoveItem(ItemOrSlot)

	if not item then
		return
	end

	local droppedItem = models.DroppedItem:Clone()
	local character = player.Character

	local data = require(droppedItem.Container)

	table.insert(data, item)

	droppedItem.Parent = workspace
	droppedItem.Name = item.Name
	droppedItem.CFrame = character:GetPivot()
	droppedItem.AssemblyLinearVelocity = (character:GetPivot() * CFrame.Angles(0, math.rad(rng:NextNumber(-20, 20)), 0)).LookVector
		* rng:NextNumber(10, 20)
end

function Inventory:pickupFromContainer(object)
	if not object or not object:FindFirstChild("Container") then
		return
	end

	util.PlaySound(sounds.ItemAdded, script, 0.05)

	local containerData = require(object.Container)

	local toRemove = {}

	for _, v in ipairs(containerData) do
		if not self:AddItem(v) then
			break
		end

		table.insert(toRemove, v)
	end

	for _, v in ipairs(toRemove) do
		table.remove(containerData, table.find(containerData, v))
	end

	if object:GetAttribute("RemoveOnEmpty") and #containerData == 0 then
		object:Destroy()
	end
end

local function setUpSlots()
	for _, slotUi in ipairs(UI.Inventory.Slots:GetChildren()) do
		if not slotUi:IsA("Frame") then
			continue
		end

		local item: item = Inventory[slotUi.Name]

		if item then
			slotUi.Frame.Image.Image = item.Icon
			slotUi.ItemName.Text = item.Name

			slotUi.Value.Text = typeof(item.Value) == "number" and item.Value or ""

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

	damage.Bar.Size = UDim2.fromScale(baseWeaponData.Damage * baseWeaponData.BulletCount / 100, 1)
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

local function nextNotePage(note: item, indexChange: number)
	if not note then
		return
	end

	local noteUi = UI.Note
	currentNoteIndex = math.clamp(currentNoteIndex + indexChange, 0, #note.Value.Message + 1)
	util.PlaySound(sounds.Paper, script, 0.075)

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
end

local function openNote(note: item)
	Inventory.noteNavigation:Enable()
	currentNoteItem = note

	local noteUi = UI.Note
	noteUi.Visible = true

	noteUi.NoteImage.ImageColor3 = Color3.new(1, 1, 1)
	noteUi.NoteImage.Image = note.Value.Image

	currentNoteIndex = 0
	nextNotePage(note, 0)

	util.tween(UI.Note, TweenInfo.new(0.5, Enum.EasingStyle.Linear), { GroupTransparency = 0 })

	if globalInputService.inputType == "Gamepad" then
		GuiService.SelectedObject = nil
	end
end

local function refreshGui()
	setUpSlots()
	setUpWeapon()
	UI.Inventory.WeaponCompare.Visible = false
end

local function useItem(slotUi)
	local item: item = Inventory[slotUi.Name]

	if (not item) or item.InUse or acts:checkAct("Reloading") then
		return
	end

	if item.Use == "EquipWeapon" then
		Inventory:ChangeSlot(slotUi.Name, "slot_13")
	elseif item.Use == "Read" then
		openNote(item)
	else
		Inventory.ItemUsed:Fire(item.Use, item, slotUi.Name)
	end

	task.wait()
	refreshGui()
end

local function updatePrompts()
	local inventoryUi = UI.Inventory
	local note = UI.Note

	inventoryUi.ActionPrompt.Visible = globalInputService.inputType == "Keyboard"
	inventoryUi.ActionPromptGamepad.Visible = globalInputService.inputType == "Gamepad"
	note.ActionPromptGamepad.Visible = globalInputService.inputType == "Gamepad"
end

local function initGui()
	local step
	local originalSlot

	UI = UITemplate:Clone()
	UI.Parent = player.PlayerGui
	UI.Enabled = false

	UI.Note.GroupTransparency = 1

	local nextButton: TextButton = UI.Note.Next
	local prevButton: TextButton = UI.Note.Prev
	local exitButton: TextButton = UI.Note.Exit

	nextButton.MouseButton1Click:Connect(function()
		nextNotePage(currentNoteItem, 1)
	end)

	prevButton.MouseButton1Click:Connect(function()
		nextNotePage(currentNoteItem, -1)
	end)

	exitButton.MouseButton1Click:Connect(function()
		closeNote()
	end)

	for _, slotUi in ipairs(UI.Inventory.Slots:GetChildren()) do
		if not slotUi:IsA("Frame") then
			continue
		end

		local mouseEnter, mouseLeave = mouseOver.MouseEnterLeaveEvent(slotUi.Button)

		mouseEnter:Connect(function()
			UIAnimationService.PlayAnimation(slotUi.Frame, 0.1, true)

			local item: item = Inventory[slotUi.Name]

			if not item then
				return
			end

			UI.Inventory.Description.Text = item.Desc

			if item.Use == "EquipWeapon" then
				UI.Inventory.WeaponCompare.Visible = true
				compareWeapon(item)
			end
		end)

		mouseLeave:Connect(function()
			UIAnimationService.StopAnimation(slotUi.Frame)
			UI.Inventory.Description.Text = ""
			UI.Inventory.WeaponCompare.Visible = false
		end)

		local button: TextButton = slotUi.Button

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

				if UI.Enabled then
					return
				end

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
				Inventory:DropItem(slotUi.ItemName.Text)
			end

			if input.KeyCode == Enum.KeyCode.Return then
				useItem(slotUi)
			end

			refreshGui()
		end)
	end
end

function Inventory.OpenInventory()
	Inventory.InvetoryToggled:Fire(true)

	hacking:ExitNetMode()
	hacking.ToggleNetInput:Disable()
	globalInputService.inputs.ToggleReady:Disable()

	Inventory.InventoryInteract:Enable()

	camera.followViewDistance.current = 1

	acts:createAct("InventoryOpening")
	Inventory.InventoryOpen = true

	local ti = TweenInfo.new(0.25)

	refreshGui()

	UI.SideBars.Image.Position = UDim2.fromScale(0, 0)
	UI.Inventory.Visible = false
	UI.SideBars.Visible = true
	UI.Enabled = true

	util.tween(Lighting.InventoryBlur, ti, { Size = 18 })
	UIAnimationService.PlayAnimation(UI.SideBars, 0.025, false, true)

	task.wait(0.2)
	util.flickerUi(UI.Inventory, 0.01, 6)
	acts:removeAct("InventoryOpening")

	if globalInputService.inputType == "Gamepad" then
		GuiService:Select(UI.Inventory.Slots)
	end
end

function Inventory.CloseInventory()
	Inventory.InvetoryToggled:Fire(false)

	hacking.ToggleNetInput:Enable()
	globalInputService.inputs.ToggleReady:Enable()

	Inventory.InventoryInteract:Disable()
	closeNote()

	camera.followViewDistance.current = camera.followViewDistance.default

	local ti = TweenInfo.new(0.5)

	util.flickerUi(UI.SideBars, 0.01, 6, true)
	util.flickerUi(UI.Inventory, 0.01, 6)

	util.tween(Lighting.InventoryBlur, ti, { Size = 0 })

	UI.Enabled = false

	Inventory.InventoryOpen = false
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

local function toggleInventoryKey(state)
	if state ~= Enum.UserInputState.Begin or acts:checkAct("InventoryOpening") then
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
	end

	if input.KeyCode == Enum.KeyCode.ButtonX then
		useItem(GuiService.SelectedObject.Parent)
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
end

function Inventory.Init()
	Inventory.noteNavigation = globalInputService.CreateNewInput(
		"NoteNavigation",
		noteNavigationInput,
		Enum.KeyCode.DPadDown,
		Enum.KeyCode.DPadUp,
		Enum.KeyCode.DPadLeft,
		Enum.KeyCode.DPadRight
	)
	Inventory.InventoryInteract = globalInputService.CreateNewInput(
		"InventoryInteraction",
		inventoryInteract,
		Enum.KeyCode.ButtonB,
		Enum.KeyCode.ButtonX
	)

	Inventory.InventoryInteract:Disable()
	Inventory.noteNavigation:Disable()

	globalInputService.CreateNewInput("ToggleInventory", toggleInventoryKey, Enum.KeyCode.E, Enum.KeyCode.ButtonY)
	initGui()
end

Inventory.statusPumpTimer.Function = pumpHealthStatus
UserInputService.InputBegan:Connect(updatePrompts)
RunService.Heartbeat:Connect(updatePlayerStatus)

return Inventory
