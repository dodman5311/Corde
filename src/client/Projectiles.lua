local module = {}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local collectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--// Instances

--// Modules
local util = require(script.Parent.Util)
local signal = require(script.Parent.signal)

--// Values
local Projectiles = {}
local isPaused = false
module.projectileHit = signal.new()

export type Projectile = {
	["Instance"]: Instance,
	["Speed"]: number,
	["LifeTime"]: number,
	["Age"]: number,
	["Info"]: table,
	["Damage"]: number,
}

module.Presets = {
	Bullet = {
		Speed = 200,
		LifeTime = 5,
		Info = {},
		Damage = 1,
	},
}

--// Functions
local function checkPlayer(subject)
	if not subject then
		return
	end
	local model = subject

	if not subject:IsA("Model") then
		model = subject:FindFirstAncestorOfClass("Model")
	end

	if not model then
		return
	end

	if not Players:GetPlayerFromCharacter(model) then
		return
	end

	return model
end

function module.createFromPreset(cframe, spread, presetName, DamageOverride, infoAddition)
	local getPreset = module.Presets[presetName]
	if not getPreset then
		warn("There is no such projectile preset by the name of: ", presetName)
		return
	end

	local damage = DamageOverride or getPreset.Damage
	local info = table.clone(getPreset.Info)

	if infoAddition then
		for i, v in pairs(infoAddition) do
			info[i] = v
		end
	end

	return module.createProjectile(
		getPreset.Speed,
		cframe,
		spread,
		damage,
		getPreset.LifeTime,
		info,
		getPreset.Model
	)
end

function module.createProjectile(speed, cframe, spread, dmg, LifeTime, extraInfo, sender, model)
	local offset = CFrame.Angles(0, util.randomAngle(spread), 0)

	local newInstance = model and ReplicatedStorage:FindFirstChild(model):Clone() or ReplicatedStorage.Projectile:Clone()
	newInstance.Parent = workspace
	newInstance.CFrame = cframe * offset

	local newProjectile = {
		Instance = newInstance,
		Speed = speed,
		LifeTime = LifeTime or 5,
		Age = 0,
		Sender = sender,
		Info = extraInfo or {},
		Damage = dmg or 1,
	}

	table.insert(Projectiles, newProjectile)
	return newProjectile
end

local function checkRaycast(projectile, raycastDistance)
	if raycastDistance > 1000 then
		return { Instance = nil }
	end

	local cframe = projectile.Instance.CFrame

	local rp = RaycastParams.new()
	rp.CollisionGroup = "Bullet"

	local newRaycast

	local size = projectile.Info["Size"]

	if size == 0 then
		newRaycast = workspace:Raycast(cframe.Position, cframe.LookVector * raycastDistance, rp)
	else
		newRaycast = workspace:Spherecast(cframe.Position, size or 0.25, cframe.LookVector * raycastDistance, rp)
	end

	return newRaycast
end

local function fireBeam(npc, damage, cframe, distance, spread)
	local offset = CFrame.Angles(0, util.randomAngle(spread), 0)
	cframe *= offset

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { npc }
	raycastParams.CollisionGroup = "NpcBullet"

	local raycast = workspace:Spherecast(cframe.Position, 0.35, cframe.LookVector * distance, raycastParams)

	if not raycast then
		return
	end

end

--// Main //--

local lastRenderStep = os.clock()

local function removeProjectileInstance(projectile)
	projectile.Instance.Transparency = 1

	for _, effect in ipairs(projectile.Instance:GetChildren()) do
		if not (effect:IsA("PointLight") or effect:IsA("ParticleEmitter") or effect:IsA("Trail")) then
			continue
		end

		effect.Enabled = false
	end

	task.delay(projectile.Instance:GetAttribute("RemoveDelay") or 0, function()
		projectile.Instance:Destroy()
	end)
end

local function createWallHitEffect(rayResult)
	
	local newHitEffect = util.callFromCache(ReplicatedStorage.WallHit)
	util.addToCache(newHitEffect, 0.6)

	newHitEffect.Parent = workspace
	newHitEffect.CFrame = CFrame.new(rayResult.Position, rayResult.Position + rayResult.Normal)
	newHitEffect.CFrame *= CFrame.Angles(0,math.rad(-180),0)

	newHitEffect.Particle:Emit(6)
	
	return newHitEffect
end

function module.projectileHit(raycast, projectile)
	if not raycast then
		return
	end

	local model = raycast.Instance:FindFirstAncestorOfClass("Model")
	if model then
		local health = model:GetAttribute("Health")

		if health then
			model:SetAttribute("Health", health - projectile.Damage)
		else
			createWallHitEffect(raycast)	
		end
	else
		createWallHitEffect(raycast)
	end
	
	projectile.ToBeRemoved = true
end

RunService.Heartbeat:Connect(function()

	for _, projectile: Projectile in ipairs(Projectiles) do
		if projectile.Age >= projectile.LifeTime then
			projectile.Instance:Destroy()
			table.remove(Projectiles, table.find(Projectiles, projectile))
			continue
		end

		local timePassed = os.clock() - lastRenderStep
		projectile.Age += timePassed

		local distanceToMove = timePassed * projectile.Speed

        if projectile["ToBeRemoved"] then
            removeProjectileInstance(projectile)
            table.remove(Projectiles, table.find(Projectiles, projectile))
            continue
        end

		local raycast = checkRaycast(projectile, distanceToMove)

		projectile.Instance.CFrame *= CFrame.new(0, 0, -(distanceToMove))

		module.projectileHit(raycast, projectile)
	end

	lastRenderStep = os.clock()
end)

return module