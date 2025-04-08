local ReplicatedStorage = game:GetService("ReplicatedStorage")
local client = script.Parent
local util = require(client.Util)
local sequences = require(client.Sequences)

local assets = ReplicatedStorage.Assets

local objectFunctions = {
	Door = function(object: Model, instant: boolean?)
		local ti = TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut, 0, false, 0.5)
		local door = object.Door

		object:RemoveTag("Interactable")
		object:RemoveTag("Hackable")

		if instant then
			ti = TweenInfo.new(0)
		else
			util.PlaySound(assets.Sounds.QuickOpen, object)
		end

		util.tween(door, ti, { CFrame = door.CFrame * CFrame.new(0, 0, -door.Size.Z) }, true)
		object:SetAttribute("Used", true)
	end,

	LargeDoubleDoor = function(object: Model, instant: boolean?)
		local ti = TweenInfo.new(2.15, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
		local leftDoor = object.LeftDoor
		local rightDoor = object.RightDoor

		object:RemoveTag("Interactable")
		object:RemoveTag("Hackable")

		if instant then
			ti = TweenInfo.new(0)
		else
			util.PlaySound(assets.Sounds.DoorsOpening, object)
			task.wait(1.1)
			util.PlaySound(assets.Sounds.Open, object)
			object.LeftEmit.ParticleEmitter.Enabled = true
			object.RightEmit.ParticleEmitter.Enabled = true

			task.wait(1)
		end

		util.tween(leftDoor, ti, { CFrame = leftDoor.CFrame * CFrame.new(0, 0, -leftDoor.Size.Z) })
		util.tween(rightDoor, ti, { CFrame = rightDoor.CFrame * CFrame.new(0, 0, -rightDoor.Size.Z) })

		task.wait(1.5)
		object.LeftEmit.ParticleEmitter.Enabled = false
		object.RightEmit.ParticleEmitter.Enabled = false

		object:SetAttribute("Used", true)
	end,

	PlaySequence = function(object: Model)
		object:RemoveTag("Interactable")

		local sequenceIndex = object:GetAttribute("SequenceIndex")
		sequences:beginSequence(sequenceIndex)
	end,

	Catwalk = function(object: Model, instant: boolean?)
		local ti = TweenInfo.new(7, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
		local platform = object.Platform

		object:RemoveTag("Interactable")
		object:RemoveTag("Hackable")

		object.Off.Transparency = 1
		object.On.Transparency = 0

		if instant then
			ti = TweenInfo.new(0)
		else
			util.PlaySound(assets.Sounds.Platform, object)
			task.wait(0.5)
		end

		util.tween(platform, ti, { CFrame = platform.CFrame * CFrame.new(0, 0, platform.Size.Z) }, true)
		object.Hitbox:Destroy()

		object:SetAttribute("Used", true)
	end,

	BigDoor = function(object: Model, instant: boolean?)
		local door = object.BigDoor

		local ti = TweenInfo.new(12, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
		local leftDoor = door.LeftDoor
		local rightDoor = door.RightDoor

		object:RemoveTag("Interactable")

		if instant then
			ti = TweenInfo.new(0)
		else
			util.PlaySound(assets.Sounds.MassiveDoor, object)
			task.wait(1.5)
			util.PlaySound(assets.Sounds.HydrolicMovement, object, 0, 10)
		end

		util.tween(leftDoor, ti, { CFrame = leftDoor.CFrame * CFrame.new(0, 0, leftDoor.Size.Z) })
		util.tween(rightDoor, ti, { CFrame = rightDoor.CFrame * CFrame.new(0, 0, rightDoor.Size.Z) })

		object:SetAttribute("Used", true)
	end,
}

return objectFunctions
