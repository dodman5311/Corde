local module = {
    HungerRate = 0.35
}


local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local moveDirection = Vector3.new()
local logPlayerDirection = 0

local Client = player.PlayerScripts.Client

local uiAnimationService = require(Client.UIAnimationService)
local inventory = require(Client.Inventory)
local timer = require(Client.Timer)
local util = require(Client.Util)
local weapons = require(Client.WeaponSystem)
local acts = require(Client.Acts)
local lastHeartbeat = os.clock()

local logHealth = 0

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

return module