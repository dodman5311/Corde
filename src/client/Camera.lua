local module = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

function module.Init()
    camera.CameraType = Enum.CameraType.Scriptable
    camera.FieldOfView = 2   
end

local mouseView = Vector2.zero

RunService.RenderStepped:Connect(function()
    local character = player.Character
    if not character then
        return
    end

    local characterPosition = character:GetPivot().Position

    local mouseLocation = UserInputService:GetMouseLocation()
    local locationScale = mouseLocation / camera.ViewportSize
    local viewDistance = 12
    local viewLocation = (locationScale - Vector2.new(.5,.5)) * viewDistance

    mouseView = mouseView:Lerp(viewLocation, 0.1)

    camera.CFrame = CFrame.new(characterPosition + Vector3.new(mouseView.X,500,mouseView.Y)) * CFrame.Angles(math.rad(-90),0,0)

end)


return module