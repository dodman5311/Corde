local module = {}

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer

local assets = ReplicatedStorage.Assets
local soundsFolder = assets.Sounds

local sequenceSounds = soundsFolder.SequenceSounds
local camera = workspace.CurrentCamera

local UI = StarterGui.Sequences
UI.Parent = player.PlayerGui

local Client = player.PlayerScripts.Client
local Achievements = require(script.Parent.Achievements)
local acts = require(Client.Acts)
local globalInputService = require(Client.GlobalInputService)
local musicService = require(Client.MusicService)
local scales = require(Client.Scales)
local signal = require(ReplicatedStorage.Packages.Signal)
local uiAnimationService = require(Client.UIAnimationService)
local util = require(Client.Util)

module.OnEnded = signal.new()
local rng = Random.new()

local function changePropertyForTable(list: {}, propertyTable: {})
	for _, object: Instance in ipairs(list) do
		for property, value in pairs(propertyTable) do
			object[property] = value
		end
	end
end

function module:beginSequence(sequenceName, ...)
	if not module[sequenceName] then
		warn(sequenceName .. " is not a valid sequence.")
		return
	end

	local params = { ... }

	task.spawn(function()
		scales.activeScales["InteractDisabled"]:Add("InSequence")
		acts:createTempAct("InSequence", module[sequenceName], nil, table.unpack(params))

		module.OnEnded:Fire(sequenceName)
		scales.activeScales["InteractDisabled"]:Remove("InSequence")
	end)
end

local function loadSequence(sequence): Frame
	local sequenceFrame = UI[sequence]:Clone()
	sequenceFrame.Name = "PlayingSequence"
	sequenceFrame.Parent = UI
	return sequenceFrame
end

local function showBars()
	local ti = TweenInfo.new(2.5, Enum.EasingStyle.Quad)

	local bars = UI.Bars
	bars.UIAspectRatioConstraint.AspectRatio = camera.ViewportSize.X / camera.ViewportSize.Y

	bars.Visible = true
	util.tween(bars.UIAspectRatioConstraint, ti, { AspectRatio = 2.39 })
end

local function hideBars()
	local ti = TweenInfo.new(1, Enum.EasingStyle.Quad)

	local bars = UI.Bars

	util.tween(
		bars.UIAspectRatioConstraint,
		ti,
		{ AspectRatio = camera.ViewportSize.X / camera.ViewportSize.Y },
		false,
		function()
			bars.Visible = false
		end
	)
end

local function playPingSound()
	util.PlaySound(soundsFolder.StaticHit)
	local sound = util.PlaySound(soundsFolder.PingSound)
	local ti = TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.In)
	util.tween(sound, ti, { Volume = 0, PlaybackSpeed = 1.95 })
end

local function showMirrorMan()
	if rng:NextNumber(0, 100) > 15 then
		return
	end

	-- @TODO Show mirror man

	Achievements:AwardAchievement(Achievements.Ids.WomanInTheMirror)
end

