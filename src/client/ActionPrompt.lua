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

function module.showAction(showTime, actionTitle)
    if not player.Character then
        return
    end

    local ti_0 = TweenInfo.new(0.075, Enum.EasingStyle.Linear)
    local ti_1 = TweenInfo.new(showTime, Enum.EasingStyle.Linear)
    local ti_2 = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In)

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

    util.tween(barFrame.Bar, ti_1, {Size = UDim2.fromScale(1,1)})
    util.tween(barFrame.B, ti_1, {Size = UDim2.fromScale(1,1)})
    util.tween(barFrame.R, ti_1, {Size = UDim2.fromScale(1,1)}, false, function()
        util.tween(frame, ti_2, {GroupTransparency = 1})
    end)
end

return module