local module = {}
--// Services
local REPLICATED_STORAGE = game:GetService("ReplicatedStorage")

--// Instances
local assets = REPLICATED_STORAGE.Assets

local goreEffects = assets.GoreEffects

local map = workspace.Map

--// Modules
local util = require(script.Parent.Util)

--// Values

-- MAKE REMOVE BASED ON PART COUNT
local rng = Random.new()

function module.createSplatter(cframe)
	local splatterTime = 120

	local getSplatter = util.callFromCache(util.getRandomChild(goreEffects.FloorSplatter))
	util.addToCache(getSplatter, splatterTime)

	getSplatter.Parent = map
	getSplatter.Size = Vector3.new(rng:NextNumber(5, 6.4), 0.001, rng:NextNumber(6, 7)) * 2.5
	getSplatter.CFrame = cframe * CFrame.new(0, 0, getSplatter.Size.Z / 2) * CFrame.Angles(0, math.rad(180), 0)
end

function module.bloodSploof(cframe, pos)
	local newBloodEffect = util.callFromCache(goreEffects.BloodPuff)
	newBloodEffect.Parent = workspace
	newBloodEffect.CFrame = cframe
	newBloodEffect.Position = pos
	util.addToCache(newBloodEffect, 2)

	for _, particle in ipairs(newBloodEffect:GetChildren()) do
		particle.Enabled = true
		task.delay(0.075, function()
			particle.Enabled = false
		end)
	end
end

return module
