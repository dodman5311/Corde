local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Dialogue = {}

local player = Players.LocalPlayer

local assets = ReplicatedStorage.Assets
local sounds = assets.Sounds
local gui = assets.Gui

local UI = gui.Dialogue
UI.Parent = player.PlayerGui
UI.Enabled = false

local client = script.Parent
local acts = require(client.Acts)
local camera = require(client.Camera)
local globalInputService = require(client.GlobalInputService)
local inventory = require(client.Inventory)
local items = require(ReplicatedStorage.Shared.Items)
local sequences = require(client.Sequences)
local signal = require(ReplicatedStorage.Packages.Signal)
local storedData = require(ReplicatedStorage.Shared.StoredData)
local util = require(client.Util)

local currentNpcModule
local currentNpc
local inMessage = false
local rng = Random.new()

Dialogue.DialogueActionSignal = signal.new()

local portraits = {
	Player = 94100968201136,
	Echo = 102753832810768,
}

local function clearOptions()
	for _, option in ipairs(UI.Box.Choices:GetChildren()) do
		if not option:IsA("Frame") then
			continue
		end

		option:Destroy()
	end
end

local function clearMessageBox()
	for _, frame in ipairs(UI.Box.Message:GetChildren()) do
		if not frame:IsA("Frame") then
			continue
		end

		frame:Destroy()
	end
end

local function openGui()
	if not inventory.InventoryOpen then
		camera.followViewDistance.current = 2
	end

	clearOptions()
	clearMessageBox()

	UI.Enabled = true
end

local function closeGui()
	if not inventory.InventoryOpen then
		camera.followViewDistance.current = camera.followViewDistance.default
	end

	clearOptions()
	clearMessageBox()

	UI.Enabled = false
end

local actionsFunctions = {
	GiveObject = function()
		inventory:AddItem(currentNpcModule.ObjectToGive)
	end,

	PlaySound = function(parameters)
		util.PlaySound(sounds[parameters[1]])
	end,

	RemoveItem = function(parameters)
		return inventory:RemoveItem(parameters[1])
	end,

	AddItem = function(parameters)
		inventory:AddItem(items[parameters[1]])
	end,

	DisableInteract = function()
		if not currentNpc then
			return
		end

		currentNpc:RemoveTag("Interactable")
	end,

	CheckForItem = function(parameters)
		return inventory:SearchForItem(parameters[1])
	end,

	HasNet = function()
		return player.Character and player.Character:GetAttribute("HasNet")
	end,

	SetStart = function(parameters)
		local path = string.split(parameters[1], ".")
		local container, index = path[1], path[2]

		if container == "Module" then
			container = currentNpcModule
		else
			container = currentNpcModule[container]
		end

		currentNpcModule.Dialogue.Start = container[index]
	end,

	BeginSequence = function(parameters)
		sequences:beginSequence(parameters[1], currentNpc)
	end,

	FireEvent = function(parameters)
		Dialogue.DialogueActionSignal:Fire(table.unpack(parameters))
	end,
}

local function doAction(action: string)
	local str = string.split(action, ":")
	local actionIndex = str[1]
	local parameters = string.split(str[2], ",")

	if not actionsFunctions[actionIndex] then
		return
	end

	return actionsFunctions[actionIndex](parameters)
end

local function checkForCondition(option)
	if typeof(option) ~= "table" then
		return option
	end

	return doAction(option[1]) and option[2]
end

local function showDialogueOptions(options)
	for _, option in ipairs(options) do
		option = checkForCondition(option)
		if not option then
			continue
		end

		local dialogueOption = UI.Option:Clone()
		local button: TextButton = dialogueOption.ButtonFrame.Button

		dialogueOption.Visible = true

		button.Text = option
		dialogueOption.Parent = UI.Box.Choices

		button.MouseButton1Click:Once(function()
			clearOptions()
			startDialogue(currentNpcModule.Dialogue[option])
		end)
	end

	globalInputService:SelectGui(UI.Box.Choices)
