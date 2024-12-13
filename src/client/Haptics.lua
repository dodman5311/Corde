local HapticService = game:GetService("HapticService")
local Players = game:GetService("Players")

local module = {}

local player = Players.LocalPlayer

local Client = player.PlayerScripts.Client

local globalInputService = require(Client.GlobalInputService)
local timer = require(Client.Timer)

function module.hapticPulse(input, motor: Enum.VibrationMotor, value, runTime, timerIndex)
    if globalInputService.inputType ~= "Gamepad" then
        return
    end

    HapticService:SetMotor(input.UserInputType, motor, value)
    
    local offTimer = timer:new(timerIndex, runTime, function()
        HapticService:SetMotor(input.UserInputType, motor, 0)
    end)

    offTimer.WaitTime = runTime
    offTimer:Reset()
    offTimer:Run()
end
return module