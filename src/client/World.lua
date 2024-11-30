local module = {}


local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local Client = player.PlayerScripts.Client

local util = require(Client.Util)
local acts = require(Client.Acts)

function module.placeNpcBody(npc)
    local newBody = ReplicatedStorage.DeadNpc:Clone()
    newBody.Parent = workspace
    newBody:PivotTo(npc:GetPivot())

    local body : Part = newBody.Body
    body.AssemblyLinearVelocity = body.CFrame.LookVector * -50

    local deathSoundList = ReplicatedStorage[npc:GetAttribute("Gender") .. "_Death"]
    local deathSound = util.getRandomChild(deathSoundList)
    local bloodSound = util.getRandomChild(ReplicatedStorage.Blood)

    util.PlaySound(deathSound, script, 0.05, 0.2)
    util.PlaySound(bloodSound, script, 0.15)
end

function module:pause()
    if acts:checkAct("Paused") then
        return
    end

    acts:createAct("Paused")

    for _,object in ipairs(workspace:GetDescendants()) do
        if object:IsA("ParticleEmitter") then
            object.TimeScale = 0
        end

        if object:IsA("BasePart") and not object.Anchored then
            object.Anchored = true
            object:SetAttribute("ToBeUnanchored", true)
        end
    end
end

function module:resume()
    if not acts:checkAct("Paused") then
        return
    end

    acts:removeAct("Paused")

    for _,object in ipairs(workspace:GetDescendants()) do
        if object:IsA("ParticleEmitter") then
            object.TimeScale = 1
        end

        if object:IsA("BasePart") and object:GetAttribute("ToBeUnanchored") then
            object.Anchored = false
            object:SetAttribute("ToBeUnanchored", false)
        end
    end
end

function  module.Init()

    for _,npc in ipairs(CollectionService:GetTagged("NPC")) do
        npc:GetAttributeChangedSignal("Health"):Connect(function()
            if npc:GetAttribute("Health") > 0 then
                return
            end

            module.placeNpcBody(npc)
            npc:Destroy()
        end)
    end
end

RunService.Heartbeat:Connect(function()
    if acts:checkAct("Paused") then
        return
    end
    
    for _,item in ipairs(CollectionService:GetTagged("PhysicsItem")) do -- Process Physics

        if item.AssemblyLinearVelocity == Vector3.new(0,0,0) and item.AssemblyAngularVelocity == Vector3.new(0,0,0) then
            continue
        end

        item.AssemblyLinearVelocity /= 1 + item.Mass
        item.AssemblyAngularVelocity /= 1 + item.Mass

        if item.AssemblyLinearVelocity.Magnitude <= 0.25 then
            item.AssemblyLinearVelocity = Vector3.zero
        end

        if item.AssemblyAngularVelocity.Magnitude <= 0.25 then
            item.AssemblyAngularVelocity = Vector3.zero
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if input.KeyCode == Enum.KeyCode.P then
        if acts:checkAct("Paused") then
            module:resume()
        else
            module:pause()
        end
    end
end)

return module