function module.UseMirror()
	globalInputService.actionGroups["PlayerControl"]:Disable("Sequence")
	showBars()
	local ti = TweenInfo.new(2.5, Enum.EasingStyle.Quad)
	local ti_0 = TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
	local ti_1 = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local blinkTi = TweenInfo.new(0.2, Enum.EasingStyle.Linear)
	local sequenceFrame = loadSequence("Mirror")

	local background: ImageLabel = sequenceFrame.Background
	local imageFrame: Frame = sequenceFrame.Frame
	local eyeFrame: Frame = sequenceFrame.EyeFrame
	local smudge: ImageLabel = sequenceFrame.Smudge

	local c = 0
	local lerpCount = 0.25

	local step = RunService.RenderStepped:Connect(function(dt)
		c += dt / 2
		if c >= math.pi * 2 then
			c = 0
		end
		local xAngle = (math.rad(math.sin(c)) * 1.25) / 3
		local yAngle = (math.rad(math.sin(c + 1)) * 1.25) / 3

		local mouse = player:GetAttribute("CursorLocation")

		local xposition = mouse.X
		local xsize = camera.ViewportSize.X
		local xnormalizedPosition = ((-xposition / xsize) + 0.5) / 50

		local yposition = mouse.Y
		local ysize = camera.ViewportSize.Y
		local ynormalizedPosition = ((-yposition / ysize) + 0.5) / 25

		local fullX = xnormalizedPosition + xAngle
		local fullY = ynormalizedPosition + yAngle

		background.Position = background.Position:Lerp(UDim2.fromScale(0.5 + (fullX * 4), 0.5 + (fullY * 4)), lerpCount)

		imageFrame.Position = imageFrame.Position:Lerp(UDim2.fromScale(0.5 + fullX, 0.5 + fullY), lerpCount)

		eyeFrame.Position = eyeFrame.Position:Lerp(
			UDim2.fromScale(0.5 + (xnormalizedPosition / 1.5) + xAngle, 0.5 + (ynormalizedPosition / 1.5) + yAngle),
			lerpCount
		)

		smudge.Position = smudge.Position:Lerp(UDim2.fromScale(0.5 + (fullX * 1.5), 0.5 + (fullY * 1.5)), lerpCount)
	end)

	util.tween(UI.Fade, ti, { BackgroundTransparency = 0 }, true)
	util.tween(UI.Fade, ti_0, { BackgroundTransparency = 1 })

	sequenceFrame.Visible = true

	util.PlaySound(sequenceSounds.Cloth)
	showMirrorMan()

	for i = 0, 2 do
		imageFrame.Image.Position = UDim2.new(-i, 0)
		eyeFrame.Image.Position = UDim2.new(-i, 0)
		task.wait(0.25)
	end

	for _ = 1, 2 do
		task.wait(2)

		util.tween(UI.Fade, blinkTi, { BackgroundTransparency = 0 })
		for i = 2, 4 do
			imageFrame.Image.Position = UDim2.new(-i, 0)
			task.wait(0.1)
		end
		util.tween(UI.Fade, blinkTi, { BackgroundTransparency = 1 })
		for i = 4, 2, -1 do
			imageFrame.Image.Position = UDim2.new(-i, 0)
			task.wait(0.1)
		end
	end

	task.wait(2.5)

	util.PlaySound(sequenceSounds.Breath)
	util.PlaySound(sequenceSounds.Cloth).PlaybackSpeed = 0.7

	util.tween(UI.Fade, ti_1, { BackgroundTransparency = 0 }, false, function()
		step:Disconnect()
		sequenceFrame:Destroy()
		hideBars()
		util.tween(UI.Fade, ti, { BackgroundTransparency = 1 })

		globalInputService.actionGroups["PlayerControl"]:Enable("Sequence")
	end)

	for i = 2, 0, -1 do
		imageFrame.Image.Position = UDim2.new(-i, 0)
		eyeFrame.Image.Position = UDim2.new(-i, 0)
		task.wait(0.25)
	end
end

local function showTextForPeriod(message: string, frame: GuiObject, showTime: number, color: Color3?)
	local changeTable = { Text = message }
	if color then
		changeTable.TextColor3 = color
	end
	changePropertyForTable(frame:GetChildren(), changeTable)
	frame.Visible = true
	task.wait(showTime)
	frame.Visible = false
end

