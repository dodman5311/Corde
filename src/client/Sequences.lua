local module = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local sounds = ReplicatedStorage.SequenceSounds

local mouseTarget = Instance.new("ObjectValue")
mouseTarget.Parent = player
mouseTarget.Name = "MouseTarget"

local UI = ReplicatedStorage.Sequences
UI.Parent = player.PlayerGui

local Client = player.PlayerScripts.Client
local world = require(Client.World)
local uiAnimationService = require(Client.UIAnimationService)
local acts = require(Client.Acts)
local util = require(Client.Util)

function module.Init()
    
end

function module:beginSequence(sequenceName)
    world:pause()

    if not module[sequenceName] then
        warn(sequenceName .. " is not a valid sequence.")
        return
    end

    util.tween({SoundService.WorldSounds, SoundService.Music}, TweenInfo.new(1), {Volume = 0})

    acts:createTempAct("InSequence", module[sequenceName])

    util.tween({SoundService.WorldSounds, SoundService.Music}, TweenInfo.new(1), {Volume = 0.5})

    world:resume()
end

local function loadSequence(sequence)
    local sequenceFrame = UI[sequence]:Clone()
    sequenceFrame.Name = "PlayingSequence"
    sequenceFrame.Parent = UI
    return sequenceFrame
end

function module.noMercy()
    local sequenceFrame = loadSequence("NoMercy")
    local textFrame = sequenceFrame.Text

    local ti_0 = TweenInfo.new(6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local ti_1 = TweenInfo.new(8, Enum.EasingStyle.Linear)
    local ti_2 = TweenInfo.new(1, Enum.EasingStyle.Linear)

    sounds.Distortion_0.Volume = 1.5

    task.wait(3)

    print(SoundService.Music.Volume)

    util.PlaySound(sounds.Distortion_0, script, 0, 0.1)
    sequenceFrame.Visible = true
    task.wait(0.1)
    sequenceFrame.Visible = false
    
    task.wait(2)

    util.PlaySound(sounds.Distortion_0, script, 0, 0.1)
    sequenceFrame.Visible = true
    task.wait(0.1)
    sequenceFrame.Visible = false
    
    task.wait(1)

    util.PlaySound(sounds.Distortion_0, script, 0, 0.1)
    sequenceFrame.Visible = true
    task.wait(0.1)
    sequenceFrame.Visible = false

    task.wait(0.25)
    util.PlaySound(sounds.Distortion_0, script, 0, 0.1)
    sequenceFrame.Visible = true
    task.wait(0.1)
    sequenceFrame.Visible = false
    task.wait(0.25)

    sounds.Distortion_0.Volume = 0.5
    SoundService.WorldSounds.Volume = 0

    sounds.Distortion_0:Play()

    sounds.Ambience_0.Volume = 0
    sounds.Ambience_0:Play()
    
    sequenceFrame.Visible = true

    util.tween(sounds.Ambience_0, ti_1, {Volume = 1})

    task.wait(2)

    task.spawn(function()
        local i = 2

        while sequenceFrame and sequenceFrame.Parent do
            sequenceFrame.Hands.Image.Position = UDim2.fromOffset(math.random(-2, 2),math.random(-2, 2))
            sequenceFrame.RedX.Position = UDim2.fromOffset(i,0)
            sequenceFrame.RedPlus.Position = UDim2.fromOffset(i,0)
            i *= -1

            task.wait(0.025)
        end
    end)

    util.tween(sequenceFrame.Hands, ti_0, {Position = UDim2.fromScale(0,1)})

    task.wait(3)

    textFrame.Visible = true
    task.delay(0.1, function()
        textFrame.Visible = false
        textFrame.Label.Text = "Mercy"
    end)

    task.wait(3)
    textFrame.Visible = true
    task.wait(0.1)
    textFrame.Visible = false
    task.wait(1.5)

    sounds.Exit:Play()
    task.wait(0.1)
    sequenceFrame.RedX.Visible = true
    task.wait(0.1)

    sequenceFrame.RedX.Visible = false
    sequenceFrame.Reel.Visible = true
    sequenceFrame.Background.Visible = false
    sequenceFrame.Hands.Visible = false

    uiAnimationService.PlayAnimation(sequenceFrame.Reel, 0.075, false, true).OnEnded:Wait()
    task.wait(0.2)
    sequenceFrame.Reel.Visible = false
    sequenceFrame.RedPlus.Visible = true
    task.wait(0.6)

    UI.Fade.BackgroundTransparency = 0
    
    sequenceFrame:Destroy()

    task.delay(0.5, function()
        util.tween(UI.Fade, ti_2, {BackgroundTransparency = 1})
    end)
    
    sounds.Distortion_0:Stop()
    sounds.Ambience_0:Stop()

    SoundService.WorldSounds.Volume = 0.5
end

return module