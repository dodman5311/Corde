local module = {}

local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")


local player = Players.LocalPlayer
local Client = player.PlayerScripts.Client

local uiAnimationService = require(Client.UIAnimationService)
local inventory = require(script.Parent.Inventory)
local util = require(script.Parent.Util)
local signals = require(ReplicatedStorage.Packages.Signal)

module.ActionBegun = signals.new()

local ti_0 = TweenInfo.new(0.075, Enum.EasingStyle.Linear)

local ti_1 = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In)

local function showActionPrompt(actionTitle)
    if not player.Character then
        return
    end

    module.ActionBegun:Fire(actionTitle)

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

    showActionPrompt(actionTitle)

    util.tween(barFrame.Bar, barTi, {Size = UDim2.fromScale(1,1)})
    util.tween(barFrame.B, barTi, {Size = UDim2.fromScale(1,1)})
    util.tween(barFrame.R, barTi, {Size = UDim2.fromScale(1,1)}, false, function()
        util.tween(frame, ti_1, {GroupTransparency = 1})
    end)
end

function module.showActionTimer(actionTimer, actionTitle)
    if not player.Character then
        return
    end

    local character = player.Character
    local promptPart = character.ActionPrompt
    local prompt = promptPart.UI

    local frame = prompt.Frame
    local barFrame = frame.BarFrame

    showActionPrompt(actionTitle)

    local onStep = actionTimer.OnTimerStepped:Connect(function(currentTime)
        barFrame.Bar.Size = UDim2.fromScale(1,currentTime / actionTimer.WaitTime)
        barFrame.B.Size = UDim2.fromScale(1,currentTime / actionTimer.WaitTime)
        barFrame.R.Size = UDim2.fromScale(1,currentTime / actionTimer.WaitTime)
    end)

    actionTimer.OnEnded:Once(function()
        onStep:Disconnect()
        util.tween(frame, ti_1, {GroupTransparency = 1})
    end)
end

return module