function module.InstallModule()
	globalInputService.actionGroups["PlayerControl"]:Disable("Sequence")
	showBars()
	local ti = TweenInfo.new(2.5, Enum.EasingStyle.Quad)
	local ti_0 = TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
	local ti_1 = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local sequenceFrame = loadSequence("Install")

	local background: ImageLabel = sequenceFrame.Background
	local imageFrame: Frame = sequenceFrame.Frame
	local eyeFrame: Frame = sequenceFrame.EyeFrame
	local smudge: ImageLabel = sequenceFrame.Smudge

	------------------------------------------------------------------------ INTRO

	util.tween(UI.Fade, ti, { BackgroundTransparency = 0 }, true)
	util.tween(UI.Fade, ti_0, { BackgroundTransparency = 1 })

	sequenceFrame.Visible = true

	util.PlaySound(sequenceSounds.Cloth)

	for _ = 0, 5 do
		local animation = uiAnimationService.PlayAnimation(imageFrame, 0.15, false, true)
		animation:OnFrameReached(3):Wait()
		uiAnimationService.StopAnimation(imageFrame)
		task.wait(0.15)
	end

	local animation = uiAnimationService.PlayAnimation(imageFrame, 0.15, false, true)

	animation:OnFrameReached(7):Wait()
	animation:Pause()
	task.wait(0.2)
	animation:Resume()

	animation:OnFrameReached(17):Wait()
	animation:Pause()
	task.wait(0.3)
	animation:Resume()

	animation:OnFrameReached(21):Wait()

	sequenceFrame.Glitch.Visible = true
	uiAnimationService.PlayAnimation(sequenceFrame.Glitch, 0.025) -- 0.0125

	local glitchSound = util.PlaySound(soundsFolder.GlitchSound_Heavy)
	glitchSound.PlaybackSpeed = 2.5
	glitchSound.Ended:Wait()

	sequenceFrame.Glitch.Visible = false
	background.Visible = false
	smudge.Visible = false
	imageFrame.Visible = false

	task.wait(3)

	------------------------------------------------------------------------

	local step = RunService.RenderStepped:Connect(function()
		for _, child in ipairs(sequenceFrame.ScreenText:GetChildren()) do
			if child.Name == "Main" then
				child.Position = UDim2.fromOffset(math.random(-1, 1), math.random(-1, 1))
				continue
			end

			child.Position = UDim2.fromOffset(math.random(-10, 10), math.random(-10, 10))
		end

		sequenceFrame.RedX.Position = UDim2.new(0.5, math.random(-2, 2), 0.5, math.random(-2, 2))
	end)

	playPingSound()
	showTextForPeriod("You’re my favorite.", sequenceFrame.ScreenText, 3, Color3.new(1))

	util.PlaySound(soundsFolder.StaticHit)
	sequenceFrame.RedX.Visible = true
	task.wait(2)
	sequenceFrame.Glitch2.Visible = true

	util.PlaySound(soundsFolder.GlitchSound, 0.2).TimePosition = 1
	uiAnimationService.PlayAnimation(sequenceFrame.Glitch2, 0.05)

	task.wait(0.25)
	sequenceFrame.Glitch2.Visible = false
	sequenceFrame.RedX.Visible = false

	playPingSound()
	showTextForPeriod("Did you know that?", sequenceFrame.ScreenText, 2.5)
	util.PlaySound(soundsFolder.StaticHit)

	sequenceFrame.Heart.Visible = true
	uiAnimationService.PlayAnimation(sequenceFrame.Heart, 0.05, true)
	task.wait(0.75)
	sequenceFrame.Heart.Visible = false

	util.PlaySound(soundsFolder.StaticHit)
	sequenceFrame.Cells.Visible = true
	uiAnimationService.PlayAnimation(sequenceFrame.Cells, 0.05, true)
	task.wait(0.75)
	sequenceFrame.Cells.Visible = false

	playPingSound()
	showTextForPeriod("It's okay.", sequenceFrame.ScreenText, 0.25)
	util.PlaySound(soundsFolder.StaticHit)
	-- VOID VISIONS
	sequenceFrame.Void.Visible = true
	uiAnimationService.PlayAnimation(sequenceFrame.Void, 0.075, true)
	task.wait(0.75)
	sequenceFrame.Void.Visible = false

	for timeFrame = 0.25, 0.05, -0.1 do
		util.PlaySound(soundsFolder.StaticHit)
		sequenceFrame.Cells.Visible = true
		task.wait(timeFrame)
		util.PlaySound(soundsFolder.StaticHit)
		sequenceFrame.Cells.Visible = false
		sequenceFrame.Heart.Visible = true
		task.wait(timeFrame)
		util.PlaySound(soundsFolder.StaticHit)
		sequenceFrame.Heart.Visible = false
		sequenceFrame.Cells.Visible = true
		task.wait(timeFrame)
		util.PlaySound(soundsFolder.StaticHit)
		sequenceFrame.Cells.Visible = false
		sequenceFrame.Void.Visible = true
		task.wait(timeFrame)
		util.PlaySound(soundsFolder.StaticHit)
		sequenceFrame.Void.Visible = false
		sequenceFrame.Heart.Visible = true
		task.wait(timeFrame)
		sequenceFrame.Heart.Visible = false
	end

	uiAnimationService.StopAnimation(sequenceFrame.Heart)
	uiAnimationService.StopAnimation(sequenceFrame.Cells)
	uiAnimationService.StopAnimation(sequenceFrame.Void)

	sequenceFrame.ScreenText.Visible = true

	playPingSound()
	changePropertyForTable(sequenceFrame.ScreenText:GetChildren(), { Text = "I won't let you go." })
	task.wait(3)
	util.PlaySound(soundsFolder.StaticHit)
	changePropertyForTable(sequenceFrame.ScreenText:GetChildren(), { Text = "Child." })
	task.wait(0.05)
	changePropertyForTable(sequenceFrame.ScreenText:GetChildren(), { Text = "I won't let you go." })

	task.wait(1.5)
	util.PlaySound(soundsFolder.GlitchSound_Light, 0.2)
	task.wait(0.5)
	sequenceFrame.Glitch2.Visible = true
	uiAnimationService.PlayAnimation(sequenceFrame.Glitch2, 0.05)
	task.wait(0.25)
	sequenceFrame.Glitch2.Visible = false
	sequenceFrame.ScreenText.Visible = false

	sequenceFrame.SecondFrame.Visible = true
	eyeFrame.Visible = true

	background.Visible = true
	smudge.Visible = true

	sequenceFrame.SecondFrame.Image.Position = UDim2.new(-1, 0)
	eyeFrame.Image.Position = UDim2.new(-1, 0)

	task.wait(0.2)

	sequenceFrame.SecondFrame.Image.Position = UDim2.new(-2, 0)
	eyeFrame.Image.Position = UDim2.new(-2, 0)

	task.wait(3)

	util.PlaySound(sequenceSounds.Breath)
	util.PlaySound(sequenceSounds.Cloth).PlaybackSpeed = 0.7

	util.tween(UI.Fade, ti_1, { BackgroundTransparency = 0 }, false, function()
		step:Disconnect()
		sequenceFrame:Destroy()
		hideBars()
		util.tween(UI.Fade, ti, { BackgroundTransparency = 1 })

		globalInputService.actionGroups["PlayerControl"]:Enable("Sequence")
	end)

	for i = -2, 0, 1 do
		sequenceFrame.SecondFrame.Image.Position = UDim2.new(i, 0)
		eyeFrame.Image.Position = UDim2.new(i, 0)
		task.wait(0.25)
	end