end

local function doActions(actions)
	for _, action: string in ipairs(actions) do
		doAction(action)
	end
end

local letterEffects = {
	TweenDown = {
		Function = function(letterFrame: Frame, tweenInfo: TweenInfo)
			letterFrame.Letter.Position = UDim2.fromScale(0, -1)
			util.tween(letterFrame.Letter, tweenInfo, { Position = UDim2.fromScale(0, 0) })
		end,
	},

	FadeIn = {
		Function = function(letterFrame: Frame, tweenInfo: TweenInfo)
			letterFrame.Letter.TextTransparency = 1
			util.tween(letterFrame.Letter, tweenInfo, { TextTransparency = 0 })
		end,
	},

	Bold = {
		Function = function(letterFrame: Frame)
			local letter: TextLabel = letterFrame.Letter
			letter.Text = `<b>{letter.Text}</b>`
		end,
		Prefix = "*",
	},

	Color = {
		Function = function(letterFrame: Frame, color: Color3)
			letterFrame.Letter.TextColor3 = color
		end,
	},

	PlaySound = {
		Function = function(_, sounds: Sound)
			util.PlaySound(sounds, 0.01)
		end,
	},

	Shake = {
		Function = function(letterFrame: Frame, magnitude: number?, lerpTime: number?)
			magnitude = magnitude or 0.1
			lerpTime = lerpTime or 0.025
			local ti = TweenInfo.new(lerpTime, Enum.EasingStyle.Quad)

			local goal = UDim2.fromScale(rng:NextNumber(-magnitude, magnitude), rng:NextNumber(-magnitude, magnitude))

			task.spawn(function()
				repeat
					util.tween(letterFrame.Letter, ti, { Position = goal }, true)
					goal = UDim2.fromScale(rng:NextNumber(-magnitude, magnitude), rng:NextNumber(-magnitude, magnitude))
				until not letterFrame.Parent
			end)
		end,
		Prefix = "#",
	},
}

local function addLetterToWord(letter: string, wordFrame: Frame, effects: {}?)
	local newLetter = gui.LetterFrame:Clone() --util.callFromCache(gui.LetterFrame)
	newLetter.Parent = wordFrame
	newLetter.Letter.Text = letter

	if not effects then
		return
	end

	for effect, params in pairs(effects) do
		letterEffects[effect].Function(newLetter, table.unpack(params))
	end

	return newLetter
end

local function addWordToMessage(messageFrame: Frame)
	local newWordFrame = gui.WordFrame:Clone() --util.callFromCache(gui.WordFrame)
	newWordFrame.Parent = messageFrame
	return newWordFrame
end

local function addPrefixEffects(effects, prefix, ...)
	local addedValue = false
	for effect, value in pairs(letterEffects) do
		if not value.Prefix then
			continue
		end

		if value.Prefix == prefix then
			addedValue = true
			effects[effect] = { ... }
		end
	end

	return addedValue
end

local function writeToDynamicBox(message: string, messageFrame: Frame, doWait: boolean?, effects: {}?)
	local waitTime = 0.025
	local words = string.split(message, " ")

	clearMessageBox()

	for _, word in ipairs(words) do
		local wordFrame: Frame = addWordToMessage(messageFrame)
		local wordEffects = effects and table.clone(effects) or {}

		for i = 1, string.len(word) do
			local letter = string.sub(word, i, i)

			if addPrefixEffects(wordEffects, letter) then
				continue
			end

			addLetterToWord(letter, wordFrame, wordEffects)

			if doWait then
				task.wait(waitTime)
			end
		end

		addLetterToWord(" ", wordFrame)
	end
end

local function getMessageVisuals(messageData)
	local sound
	local color
	if messageData.Speaker == "Player" then -- Play Voice
		sound = sounds.PlayerVoice
		color = Color3.fromRGB(207, 142, 141)
	elseif messageData.Speaker == "System" then
		sound = sounds.SystemVoice
		color = Color3.fromRGB(218, 133, 65)
	else
		sound = currentNpc.Voice
		color = Color3.fromRGB(255, 255, 255)
	end

	return color, sound
