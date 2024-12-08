local module = {
    INTERACT_DISTANCE = 4
}

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

local camera = workspace.CurrentCamera

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
local globalInputType = require(Client.GlobalInputType)

local interactTimer = timer:new("PlayerInteractionTimer", 0.5)
local rng = Random.new()

local function getMouseHit()
    local cursorLocation = player:GetAttribute("CursorLocation")

    local ray = camera:ViewportPointToRay(cursorLocation.X, cursorLocation.Y)
    local direction = ray.Direction * 600
    local endPoint = ray.Origin + direction
    local hit = CFrame.new(endPoint)

    local raycast = workspace:Raycast(ray.Origin, direction)
    
    if not raycast then
        return hit
    end

    return CFrame.new(raycast.Position), raycast.Instance
end

local function showInteract(object, cursor)
    cursor.Image.Position = UDim2.fromScale(0,0)
    cursor.CursorBlue.Image.Position = UDim2.fromScale(0,0)
    cursor.CursorRed.Image.Position = UDim2.fromScale(0,0)
    cursor.Visible = true

    cursor.ItemName.Text = object.Name
    cursor.ItemNameRed.Text = object.Name
    cursor.ItemNameBlue.Text = object.Name

    uiAnimationService.PlayAnimation(cursor, 0.025, false, true)
    uiAnimationService.PlayAnimation(cursor.CursorBlue, 0.025, false, true)
    uiAnimationService.PlayAnimation(cursor.CursorRed, 0.025, false, true).OnEnded:Once(function()
        cursor.ItemName.Visible = true
        cursor.ItemNameRed.Visible = true
        cursor.ItemNameBlue.Visible = true
    end)

    cursor.KeyPrompt.Visible = globalInputType.inputType == "Gamepad"
    cursor.KeyPrompt.Image = globalInputType.inputIcons[globalInputType.gamepadType].ButtonA

    cursor.Locked.Visible = object:GetAttribute("Locked")
end

local function showLocked(cursor : Frame)
    task.spawn(function()
        for i = 1,10 do
            cursor.Position = UDim2.fromScale(rng:NextNumber(-0.025, 0.025), rng:NextNumber(-0.025, 0.025))
            task.wait(0.025)
        end
    
        cursor.Position = UDim2.fromScale(0,0)
    end)
end

local function hideInteract(object, cursor)
    cursor.Visible = false
    cursor.Image.Position = UDim2.fromScale(0,0)
    cursor.CursorBlue.Image.Position = UDim2.fromScale(0,0)
    cursor.CursorRed.Image.Position = UDim2.fromScale(0,0)

    cursor.ItemName.Visible = false
    cursor.ItemNameRed.Visible = false
    cursor.ItemNameBlue.Visible = false

    interactTimer:Cancel()
end

mouseTarget.Changed:Connect(function(value)
    if not UI then
        return
    end

    local interactUi = UI.Cursor.Interact

    if value and value:HasTag("Interactable") then
        showInteract(value, interactUi)
    else
        hideInteract(value, interactUi)
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

    interactTimer:Run()
    actionPrompt.showActionTimer(interactTimer, actionName)
end

local function attemptOpenDoor(object : Instance)
    if object:GetAttribute("Locked") then
        util.PlaySound(sounds.Locked, script)
        showLocked(UI.Cursor.Interact)
    else
        util.PlaySound(sounds.Opening, script, 0.05, 0.5)
        runTimer("Opening", 0.5, openDoor, object)
    end
end

local function pickupContainer(object : Instance)
    util.PlaySound(sounds.Collecting, script, 0.05, 0.5)
    runTimer("Collecting", 0.5, function()
        inventory:pickupFromContainer(mouseTarget.Value)
    end)
end

local function InteractiWithObject(object : Instance)
    if object:HasTag("Container") then
        pickupContainer(object)
    end

    if object:HasTag("NPC") then
        dialogue:EnterDialogue(mouseTarget.Value)
    end

    if object:HasTag("Door") then
        attemptOpenDoor(object)
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    local object = mouseTarget.Value

    if 
        (input.KeyCode ~= Enum.KeyCode.F and input.KeyCode ~= Enum.KeyCode.ButtonA)
        or gameProcessedEvent 
        or not object 
        or acts:checkAct("Interacting")  
    then
        return
    end

    InteractiWithObject(object)
end)

local function processCrosshair()

    if not player.Character then
        mouseTarget.Value = nil
        return
    end

    local hit, target = getMouseHit()

    local distanceToMouse = (player.Character:GetPivot().Position - hit.Position).Magnitude
    
    if distanceToMouse > module.INTERACT_DISTANCE then
        mouseTarget.Value = nil
    else
        mouseTarget.Value = target and (target:FindFirstAncestorOfClass("Model") or target)
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