end

function module.keyhole(object: Model)
	object:RemoveTag("Interactable")

	local fade = UI.Fade
	local ti = TweenInfo.new(1, Enum.EasingStyle.Linear)

	local sequenceFrame = loadSequence("Keyhole")
	local frame = sequenceFrame.Frame

	musicService:PlayTrack("Limitless", 1)

	util.tween(fade, ti, { BackgroundTransparency = 0 }, true)

	util.tween(fade, ti, { BackgroundTransparency = 1 })

	sequenceFrame.Visible = true
	uiAnimationService.PlayAnimation(frame.Static, 0.5, true)

	globalInputService.actionGroups["PlayerControl"]:Disable("Sequence")

	task.wait(4)
	uiAnimationService.PlayAnimation(frame.Entity, 1, false, true).OnEnded:Wait()

	task.wait(0.5)

	sequenceFrame:Destroy()
	fade.BackgroundTransparency = 0
	util.tween(fade, ti, { BackgroundTransparency = 1 })

	scales.activeScales["InteractDisabled"]:Remove("InSequence")
	globalInputService.actionGroups["PlayerControl"]:Enable("Sequence")

	musicService:PlayTrack("ItsPlaytime")
	musicService:PlayTrack("SuddenDeath")

	for i = 0.25, 1.25, 0.25 do
		task.wait(1.25)
		util.PlayFrom(player.Character, sequenceSounds.MetalBang, 0.25).Volume = i
	end

	task.wait(1)
	object.Door:Destroy()
	object:SetAttribute("Used", true)
	util.PlayFrom(player.Character, sequenceSounds.MetalBreak)
