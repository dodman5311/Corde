local screenEffects = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local effectsGui = ReplicatedStorage.Assets.Gui.ScreenEffects

effectsGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local util = require(script.Parent.Util)

for _, frame in ipairs(effectsGui:GetChildren()) do
	frame.Visible = frame.Name == util.getSetting("Graphics", "Screen Effects")
end

return screenEffects
