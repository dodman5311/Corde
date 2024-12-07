local module = {
    HungerRate = 0.35,
    RamRecoveryRate = 0.035
}


local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local moveDirection = Vector3.new()
local logPlayerDirection = 0

local camera = workspace.CurrentCamera
local Client = player.PlayerScripts.Client

local uiAnimationService = require(Client.UIAnimationService)
local inventory = require(Client.Inventory)
local timer = require(Client.Timer)
local util = require(Client.Util)
local weapons = require(Client.WeaponSystem)
local acts = require(Client.Acts)
local lastHeartbeat = os.clock()
local inputType = require(Client.GlobalInputType)

local mouse = player:GetMouse()

local assets = ReplicatedStorage.Assets
local sounds = assets.Sounds
local models = assets.Models

local logHealth = 0
local logLv = Vector3.zero
local logMousePos = Vector3.zero
local hungerDamageTimer = timer:new("HungerDamage", 2)
local cursorLocation = Vector2.zero

local thumbstick1Pos = Vector3.zero
local thumbstick2Pos = Vector3.zero
local thumbstickLookPos = Vector3.new(0,0,1)

local function spawnCharacter()
    local presetCharacter = models.Character
    local character:Model = presetCharacter:Clone()

    player.Character = character
    character.Parent = workspace

    logHealth = character:GetAttribute("Health")

    character:GetAttributeChangedSignal("Health"):Connect(function()
        
        if character:GetAttribute("Health") <= 0 then
            character:SetAttribute("Health", 0)

            player.Character = nil
            character:Destroy()

            task.delay(2, function()
                spawnCharacter()
            end)

        end

        if logHealth > character:GetAttribute("Health") then
            util.getRandomChild(sounds.Pain):Play()
        end

        logHealth = character:GetAttribute("Health")
    end)
end

function module:DamagePlayer(damage : number, damageType : string)
    player.Character:SetAttribute("Health", player.Character:GetAttribute("Health") - damage)
    player.Character:SetAttribute("LastDamageType", damageType)
end

hungerDamageTimer.Function = function()
    if not player.Character then
        return
    end

    module:DamagePlayer(10, "Hunger")
end

local function updatePlayerDirection()
    if cursorLocation.Magnitude <= 0.1 then
        cursorLocation = Vector2.new(moveDirection.X, moveDirection.Z)
    end
    
    player:SetAttribute("CursorPosition", cursorLocation)

    local character = player.Character
    if not character or acts:checkAct("Paused") then return end
    local gyro = character:FindFirstChild("Gyro")
    if not gyro then return end

    local characterPosition = character:GetPivot().Position

    local mousePosition = mouse.Hit.Position

    if acts:checkAct("InDialogue") then
        mousePosition = logMousePos
    else
        logMousePos = mousePosition
    end

    local lookPoint = Vector3.new(mousePosition.X, characterPosition.Y, mousePosition.Z)
    
    if inputType.inputType == "Gamepad" then
        gyro.CFrame = CFrame.lookAt(characterPosition, characterPosition + thumbstickLookPos)
    else
        gyro.CFrame = CFrame.lookAt(characterPosition, lookPoint)
    end

    local yOrientation = character.PrimaryPart.Orientation.Y
    local sway = logPlayerDirection - yOrientation
    local torsoMotor = character.PrimaryPart.Torso
    local legs = character.Legs

    torsoMotor.C1 = torsoMotor.C1:Lerp(CFrame.new(0,0,0) * CFrame.Angles(0,-math.rad(sway * 3),0), 0.4)
    

    local difference = (logLv - character:GetPivot().LookVector).Magnitude
    if difference >= 0.2 then
        util.PlaySound(util.getRandomChild(sounds.Movement), script, 0.1)
    end

    logPlayerDirection = yOrientation
    logLv = character:GetPivot().LookVector

    local lookPoint = characterPosition + module.moveUnit

    if module.moveUnit.Magnitude == 0 then
        lookPoint = (character:GetPivot() * CFrame.new(0,0,-1)).Position
    end

    legs.Gyro.CFrame = CFrame.lookAt(characterPosition, lookPoint) * CFrame.Angles(0,math.rad(90),0)
end

local function updateDirection(inputState, vector)
    if inputState == Enum.UserInputState.Begin then
        moveDirection += vector
    elseif inputState == Enum.UserInputState.End then
        moveDirection -= vector
    else
        moveDirection = vector
	end
	
	moveDirection = Vector3.new(math.clamp(moveDirection.X,-1,1),math.clamp(moveDirection.Y,-1,1),math.clamp(moveDirection.Z,-1,1))

    local character = player.Character
    if not character then return end

    local frame = character.Legs.UI.Frame
    local arms = character.Torso.UI.Reload

    if moveDirection.Magnitude > 0 then
        if uiAnimationService.CheckPlaying(frame) then
            return
        end

        uiAnimationService.PlayAnimation(frame, 0.125, true)

        if weapons.weaponUnequipped then
            uiAnimationService.PlayAnimation(arms, 0.125, true)
        end
        
        sounds.Steps:Resume()
    else
        sounds.Steps:Pause()
        uiAnimationService.StopAnimation(frame)

        if weapons.weaponUnequipped then
            uiAnimationService.StopAnimation(arms)
        end
    end
