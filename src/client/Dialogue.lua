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

local function doActions(actions)
	for _, action in ipairs(actions) do
		print(action, actions)

		if action == "GiveObject" then
			inventory:AddItem(currentNpcModule.ObjectToGive)
		end

		if string.match(action, "SetStart_") then
			local str = string.split(string.sub(action, 10), ".")
			local container, index = str[1], str[2]

			if container == "Module" then
				container = currentNpcModule
			else
				container = currentNpcModule[container]
			end

			currentNpcModule.Dialogue.Start = container[index]
		end
	end
end

local function endMessage(messageData)
	UI.Box.Message.Text = messageData.Message

	if messageData["Actions"] then
		doActions(messageData.Actions)
	end
end

function typeOutMessage(messageData, dialogue)
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
			endMessage(messageData, dialogue)
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
				util.PlaySound(currentNpc.Voice, script)
				messageUi.TextColor3 = Color3.fromRGB(255, 255, 255)
			end

			task.wait(waitTime)
		end

		texting = false

		endMessage(messageData, dialogue)

		clickCooldown = true
		task.delay(0.1, function()
			clickCooldown = false
		end)
	end)
end

function startDialogue(dialogue)
	for _, message in ipairs(dialogue) do
		typeOutMessage(message, dialogue)
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
