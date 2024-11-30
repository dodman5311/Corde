local module = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local mouse = player:GetMouse()

local mouseTarget = Instance.new("ObjectValue")
mouseTarget.Parent = player
mouseTarget.Name = "MouseTarget"

local UI

local Client = player.PlayerScripts.Client
local uiAnimationService = require(Client.UIAnimationService)
local inventory = require(Client.Inventory)
local dialogue = require(Client.Dialogue)
local acts = require(Client.Acts)

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
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    local object = mouseTarget.Value

    if input.KeyCode ~= Enum.KeyCode.F or gameProcessedEvent or not object  then
        return
    end

    if object:HasTag("Container") then
        inventory:pickupFromContainer(mouseTarget.Value)
    end

    if object:HasTag("NPC") then
        dialogue:EnterDialogue(mouseTarget.Value)
    end

end)

local function processCrosshair()

    if not player.Character then
        mouseTarget.Value = nil
        return
    end

    local distanceToMouse = (player.Character:GetPivot().Position - mouse.Hit.Position).Magnitude
    
    if distanceToMouse > 4 then
        mouseTarget.Value = nil
    else
        mouseTarget.Value = mouse.Target:FindFirstAncestorOfClass("Model") or mouse.Target
    end
end

function module.Init()
    UI = player.PlayerGui.Crosshair
    RunService.RenderStepped:Connect(processCrosshair)
end

return module