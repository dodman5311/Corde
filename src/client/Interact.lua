local module = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local mouse = player:GetMouse()

local mouseTarget = Instance.new("ObjectValue")
mouseTarget.Parent = player
mouseTarget.Name = "MouseTarget"

local assets = ReplicatedStorage.Assets
local sounds = assets.Sounds
local models = assets.Models

local UI

local Client = player.PlayerScripts.Client
local uiAnimationService = require(Client.UIAnimationService)
local inventory = require(Client.Inventory)
local dialogue = require(Client.Dialogue)
local acts = require(Client.Acts)
local actionPrompt = require(Client.ActionPrompt)
local timer = require(Client.Timer)
local weaponSystem = require(Client.WeaponSystem)
local util = require(Client.Util)

local interactTimer = timer:new("PlayerInteractionTimer", 0.5)

mouseTarget.Changed:Connect(function(value)
    local cursor = UI.Cursor
    if not UI then
        return
    end

    if value and value:HasTag("Interactable") then

        cursor.Image.Position = UDim2.fromScale(0,0)
        cursor.CursorBlue.Image.Position = UDim2.fromScale(0,0)
        cursor.CursorRed.Image.Position = UDim2.fromScale(0,0)
        cursor.Visible = true

        cursor.ItemName.Text = value.Name
        cursor.ItemNameRed.Text = value.Name
        cursor.ItemNameBlue.Text = value.Name

        uiAnimationService.PlayAnimation(cursor, 0.025, false, true)
        uiAnimationService.PlayAnimation(cursor.CursorBlue, 0.025, false, true)
        uiAnimationService.PlayAnimation(cursor.CursorRed, 0.025, false, true).OnEnded:Once(function()
            cursor.ItemName.Visible = true
            cursor.ItemNameRed.Visible = true
            cursor.ItemNameBlue.Visible = true
        end)

    else
        cursor.Visible = false
        cursor.Image.Position = UDim2.fromScale(0,0)
        cursor.CursorBlue.Image.Position = UDim2.fromScale(0,0)
        cursor.CursorRed.Image.Position = UDim2.fromScale(0,0)

        cursor.ItemName.Visible = false
        cursor.ItemNameRed.Visible = false
        cursor.ItemNameBlue.Visible = false

        interactTimer:Cancel()
    end
end)

local function openDoor(object)
    local doorModule = require(object.Module)

    if doorModule.open() then
        return
    end
end

local function runTimer(actionName : string, interactionTime : number, func, ...)
    interactTimer.Function = func
    interactTimer.Parameters = {...}
    interactTimer.WaitTime = interactionTime

    acts:createAct("Interacting")

    interactTimer:Run()
    actionPrompt.showActionTimer(interactTimer, actionName)
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    local object = mouseTarget.Value

    if input.KeyCode ~= Enum.KeyCode.F or gameProcessedEvent or not object or acts:checkAct("Interacting")  then
        return
    end

    if object:HasTag("Container") then
        util.PlaySound(sounds.Collecting, script, 0.05, 0.5)
        runTimer("Collecting", 0.5, function()
            inventory:pickupFromContainer(mouseTarget.Value)
        end)
    end

    if object:HasTag("NPC") then
        dialogue:EnterDialogue(mouseTarget.Value)
    end

    if object:HasTag("Door") then
        util.PlaySound(sounds.Opening, script, 0.05, 0.5)
        runTimer("Opening", 0.5, openDoor, object)
    end
end)

local function processCrosshair()

    if not player.Character then
        mouseTarget.Value = nil
        return
    end

    local distanceToMouse = (player.Character:GetPivot().Position - mouse.Hit.Position).Magnitude
    
    if distanceToMouse > 3 then
        mouseTarget.Value = nil
    else
        mouseTarget.Value = mouse.Target:FindFirstAncestorOfClass("Model") or mouse.Target
    end
end

function module.Init()
    UI = player.PlayerGui.HUD
    RunService.RenderStepped:Connect(processCrosshair)
end

interactTimer.OnEnded:Connect(function(state)
    acts:removeAct("Interacting")
end)

return module