end

local function endMessage(messageData)
	if messageData.Message then
		local color = getMessageVisuals(messageData)
		writeToDynamicBox(messageData.Message, UI.Box.Message, false, { Color = { color } })
	end

	if messageData["Actions"] then
		doActions(messageData.Actions)
	end
end

local function processSpeakerPortrait(messageData)
	if portraits[messageData.Speaker] then
		UI.Portrait.Visible = true
		UI.Portrait.Image = "rbxassetid://" .. portraits[messageData.Speaker]
	else
		UI.Portrait.Visible = false
	end

	if messageData.Speaker == "Player" then
		UI.Box.Speaker.Text = "Kaia"
	end
end

function typeOutMessage(messageData)
	inMessage = true

	local inputEvent
	local typeThread
	local messageUi = UI.Box.Message
	local texting = true

	local clickCooldown = true
	task.delay(0.1, function()
		clickCooldown = false
	end)

	UI.Box.Speaker.Text = messageData.Speaker

	processSpeakerPortrait(messageData)

	inputEvent = UserInputService.InputBegan:Connect(function(input)
		if
			(
				input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.KeyCode ~= Enum.KeyCode.F
				and input.KeyCode ~= Enum.KeyCode.ButtonA
				and input.KeyCode ~= Enum.KeyCode.ButtonX
			) or clickCooldown
		then
			return
		end

		clickCooldown = true
		task.delay(0.1, function()
			clickCooldown = false
		end)

		if texting then
			task.cancel(typeThread)
			texting = false
			endMessage(messageData)
			return
		end

		inMessage = false
		inputEvent:Disconnect()
	end)

	typeThread = task.spawn(function()
		local message = messageData.Message

		messageUi.Visible = true
		local color, sound = getMessageVisuals(messageData)

		writeToDynamicBox(message, messageUi, true, {
			TweenDown = { TweenInfo.new(0.1, Enum.EasingStyle.Quart) },
			FadeIn = { TweenInfo.new(0.1, Enum.EasingStyle.Quart) },
			PlaySound = { sound },
			Color = { color },
		})

		texting = false

		endMessage(messageData)

		clickCooldown = true
		task.delay(0.1, function()
			clickCooldown = false
		end)
	end)
end

function startDialogue(dialogue)
	if not dialogue then
		acts:removeAct("InDialogue")
		return
	end

	for _, messageData in ipairs(dialogue) do
		if messageData.Condition and not doAction(messageData.Condition) then
			continue
		end

		if not messageData.Message then
			endMessage(messageData)
			continue
		end

		typeOutMessage(messageData)
		repeat
			task.wait()
		until not inMessage
	end

	if dialogue["Options"] then
		showDialogueOptions(dialogue.Options)
	else
		acts:removeAct("InDialogue")
	end
end

function Dialogue:EnterDialogue(model: Instance)
	if acts:checkAct("InDialogue") then
		return
	end

	local module

	if model:FindFirstChild("Data") then
		module = require(model.Data)
	elseif model:GetAttribute("Data") then
		module = storedData:GetData(model:GetAttribute("Data"))
	end

	if not module then
		return
	end

	currentNpcModule = module
	currentNpc = model

	acts:createAct("InDialogue")

	openGui()
	startDialogue(currentNpcModule.Dialogue.Start)

	repeat
		task.wait()
	until not acts:checkAct("InDialogue")
	closeGui()
end

function Dialogue:EnterPlayerMonologue(dialogueModule: {})
	local character = player.Character
	if not character then
		return
	end

	local data = require(character.Data)
	data.Dialogue = dialogueModule
	data.Start = dialogueModule

	self:EnterDialogue(character)
end

function Dialogue:SayFromPlayer(message: string)
	self:EnterPlayerMonologue {
		Start = {
			{ Speaker = "Player", Message = message },
		},
	}
end

return Dialogue
