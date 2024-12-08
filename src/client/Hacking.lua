local module = {}

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local mouseTarget = Instance.new("ObjectValue")
mouseTarget.Parent = player
mouseTarget.Name = "MouseTarget"

local assets = ReplicatedStorage.Assets
local sounds = assets.Sounds.NET
local models = assets.Models
local gui = assets.Gui

local camera = workspace.CurrentCamera
local currentActivePoint = Instance.new("ObjectValue")
local lastActivePoint

local UI = gui.NET
UI.Parent = player.PlayerGui

local Client = player.PlayerScripts.Client
local uiAnimationService = require(Client.UIAnimationService)
local acts = require(Client.Acts)
local actionPrompt = require(Client.ActionPrompt)
local util = require(Client.Util)
local hackingFunctions = require(Client.HackingFunctions)
local globalInputType = require(Client.GlobalInputType)

local ti = TweenInfo.new(0.25)

local currentInputIndex = 1

local function getKeyCodeFromNumber(number : number | string)
    if tonumber(number) == 1 then
        return globalInputType.inputType ~= "Gamepad" and Enum.KeyCode.One or Enum.KeyCode.DPadUp
    elseif tonumber(number) == 2 then
        return globalInputType.inputType ~= "Gamepad" and Enum.KeyCode.Two or Enum.KeyCode.DPadLeft
    elseif tonumber(number) == 3 then
        return globalInputType.inputType ~= "Gamepad" and Enum.KeyCode.Three or Enum.KeyCode.DPadDown
    elseif tonumber(number) == 4 then
        return globalInputType.inputType ~= "Gamepad" and Enum.KeyCode.Four or Enum.KeyCode.DPadRight
    end
end

local function completePoint(point : BillboardGui)
    local hackUi = point.HackPrompt
    local ti = TweenInfo.new(0.5, Enum.EasingStyle.Quart)

    point:RemoveTag("ActiveNetPoint")
    hackUi.Visible = true

    util.tween(hackUi, ti, {Size = UDim2.fromScale(1.2,1.2), GroupTransparency = 1}, false, function()
        point:Destroy()
    end)
end

local function showPointPromt(point : BillboardGui)
    if not point:HasTag("ActiveNetPoint") then
        return
    end

    util.PlaySound(sounds.Select, script, 0.025)

    local hackUi = point.HackPrompt
    local ti = TweenInfo.new(0.25)

    currentInputIndex = 1

    hackUi.ActionName.Visible = false
    hackUi.ItemName.Visible = false
    hackUi.ActionName.Text = `Action: <font color="rgb(255,145,0)">{point.Adornee:GetAttribute("HackAction")}</font>`
    hackUi.ItemName.Text = point.Adornee.Name

    for _,v in ipairs(hackUi:GetChildren()) do
        if string.match(v.Name, "Keystroke_") then
            local key = math.random(1,4)
            v:SetAttribute("Key", key)
            v.TextTransparency = 1
            
            v.Text = globalInputType.inputType == "Gamepad" and "" or key

            v.Size = UDim2.fromScale(0.1, 0.075)
            v.TextColor3 = Color3.new(1,1,1)

            v.Prompt.ImageTransparency = 0.75
            v.Prompt.Visible = globalInputType.inputType == "Gamepad"

            if key == 1 then
                v.Prompt.Image = globalInputType.inputIcons.Misc.Up
            elseif key == 2 then
                v.Prompt.Image = globalInputType.inputIcons.Misc.Left
            elseif key == 3 then
                v.Prompt.Image = globalInputType.inputIcons.Misc.Down
            elseif key == 4 then
                v.Prompt.Image = globalInputType.inputIcons.Misc.Right
            end
        end
    end

    hackUi.Keystroke_1.TextColor3 = Color3.fromRGB(255,145,0)
    hackUi.Keystroke_1.Prompt.ImageTransparency = 0

    hackUi.Image.Position = UDim2.fromScale(0,0)

    local animation = uiAnimationService.PlayAnimation(hackUi, 0.045, false, true)

    animation:OnFrameRached(4):Connect(function()
        if not hackUi.Parent then
            return
        end

        util.tween({hackUi.Keystroke_1, hackUi.Keystroke_2, hackUi.Keystroke_3, hackUi.Keystroke_4}, ti, {TextTransparency = 0})
        util.tween({hackUi.Keystroke_2.Prompt, hackUi.Keystroke_3.Prompt, hackUi.Keystroke_4.Prompt}, ti, {ImageTransparency = 0.75})
        util.tween({hackUi.Keystroke_1.Prompt}, ti, {ImageTransparency = 0})

        util.flickerUi(hackUi.ItemName, 0.035, 5, true)
        util.flickerUi(hackUi.ActionName, 0.035, 5)

        if not hackUi.Parent then
            return
        end

        hackUi.ActionName.Visible = true
        hackUi.ItemName.Visible = true
    end)

    point.HackPrompt.Visible = true
    point.Point.Visible = false
