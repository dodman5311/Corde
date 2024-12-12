export type CameraMode = "Follow" | "FirstPerson" | "Scriptable"
export type FirstPersonData = {
    RootCFrame : CFrame,
    ViewRange : number,
    FieldOfView : number,
}

local module = {
    mode = "Follow" :: CameraMode,
    followViewDistance = {
        current = 0,
        default = 15,
    },
    fieldOfView =  1.75,

    firstPersonData = {
        RootCFrame = CFrame.new(),
        ViewRange = 30,
        FieldOfView = 60,
    } :: FirstPersonData
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

local shakeOffset = CFrame.new()
local cameraShaker = require(script.Parent.CameraShaker)
local mouseView = Vector2.zero

local function shakeCamera(shakeCframe)
    shakeOffset = shakeCframe
end

module.shaker = cameraShaker.new(Enum.RenderPriority.Camera.Value + 1, shakeCamera)
module.shaker:Start()

function module:EnterFirstPerson(rootCFrame : CFrame, viewRange : number?, fieldOfView : number?)
    module.firstPersonData = {
        RootCFrame = rootCFrame,
        ViewRange = viewRange or 30,
        FieldOfView = fieldOfView or 60,
    } :: FirstPersonData

    module.mode = "FirstPerson" :: CameraMode
end

function module.Init()
    camera.CameraType = Enum.CameraType.Scriptable
    camera.FieldOfView = module.fieldOfView
    module.followViewDistance.current = module.followViewDistance.default
end

RunService:BindToRenderStep("RunCamera", Enum.RenderPriority.Camera.Value, function()
    local character = player.Character
    if not character then
        return
    end

    local characterPosition = character:GetPivot().Position

    if module.mode == "Follow" then
        local mouseLocation = player:GetAttribute("CursorLocation")
        local locationScale = mouseLocation / camera.ViewportSize
        local viewLocation = (locationScale - Vector2.new(.5,.5)) * module.followViewDistance.current
        mouseView = mouseView:Lerp(viewLocation, 0.1)

        local goal = CFrame.new(characterPosition + Vector3.new(mouseView.X,500,mouseView.Y)) * CFrame.Angles(math.rad(-90),0,0)
        camera.CFrame = goal * shakeOffset
    end
end)

return module