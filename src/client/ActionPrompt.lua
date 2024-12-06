local module = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Client = player.PlayerScripts.Client

local acts= require(Client.Acts)
local util = require(Client.Util)
local signals = require(ReplicatedStorage.Packages.Signal)

module.ActionBegun = signals.new()

local ti_0 = TweenInfo.new(0.075, Enum.EasingStyle.Linear)

local ti_1 = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In)

function module.showActionPrompt(actionTitle : string)
    if not player.Character then
        return
    end

    module.ActionBegun:Fire(actionTitle)
    acts:createAct("Interacting")

    local character = player.Character
    local promptPart = character.ActionPrompt
    local prompt = promptPart.UI

    local frame = prompt.Frame
    local barFrame = frame.BarFrame

    barFrame.Bar.Size = UDim2.fromScale(1,0)
    barFrame.B.Size = UDim2.fromScale(1,0)
    barFrame.R.Size = UDim2.fromScale(1,0)

    frame.Action.Text = actionTitle
    frame.ActionR.Text = actionTitle
    frame.ActionB.Text = actionTitle

    util.tween(frame, ti_0, {GroupTransparency = 0})
end

function module.hideActionPrompt()
    if not player.Character then
        return
    end

    acts:removeAct("Interacting")
    util.tween(player.Character.ActionPrompt.UI.Frame, ti_1, {GroupTransparency = 1})
end

function module.updateActionValue(value : number)
    if not player.Character then
        return
    end

    local character = player.Character
    local promptPart = character.ActionPrompt
    local prompt = promptPart.UI

    local frame = prompt.Frame
    local barFrame = frame.BarFrame

    barFrame.Bar.Size = UDim2.fromScale(1,value)
    barFrame.B.Size = UDim2.fromScale(1,value)
    barFrame.R.Size = UDim2.fromScale(1,value)
end

function module.showAction(showTime, actionTitle)
    if not player.Character then
        return
    end

    local character = player.Character
    local promptPart = character.ActionPrompt
    local prompt = promptPart.UI

    local frame = prompt.Frame
    local barFrame = frame.BarFrame

    local barTi = TweenInfo.new(showTime, Enum.EasingStyle.Linear)

    module.showActionPrompt(actionTitle)

    util.tween(barFrame.Bar, barTi, {Size = UDim2.fromScale(1,1)})
    util.tween(barFrame.B, barTi, {Size = UDim2.fromScale(1,1)})
    util.tween(barFrame.R, barTi, {Size = UDim2.fromScale(1,1)}, false, function()
        module.hideActionPrompt()
    end)
end

function module.showActionTimer(actionTimer, actionTitle)
    module.showActionPrompt(actionTitle)

    local onStep = actionTimer.OnTimerStepped:Connect(function(currentTime)
        module.updateActionValue(currentTime / actionTimer.WaitTime)
    end)

    actionTimer.OnEnded:Once(function()
        onStep:Disconnect()
        module.hideActionPrompt()
    end)
end

return module