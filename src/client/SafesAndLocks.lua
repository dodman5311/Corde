local ReplicatedStorage = game:GetService("ReplicatedStorage")
local module = {
    currentDisplayedModel = nil,
}
local client = script.Parent
local cameraService = require(client.Camera)
local acts = require(client.Acts)

local locksAndSafesFolder = ReplicatedStorage.Assets.Models.LocksAndSafes

function module:EnterLock(lockObject : Instance)
    local modelName = lockObject:GetAttribute("3DModel")
    if not modelName or acts:checkAct("Interacting") then
        return
    end

    local model = locksAndSafesFolder:FindFirstChild(modelName)
    if not model then
        return
    end

    acts:createAct("Interacting")

    local newModel = model:Clone()
    newModel.Parent = workspace
    newModel:PivotTo(CFrame.new(0,-100,0))    
    local cameraRoot = newModel.PrimaryPart.CameraRoot

    cameraService:EnterFirstPerson(cameraRoot.WorldCFrame, cameraRoot:GetAttribute("ViewRange"), cameraRoot:GetAttribute("FieldOfView"))
    module.currentDisplayedModel = newModel
    return newModel
end

function module:ExitLock()
    acts:removeAct("Interacting")
    cameraService:EnterFollow()
    module.currentDisplayedModel:Destroy()
end

function module.Init()
end

return module