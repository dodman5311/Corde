local ReplicatedStorage = game:GetService("ReplicatedStorage")
local client = script.Parent
local util = require(client.Util)

local assets = ReplicatedStorage.Assets

local objectFunctions = {
	Door = function(object: Model)
		local ti = TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
		local door = object.Door

		object:RemoveTag("Interactable")
		object:RemoveTag("Hackable")

		util.PlaySound(assets.Sounds.QuickOpen)
		task.wait(0.5)
		util.tween(door, ti, { CFrame = door.CFrame * CFrame.new(0, 0, -door.Size.Z) })
	end,

	LargeDoubleDoor = function(object: Model)
		local ti = TweenInfo.new(2.15, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
		local leftDoor = object.LeftDoor
		local rightDoor = object.RightDoor

		object:RemoveTag("Interactable")
		object:RemoveTag("Hackable")

		util.PlaySound(assets.Sounds.DoorsOpening)
		task.wait(1.1)
		util.PlaySound(assets.Sounds.Open)
		object.LeftEmit.ParticleEmitter.Enabled = true
		object.RightEmit.ParticleEmitter.Enabled = true

		task.wait(1)

		util.tween(leftDoor, ti, { CFrame = leftDoor.CFrame * CFrame.new(0, 0, -leftDoor.Size.Z) })
		util.tween(rightDoor, ti, { CFrame = rightDoor.CFrame * CFrame.new(0, 0, -rightDoor.Size.Z) })

		task.wait(1.5)
		object.LeftEmit.ParticleEmitter.Enabled = false
		object.RightEmit.ParticleEmitter.Enabled = false
	end,

	Catwalk = function(object: Model)
		local ti = TweenInfo.new(7, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
		local platform = object.Platform

		object:RemoveTag("Interactable")
		object:RemoveTag("Hackable")

		object.Off.Transparency = 1
		object.On.Transparency = 0

		util.PlaySound(assets.Sounds.Platform)
		task.wait(0.5)

		util.tween(platform, ti, { CFrame = platform.CFrame * CFrame.new(0, 0, platform.Size.Z) }, true)
		object.Hitbox:Destroy()
	end,
}

return objectFunctions