end

sounds.Steps.DidLoop:Connect(function()
    sounds.Steps.PlaybackSpeed = Random.new():NextNumber(1.45, 1.55)
end)

local function updateCursorData(action, state, key)
    

    if key.KeyCode == Enum.KeyCode.Thumbstick2 then
        cursorLocation = Vector2.new(key.Position.X, -key.Position.Y) * camera.ViewportSize

        thumbstick2Pos = key.Position
    elseif key.KeyCode == Enum.KeyCode.Thumbstick1 then
        thumbstick1Pos = key.Position
        
    elseif key.UserInputType == Enum.UserInputType.MouseMovement then
        cursorLocation = UserInputService:GetMouseLocation()
    end

    if key.KeyCode == Enum.KeyCode.Thumbstick2 or key.KeyCode == Enum.KeyCode.Thumbstick1 then
        local thumbPos
        if thumbstick2Pos.Magnitude <= .125 then
            thumbPos = Vector3.new(thumbstick1Pos.X, 0, -thumbstick1Pos.Y)
        else
            thumbPos = Vector3.new(thumbstick2Pos.X, 0, -thumbstick2Pos.Y)
            cursorLocation = thumbPos * camera.ViewportSize
        end

        if thumbPos.Magnitude > 0 then
            thumbstickLookPos = thumbPos
        end
    end

end


local function movePlayer(action, state, key)
    if acts:checkAct("InDialogue") then
        moveDirection = Vector3.new(0,0,0)
        updateDirection(state, Vector3.new(0,0,0))
        return
    end

    if key.KeyCode == Enum.KeyCode.W then
        updateDirection(state, Vector3.new(0,0,-1))
    elseif key.KeyCode == Enum.KeyCode.S then
        updateDirection(state, Vector3.new(0,0,1))
    elseif key.KeyCode == Enum.KeyCode.A then
        updateDirection(state, Vector3.new(-1,0,0))
    elseif key.KeyCode == Enum.KeyCode.D then
        updateDirection(state, Vector3.new(1,0,0))
    elseif key.KeyCode == Enum.KeyCode.Thumbstick1 then
        local position = Vector3.new(key.Position.X, 0, -key.Position.Y)

        if position.Magnitude <= 0.125 then
            position = Vector3.zero
        end

        updateDirection(state, position)
        updateCursorData(action, state, key)
    end
end

local function updatePlayerMovement()
    local character = player.Character
    if not character or acts:checkAct("Paused") then return end

    module.moveUnit = moveDirection.Magnitude ~= 0 and moveDirection.Unit or Vector3.zero
    local moveToPoint = module.moveUnit * character:GetAttribute("Walkspeed") 

    local walkVelocity = character.WalkVelocity

    walkVelocity.VectorVelocity = walkVelocity.VectorVelocity:Lerp(moveToPoint, 0.1)     
end

function  module.Init()
    spawnCharacter()

    ContextActionService:BindAction("Walk", movePlayer, false, Enum.KeyCode.W, Enum.KeyCode.S, Enum.KeyCode.A, Enum.KeyCode.D, Enum.KeyCode.Thumbstick1)
    ContextActionService:BindAction("updateCursorData", updateCursorData, false, Enum.UserInputType.MouseMovement, Enum.KeyCode.Thumbstick2)

    RunService:BindToRenderStep("updatePlayerMovement", Enum.RenderPriority.Character.Value, updatePlayerMovement)
    RunService:BindToRenderStep("updatePlayerDirection", Enum.RenderPriority.Character.Value + 1, updatePlayerDirection)
end

RunService.Heartbeat:Connect(function()
    if player.Character and not acts:checkAct("Paused") then
        if player.Character:GetAttribute("Hunger") <= 0 then
            player.Character:SetAttribute("Hunger", 0)
            hungerDamageTimer:Run()
        elseif player.Character:GetAttribute("Hunger") > 100 then
            player.Character:SetAttribute("Hunger", 100)
        else
            player.Character:SetAttribute("Hunger", player.Character:GetAttribute("Hunger") - ((os.clock() - lastHeartbeat) * module.HungerRate))
        end     
        
        if player.Character:GetAttribute("RAM") < 0 then
            player.Character:SetAttribute("RAM", 0)
        elseif player.Character:GetAttribute("RAM") >= 1 then
            player.Character:SetAttribute("RAM", 1)
        else
            player.Character:SetAttribute("RAM", player.Character:GetAttribute("RAM") + ((os.clock() - lastHeartbeat) * module.RamRecoveryRate))
        end
    end

    lastHeartbeat = os.clock()
end)

inventory.ItemUsed:Connect(function(use, item, slot)
    if not player.Character or use ~= "Eat" then
        return
    end

    player.Character:SetAttribute("Hunger", player.Character:GetAttribute("Hunger") + item.Value)

    inventory[slot] = nil
end)

player:SetAttribute("CursorPosition", Vector2.zero)
player:SetAttribute("CursorHit", Vector2.zero)

return module