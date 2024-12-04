local CameraMode = {
    Follow = "Follow",
    FirstPerson = "FirstPerson",
    Scriptable = "Scriptable",
}

local module = {
    mode = CameraMode.Follow,
    followViewDistance = {
        current = 0,
        default = 15,
    },
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

function module.Init()
    camera.CameraType = Enum.CameraType.Scriptable
    camera.FieldOfView = 1.75

    module.followViewDistance.current = module.followViewDistance.default
end

local mouseView = Vector2.zero

RunService.RenderStepped:Connect(function()
    local character = player.Character
    if not character then
        return
    end

    local characterPosition = character:GetPivot().Position

    if module.mode == CameraMode.Follow then
        local mouseLocation = UserInputService:GetMouseLocation()
        local locationScale = mouseLocation / camera.ViewportSize
        local viewLocation = (locationScale - Vector2.new(.5,.5)) * module.followViewDistance.current
        mouseView = mouseView:Lerp(viewLocation, 0.1)
    
        camera.CFrame *= CFrame.Angles(0,0,math.rad(180))
        camera.CFrame = CFrame.new(characterPosition + Vector3.new(mouseView.X,500,mouseView.Y)) * CFrame.Angles(math.rad(-90),0,0)
    end
end)


return module