end

local function hidePointPromt(point : BillboardGui?)
    if not point or not point.Parent then
        return
    end

    if not point:HasTag("ActiveNetPoint") then
        return
    end

    point.HackPrompt.Visible = false
    point.Point.Visible = true
end

local function placeNetPoint(object : Instance)
    local newNetPoint : BillboardGui = gui.NetPoint:Clone()
    newNetPoint.Parent = player.PlayerGui
    newNetPoint:AddTag("ActiveNetPoint")
    newNetPoint.Adornee = object

    newNetPoint.Enabled = true
end

local function placeNetPoints()
    for _,object in ipairs(CollectionService:GetTagged("Hackable")) do
        if not object:FindFirstAncestor("Workspace") then
            continue
        end
        placeNetPoint(object)
    end
end 

local function clearNetPoints()
    for _,object in ipairs(CollectionService:GetTagged("ActiveNetPoint")) do
        object:Destroy()
    end
end

local function refreshNetPoints()
    clearNetPoints()
    placeNetPoints()
end

local function getValidNetPoints()
    local character = player.Character
    if not character then
        return
    end

    local closest, closestPoint = math.huge, nil
    local validPoints = {}

    for _,netPoint : BillboardGui in ipairs(CollectionService:GetTagged("ActiveNetPoint")) do
        local object : BasePart | Model = netPoint.Adornee

        local vector, onScreen = camera:WorldToViewportPoint(object:GetPivot().Position)
        if not onScreen then
            continue
        end
        table.insert(validPoints, netPoint)

        local distanceToCursor = (Vector2.new(vector.X, vector.Y) - player:GetAttribute("CursorLocation")).Magnitude

        if distanceToCursor < closest then
            closest = distanceToCursor
            closestPoint = netPoint
        end
    end

    return validPoints, closestPoint
end

local function drawNetLines(validPoints : {}, closestPoint : BillboardGui)
    local character = player.Character
    if not character then
        return
    end


    local netLines : Path2D = UI.NetLines.Path2D
    local activeLine : Path2D = UI.NetLines.ActiveLine

    local tangentPoints = {}

    local playerPos = camera:WorldToViewportPoint(character:GetPivot().Position)

    for _,netPoint : BillboardGui in ipairs(validPoints) do
        if netPoint == closestPoint then
            continue
        end

        local object : BasePart | Model = netPoint.Adornee
        local screenPos = camera:WorldToViewportPoint(object:GetPivot().Position)
       
        local playerPoint = Path2DControlPoint.new(UDim2.fromOffset(playerPos.X, playerPos.Y))
        local point = Path2DControlPoint.new(UDim2.fromOffset(screenPos.X, screenPos.Y))

        table.insert(tangentPoints, playerPoint)
        table.insert(tangentPoints, point)
        
        -- draw points
    end

    netLines:SetControlPoints(tangentPoints)

    if not closestPoint then
        activeLine:SetControlPoints({})
        return
    end

    currentActivePoint.Value = closestPoint

    local closestObject : BasePart | Model = closestPoint.Adornee
    local screenPos = camera:WorldToViewportPoint(closestObject:GetPivot().Position)
    local playerPoint = Path2DControlPoint.new(UDim2.fromOffset(playerPos.X, playerPos.Y))
    local point = Path2DControlPoint.new(UDim2.fromOffset(screenPos.X, screenPos.Y))

    activeLine:SetControlPoints({
        playerPoint,
        point
    })
