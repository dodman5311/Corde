local module = {}


local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local moveDirection = Vector3.new()
local logPlayerDirection = 0

local assets = ReplicatedStorage.Assets
local models = assets.Models

local Client = player.PlayerScripts.Client

local uiAnimationService = require(Client.UIAnimationService)
local util = require(Client.Util)

function module.dropItem(item)
    local newObject = models.DroppedItem:Clone()

    newObject.Parent = workspace
end

function module.Init()

end

return module