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
local inventory = require(client.Inventory)
local util = require(client.Util)
local acts = require(client.Acts)
local camera = require(client.Camera)
local globalInputService = require(client.GlobalInputService)
local sequences = require(client.Sequences)

local currentNpcModule
local currentNpc
local inMessage = false

local function clearOptions()
	for _, option in ipairs(UI.Box.Choices:GetChildren()) do
		if not option:IsA("Frame") then
			continue
		end

		option:Destroy()
	end
end

local function openGui()
	camera.followViewDistance.current = 2

	clearOptions()
	UI.Box.Message.Text = ""

	UI.Enabled = true
end

local function closeGui()
	camera.followViewDistance.current = camera.followViewDistance.default

	clearOptions()
	UI.Box.Message.Text = ""

	UI.Enabled = false
end

local function showDialogueOptions(options)
	for _, option in ipairs(options) do
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

	if globalInputService.inputType == "Gamepad" then
		GuiService:Select(UI.Box.Choices)
	end
end

local function getActionData(action: string)
	local str = string.split(action, ":")
	return str[1], string.split(str[2], ",")
end

local function doActions(actions)
	for _, action: string in ipairs(actions) do
		local actionIndex, parameters = getActionData(action)

		if actionIndex == "GiveObject" then
			inventory:AddItem(currentNpcModule.ObjectToGive)
		elseif actionIndex == "SetStart" then
			local path = string.split(parameters[1], ".")
			local container, index = path[1], path[2]

			if container == "Module" then
				container = currentNpcModule
			else
				container = currentNpcModule[container]
			end

			currentNpcModule.Dialogue.Start = container[index]
		elseif actionIndex == "BeginSequence" then
			local sequenceName = parameters[1]

			sequences:beginSequence(sequenceName, currentNpc)
		end
	end
end

local function endMessage(messageData)
	if messageData.Message then
		UI.Box.Message.Text = messageData.Message
	end

	if messageData["Actions"] then
		doActions(messageData.Actions)
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

	if messageData.Speaker == "Player" then
		UI.PlayerPortrait.Visible = true
		UI.Box.Speaker.Text = "Kaia"
	else
		UI.PlayerPortrait.Visible = false
	end

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
		--messageUi.Visible = false

		local waitTime = 0.025
		local textLength = string.len(message)
		local textStep = math.clamp(math.round(textLength * waitTime), 1, math.huge)
		--local loadTime = math.clamp(textLength / 400, 0.1, 0.5)

		--messageUi.Text = '<font transparency="0">' .. message .. '</font>'

		--task.wait(loadTime)

		messageUi.Visible = true

		for i = 1, textLength, textStep do
			messageUi.Text = string.sub(message, 0, i)

			if messageData.Speaker == "Player" then -- Play Voice
				util.PlaySound(sounds.PlayerVoice, script, 0.01)
				messageUi.TextColor3 = Color3.fromRGB(207, 142, 141)
			elseif messageData.Speaker == "System" then
				util.PlaySound(sounds.SystemVoice, script, 0.02)
				messageUi.TextColor3 = Color3.fromRGB(218, 133, 65)
			else
				util.PlaySound(currentNpc.Voice)
				messageUi.TextColor3 = Color3.fromRGB(255, 255, 255)
			end

			task.wait(waitTime)
		end

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

function Dialogue:EnterDialogue(model)
	local module = model:FindFirstChild("Data")
	if not module or acts:checkAct("InDialogue") then
		return
	end

	acts:createAct("InDialogue")
	currentNpcModule = require(module)
	currentNpc = model

	openGui()
	startDialogue(currentNpcModule.Dialogue.Start)

	repeat
		task.wait()
	until not acts:checkAct("InDialogue")
	closeGui()
end

return Dialogue