end

local function clearNetLines()
    local netLines : Path2D = UI.NetLines.Path2D
    local activeLine : Path2D = UI.NetLines.ActiveLine

    netLines:SetControlPoints({})
    activeLine:SetControlPoints({})
end

local function processNet()
    if not acts:checkAct("InNet") then
        return
    end

    local validPoints, closestPoint = getValidNetPoints()
    drawNetLines(validPoints, closestPoint)

    if not player.Character then
        return
    end
    actionPrompt.updateActionValue(player.Character:GetAttribute("RAM"))
end

local function doHackAction(object, point : BillboardGui)
    player.Character:SetAttribute("RAM", 0)

    local hackFunction = hackingFunctions[object:GetAttribute("HackAction")]

    util.PlaySound(sounds.HackSuccess, script)
    completePoint(point)

    if hackFunction then
        task.spawn(hackFunction, object, point)
    end

    refreshNetPoints()
end

local function checkHackGate(point : BillboardGui)
    local object = point.Adornee

    if object:GetAttribute("HackType") ~= "Prompt" then
        -- gate
        return
    end

   doHackAction(object, point)
end

local function checkKeystrokeInput(input)
    local character = player.Character
    if not character then
        return
    end

    local point = currentActivePoint.Value
    if not point or not point.Parent then
        return
    end

    local hackUi = currentActivePoint.Value.HackPrompt
    local keystrokeLabel = hackUi:FindFirstChild("Keystroke_" .. currentInputIndex)

    if not keystrokeLabel or input.KeyCode ~= getKeyCodeFromNumber(keystrokeLabel:GetAttribute("Key")) then
        return
    end

    if character:GetAttribute("RAM") < 1 then
        util.PlaySound(sounds.LowRam, script, 0.025)
        return
    end

    util.PlaySound(sounds.HackInput, script, 0.05)

    keystrokeLabel.TextColor3 = Color3.new(1,1,1)

    util.tween(keystrokeLabel, TweenInfo.new(0.25), {Size = UDim2.fromScale(0.15, 0.15), TextTransparency = 1})
    util.tween(keystrokeLabel.Prompt, TweenInfo.new(0.25), {ImageTransparency = 1})

    currentInputIndex += 1

    keystrokeLabel = hackUi:FindFirstChild("Keystroke_" .. currentInputIndex)
    if not keystrokeLabel then
        checkHackGate(currentActivePoint.Value)
        return
    end
    keystrokeLabel.TextColor3 = Color3.fromRGB(255,145,0)
    keystrokeLabel.Prompt.ImageTransparency = 0
end

function module:EnterNetMode()
    acts:createAct("InNet")
    actionPrompt.showActionPrompt("RAM")
    placeNetPoints()

    util.PlaySound(sounds.NetOpen, script)

    util.tween(Lighting.NETColor, ti, {
        TintColor = Color3.fromRGB(185, 255, 250),
        Brightness = 0.25,
        Contrast = 1,
        Saturation = -1,

    })
end

function module:ExitNetMode()
    acts:removeAct("InNet")
    actionPrompt.hideActionPrompt()
    clearNetPoints()
    clearNetLines()

    util.PlaySound(sounds.NetClose, script, 0, 0.25)

    util.tween(Lighting.NETColor, ti, {
        TintColor = Color3.new(1,1,1),
        Brightness = 0,
        Contrast = 0,
        Saturation = 0,
    })
end

function module.Init()
    RunService.RenderStepped:Connect(processNet)
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent or acts:checkAct("Paused") then
        return
    end

    if input.KeyCode == Enum.KeyCode.Tab or input.KeyCode == Enum.KeyCode.ButtonL1 then
        if acts:checkAct("InNet") then
            module:ExitNetMode()
        elseif not acts:checkAct("Interacting") then
            module:EnterNetMode()
        end
    end

    checkKeystrokeInput(input)
end)

currentActivePoint.Changed:Connect(function(point)
    hidePointPromt(lastActivePoint)
    showPointPromt(point)

    lastActivePoint = point
end)

return module