end

function module.noMercy()
	musicService:StopTrack()

	local sequenceFrame = loadSequence("NoMercy")
	local textFrame = sequenceFrame.Text

	local ti_0 = TweenInfo.new(6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local ti_1 = TweenInfo.new(8, Enum.EasingStyle.Linear)
	local ti_2 = TweenInfo.new(1, Enum.EasingStyle.Linear)

	sequenceSounds.Distortion_0.Volume = 1.5

	task.wait(3)

	util.PlaySound(sequenceSounds.Distortion_0, 0, 0.1)
	sequenceFrame.Visible = true
	task.wait(0.1)
	sequenceFrame.Visible = false

	task.wait(2)

	util.PlaySound(sequenceSounds.Distortion_0, 0, 0.1)
	sequenceFrame.Visible = true
	task.wait(0.1)
	sequenceFrame.Visible = false

	task.wait(1)

	util.PlaySound(sequenceSounds.Distortion_0, 0, 0.1)
	sequenceFrame.Visible = true
	task.wait(0.1)
	sequenceFrame.Visible = false

	task.wait(0.25)
	util.PlaySound(sequenceSounds.Distortion_0, 0, 0.1)
	sequenceFrame.Visible = true
	task.wait(0.1)
	sequenceFrame.Visible = false
	task.wait(0.25)

	sequenceSounds.Distortion_0.Volume = 0.5

	sequenceSounds.Distortion_0:Play()

	sequenceSounds.Ambience_0.Volume = 0
	sequenceSounds.Ambience_0:Play()

	sequenceFrame.Visible = true

	globalInputService.actionGroups["PlayerControl"]:Disable("Sequence")

	util.tween(sequenceSounds.Ambience_0, ti_1, { Volume = 1 })

	task.wait(2)

	task.spawn(function()
		local i = 2

		while sequenceFrame and sequenceFrame.Parent do
			sequenceFrame.Hands.Image.Position = UDim2.fromOffset(math.random(-2, 2), math.random(-2, 2))
			sequenceFrame.RedX.Position = UDim2.fromOffset(i, 0)
			sequenceFrame.RedPlus.Position = UDim2.fromOffset(i, 0)
			i *= -1

			task.wait(0.025)
		end
	end)

	util.tween(sequenceFrame.Hands, ti_0, { Position = UDim2.fromScale(0, 1) })

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

	sequenceSounds.Exit:Play()
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

	globalInputService.actionGroups["PlayerControl"]:Enable("Sequence")

	task.delay(0.5, function()
		util.tween(UI.Fade, ti_2, { BackgroundTransparency = 1 })
	end)

	sequenceSounds.Distortion_0:Stop()
	sequenceSounds.Ambience_0:Stop()

	musicService:ReturnToLastTrack()
end

local deathDialogue = {
	{
		"You feel your bones crush.",
		"I feel my bones crush.",
	},

	{
		"You watch your flesh tear.",
		"I watch my flesh tear.",
	},

	{
		"You regret this.",
		"I regret this.",
	},

	{
		"Maybe this time",
		"I'll know.",
	},

	{
		"Do you see it now?",
		"Not yet.",
	},

	{
		"You see your light fade.",
		"I see my light fade.",
	},

	{
		"Let him go.",
		"Let him go.",
	},

	{
		"Your mind begins to fade",
		"My mind begins to fade",
	},
}

local function Lerp(num, goal, i)
	return num + (goal - num) * i
end

local function deathScreenUi()
	local sequenceFrame = loadSequence("DeathScreen")
	sequenceFrame.Background.Visible = false
	sequenceFrame.ScreenText.Visible = false
	sequenceFrame.Visible = true

	uiAnimationService.PlayAnimation(sequenceFrame.Glitch, 0.04, true)
	ContentProvider:PreloadAsync { sequenceFrame.Eye.Image }

	local start = os.clock()
	local startFov = camera.FieldOfView

	local step = RunService.RenderStepped:Connect(function()
		for _, child in ipairs(sequenceFrame.ScreenText:GetChildren()) do
			if child.Name == "Main" then
				child.Position = UDim2.fromOffset(math.random(-1, 1), math.random(-1, 1))
				continue
			end

			child.Position = UDim2.fromOffset(math.random(-10, 10), math.random(-10, 10))
		end

		sequenceFrame.Vax.Position = UDim2.new(0.5, math.random(-2, 2), 0.5, math.random(-2, 2))

		camera.FieldOfView = Lerp(startFov, startFov + 2, (os.clock() - start) / 20)
	end)

	local dialogue = deathDialogue[math.random(1, #deathDialogue)]

	task.wait(3.5)

	local playerTalking = false
	for _, text in ipairs(dialogue) do
		changePropertyForTable(
			sequenceFrame.ScreenText:GetChildren(),
			{ TextColor3 = playerTalking and Color3.fromRGB(207, 142, 141) or Color3.new(1), Text = text }
		)

		playerTalking = not playerTalking
		task.wait(2)

		sequenceFrame.Background.Visible = true
		sequenceFrame.ScreenText.Visible = true

		task.wait(1)

		sequenceFrame.Background.Visible = false
		sequenceFrame.ScreenText.Visible = false
	end

	task.wait(2)

	changePropertyForTable(sequenceFrame.ScreenText:GetChildren(), { TextColor3 = Color3.new(1), Text = "Witness" })

	util.PlaySound(soundsFolder.Death.Hit, 0.075)
	sequenceFrame.Background.Visible = true
	sequenceFrame.ScreenText.Visible = true

	task.wait(1.25)
	sequenceFrame.ScreenText.Visible = false

	changePropertyForTable(sequenceFrame.ScreenText:GetChildren(), { Text = "Eternity" })

	sequenceFrame.Eye.Visible = true
	local animation = uiAnimationService.PlayAnimation(sequenceFrame.Eye, 0.1)

	animation:OnFrameReached(8):Once(function()
		animation:Pause()
		sequenceFrame.ScreenText.Visible = true
		sequenceFrame.Eye.Visible = false
		task.wait(1.25)
		sequenceFrame.ScreenText.Visible = false
		sequenceFrame.Eye.Visible = true
		animation:Resume()
	end)

	animation.OnEnded:Once(function()
		sequenceFrame.Eye.Visible = false
		sequenceFrame.Vax.Visible = true
		task.wait(1.5)
		uiAnimationService.PlayAnimation(sequenceFrame.Vax, 0.04, false, true).OnEnded:Wait()
		sequenceFrame.Vax.Visible = false
		--task.wait(1)
		--sequenceFrame.Visible = false

		step:Disconnect()
	end)
end

function module.deathScreen()
	task.wait(0.1)
	task.spawn(deathScreenUi)

	local snds = soundsFolder.Death
	local ti = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 14)
	local ti_2 = TweenInfo.new(4, Enum.EasingStyle.Linear)
	local ti_3 = TweenInfo.new(0.25)

	musicService:PlayTrack("Silence")
	util.tween(soundsFolder.Heartbeat, TweenInfo.new(0.1), { Volume = 0 })

	util.PlaySound(snds.Event)
	local static = util.PlaySound(snds.Static)
	util.tween(static, ti, { Volume = 0.05 })

	task.wait(1)

	util.PlaySound(snds.SpawnAmb)
	util.tween(util.PlaySound(snds.EtherialVoices), ti, { Volume = 0 })

	task.wait(10)

	local corde = util.PlaySound(snds.Corde)
	corde.Volume = 0
	local breath = util.PlaySound(snds.Breathing)
	breath.Volume = 0

	util.tween(corde, ti_2, { Volume = 0.5 })
	util.tween(breath, ti_2, { Volume = 0.5 })

	task.wait(9)
	util.tween(static, ti_2, { Volume = 0 })
	util.tween(corde, ti_3, { Volume = 0 })
	util.tween(breath, ti_3, { Volume = 0 })
end

return module
