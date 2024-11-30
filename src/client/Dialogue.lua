local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Dialogue = {}

local player = Players.LocalPlayer

local UI = ReplicatedStorage.Dialogue
UI.Parent = player.PlayerGui
UI.Enabled = false

local client = script.Parent
local inventory = require(client.Inventory)
local util = require(client.Util)
local acts = require(client.Acts)

local currentNpcModule
local currentNpc
local inMessage = false

local function clearOptions()
    for _,option in ipairs(UI.Box.Choices:GetChildren()) do
        if not option:IsA("Frame") then
            continue
        end

        option:Destroy()
    end
end

local function openGui()
    
    clearOptions()
    UI.Box.Message.Text = ""

    UI.Enabled = true
end

local function closeGui()
    
    clearOptions()
    UI.Box.Message.Text = ""

    UI.Enabled = false
end

local function showDialogueOptions(options)
    for _,option in ipairs(options) do
        local dialogueOption = UI.Option:Clone()
        local button:TextButton = dialogueOption.ButtonFrame.Button

        dialogueOption.Visible = true
        button.Text = option
        dialogueOption.Parent = UI.Box.Choices

        button.MouseButton1Click:Once(function()
            clearOptions()
            startDialogue(currentNpcModule.Dialogue[option])
        end)
    end
end

local function doActions(actions)
    for _,action in ipairs(actions) do
        if action == "GiveObject" then
            inventory:AddItem(currentNpcModule.ObjectToGive)
        end
    end
end

local function endMessage(messageData, dialogue)
    UI.Box.Message.Text = messageData.Message
    
    if messageData['Actions'] then
        doActions(messageData.Actions)
    end
end

function typeOutMessage(messageData, dialogue)
    inMessage = true

    local inputEvent
    local typeThread
    local messageUi = UI.Box.Message
    local texting = true
    local clickCooldown = false

    if messageData.Speaker == "Player" then
        UI.PlayerPortrait.Visible = true
    else
        UI.PlayerPortrait.Visible = false
    end

    inputEvent = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 or clickCooldown then return end

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

        local textLength = string.len(message)
		local loadTime = math.clamp(textLength / 400, 0.1, 0.5)

		messageUi.Visible = false
        messageUi.Text = '<font transparency="0">' .. message .. '</font>'

		task.wait(loadTime)

        messageUi.Visible = true

        for i = 1, string.len(messageData.Message) do
            messageUi.Text = string.sub(messageData.Message, 0, i)

            if messageData.Speaker == "Player" then -- Play Voice
                util.PlaySound(ReplicatedStorage.PlayerVoice, script, 0.01)
                messageUi.TextColor3 = Color3.fromRGB(207, 142, 141)
            elseif messageData.Speaker == "System" then
                util.PlaySound(ReplicatedStorage.SystemVoice, script, 0.02)
                messageUi.TextColor3 = Color3.fromRGB(218, 133, 65)
            else
                util.PlaySound(currentNpc.Voice, script)
                messageUi.TextColor3 = Color3.fromRGB(255, 255, 255)
            end

            task.wait(0.02)
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
    for _,message in ipairs(dialogue) do
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

function Dialogue:EnterDialogue(npc)
    local module = npc:FindFirstChild("Data")
    if not module or acts:checkAct("InDialogue") then
        return
    end

    acts:createAct("InDialogue")
    currentNpcModule = require(module)
    currentNpc = npc

    openGui()
    startDialogue(currentNpcModule.Dialogue[npc:GetAttribute("InitialDialogue")])

    repeat
        task.wait()
    until not acts:checkAct("InDialogue")
    closeGui()
end

return Dialogue