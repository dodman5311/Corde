local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local rng = Random.new()

local client = script.Parent
local acts = require(client.Acts)
local animationService = require(client.UIAnimationService)
local util = require(client.Util)
local playerService = require(client.Player)
local bloodEffects = require(client.BloodEffects)

local assets = ReplicatedStorage.Assets
local sounds = assets.Sounds
local models = assets.Models
export type Npc = {
	Name: string,
	Instance: Instance,
	Personality: {},
	MindData: {}, -- extra data the npc might need
	MindState: StringValue,
	MindTarget: ObjectValue,

	Heartbeat: {},

	Timer: { new: (self: any) -> nil }?,
	Timers: {},
	Acts: {},
	Janitor: any,
	OnDied: any?,

	Spawn: (Npc: Npc, Position: Vector3 | CFrame) -> Instance,

	IsState: (Npc: Npc, State: string) -> boolean,
	GetState: (Npc: Npc) -> string,
	GetTarget: (Npc: Npc) -> any?,
	GetTimer: (Npc: Npc, TimerName: string) -> {},

	Exists: (Npc: Npc) -> boolean,

	Destroy: (Npc: Npc) -> nil,
	Place: (Npc: Npc, Position: Vector3 | CFrame) -> Instance,
	Run: (Npc: Npc) -> nil,
	LoadPersonality: (Npc: Npc) -> nil,
}

local module = {
	npcs = {},
}
local function checkSightLine(npc, target, maxSightAngle)
	if not target then
		return
	end
	local rp = RaycastParams.new()

	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { workspace.Map }

	local npcCFrame = npc.Instance:GetPivot()
	local targetCFrame = target:GetPivot()

	local position = npcCFrame.Position
	local targetPosition = targetCFrame.Position

	if not maxSightAngle then
		return not workspace:Raycast(position, targetPosition - position, rp)
	end

	local npcDirection = npcCFrame.LookVector
	local targetDirection = CFrame.lookAt(position, targetPosition).LookVector

	local directionDifference = (targetDirection - npcDirection).Magnitude

	if directionDifference >= (maxSightAngle / 180) * 2 then
		return
	end

	return not workspace:Raycast(position, targetPosition - position, rp)
end

local function checkEarshot(npc, distance)
	for sound: Sound, object in pairs(util.PlayingSounds) do
		if distance <= sound.RollOffMaxDistance and object and checkSightLine(npc, object, 400) then
			return object
		end
	end
end

local function getObject(class, parent)
	local foundInstance = parent:FindFirstChildOfClass(class)
	if not foundInstance then
		foundInstance = Instance.new(class)
		foundInstance.Parent = parent
		return foundInstance, true
	end

	return foundInstance, false
end

local function lookAtPostition(npc: Npc, position: Vector3, doLerp: boolean, lerpAlpha: number)
	-- if npc.MindData["CantMove"] then
	-- 	return
	-- end

	local subject = npc.Instance
	local subjectPos = subject:GetPivot().Position
	local newVector = Vector3.new(position.X, subjectPos.Y, position.Z)

	local goal = CFrame.lookAt(subjectPos, newVector)

	local Align, isNew = getObject("AlignOrientation", subject.PrimaryPart)
	Align.Mode = Enum.OrientationAlignmentMode.OneAttachment
	Align.RigidityEnabled = true
	Align.AlignType = Enum.AlignType.Parallel

	if isNew then
		Align.CFrame = subject:GetPivot()
	end

	Align.Attachment0 = getObject("Attachment", subject.PrimaryPart)

	if doLerp then
		Align.CFrame = Align.CFrame:Lerp(goal, lerpAlpha)
	else
		Align.CFrame = goal
	end
end

local function createDamageHitbox(npc: Npc, size: Vector2, damage: number, damageType)
	local npcCFrame = npc.Instance:GetPivot()
	local newHitbox = workspace:GetPartBoundsInBox(
		npcCFrame * CFrame.new(0, 0, (-npc.Instance.PrimaryPart.Size.Z / 2) + (-size.Y / 2)),
		Vector3.new(size.X, 1, size.Y)
	)

	for _, part in ipairs(newHitbox) do
		local model = part:FindFirstAncestorOfClass("Model")
		if not model then
			continue
		end

		if model == Players.LocalPlayer.Character then
			playerService:DamagePlayer(damage, damageType)

			bloodEffects.createSplatter(model:GetPivot())

			bloodEffects.bloodSploof(npcCFrame, model:GetPivot().Position)
			break
		end
	end
end

local function doAction(npc, action, ...)
	local result = module.actions[action.Function](npc, ...)
	if not action.ReturnAction then
		return
	end

	module.actions[action.ReturnAction.Function](npc, table.unpack(action.ReturnAction.Parameters), result)
end

function module.doActions(npc, actions, ...)
	if npc:IsState("Dead") then
		return
	end

	for _, action in ipairs(actions) do
		if action.State and not npc:IsState(action.State) then
			continue
		end

		if action.NotState and npc:IsState(action.NotState) then
			continue
		end

		if not module.actions[action.Function] then
			warn("There is no NPC action by the name of ", action.Function)
			continue
		end

		local parameters = {}

		if action.Parameters then
			for _, parameter in ipairs(action.Parameters) do
				if typeof(parameter) == "table" and parameter["Min"] and parameter["Max"] then
					parameter = rng:NextNumber(parameter["Min"], parameter["Max"])
				end

				table.insert(parameters, parameter)
			end
		end

		if not action["IgnoreEventParams"] then
			for _, parameter in ipairs({ ... }) do
				table.insert(parameters, parameter)
			end
		end

		doAction(npc, action, table.unpack(parameters))
	end
end

module.events = {
	OnStep = function(npc: Npc, actions)
		npc.Heartbeat["OnStep"] = function()
			module.doActions(npc, actions)
		end
	end,

	OnMoved = function(npc: Npc, actions)
		local lastVelocity = Vector3.zero
		npc.Heartbeat["OnMoved"] = function()
			local velocity = npc.Instance.PrimaryPart.AssemblyLinearVelocity

			if velocity ~= lastVelocity and velocity.Magnitude >= 0.05 then
				module.doActions(npc, actions)
			end

			lastVelocity = velocity
		end
	end,

	OnStopped = function(npc: Npc, actions)
		local lastVelocity = Vector3.zero
		npc.Heartbeat["OnStopped"] = function()
			local velocity = npc.Instance.PrimaryPart.AssemblyLinearVelocity

			if velocity ~= lastVelocity and velocity.Magnitude < 0.05 then
				module.doActions(npc, actions)
			end

			lastVelocity = velocity
		end
	end,

	Start = function(npc: Npc, actions)
		module.doActions(npc, actions)
	end,

	OnDeath = function(npc: Npc, actions)
		return npc.Instance:GetAttributeChangedSignal("Health"):Connect(function()
			if npc.Instance:GetAttribute("Health") > 0 then
				return
			end

			module.doActions(npc, actions)
		end)
	end,

	OnTargetFound = function(npc: Npc, actions)
		return npc.MindTarget.Changed:Connect(function(value)
			if not value then
				return
			end
			module.doActions(npc, actions)
		end)
	end,

	OnTargetLost = function(npc: Npc, actions)
		return npc.MindTarget.Changed:Connect(function(value)
			if value then
				return
			end
			module.doActions(npc, actions)
		end)
	end,

	InCloseRange = function(npc: Npc, actions, targetDistance)
		npc.Heartbeat["CheckCloseRange"] = function()
			local target = npc:GetTarget()
			if not target then
				return
			end

			targetDistance = targetDistance or 1
			local distance = (npc.Instance:GetPivot().Position - target:GetPivot().Position).Magnitude

			if distance > targetDistance then
				return
			end

			module.doActions(npc, actions)
		end
	end,

	OnStateChanged = function(npc: Npc, actions)
		return npc.MindState.Changed:Connect(function()
			module.doActions(npc, actions)
		end)
	end,
}

module.actions = {
	SwitchToState = function(npc: Npc, state: string)
		npc.MindState.Value = state
	end,

	PlayAnimation = function(npc: Npc, animaitonName: string, frameDelay, loop, stayOnLastFrame, startOnFrame)
		local animationFrame = npc.Instance:FindFirstChild(animaitonName, true)

		for _, frame in ipairs(animationFrame.Parent:GetChildren()) do
			if not frame:IsA("Frame") or frame == animationFrame then
				continue
			end

			frame.Visible = false
			animationService.StopAnimation(frame)
		end

		animationFrame.Visible = true
		return animationService.PlayAnimation(animationFrame, frameDelay, loop, stayOnLastFrame, startOnFrame)
	end,

	SetAnimationPlayback = function(npc: Npc, animaitonName: string, action: string | "Pause" | "Resume")
		local animationFrame = npc.Instance:FindFirstChild(animaitonName, true)
		local animation = animationService.CheckPlaying(animationFrame)
		if not animation then
			return
		end

		animation[action](animation)

		return animation
	end,

	Destroy = function(npc: Npc, delay: number?)
		if delay then
			task.delay(delay, npc.Destroy, npc)
		else
			npc:Destroy()
		end
	end,

	PlaceNpcBody = function(npc: Npc)
		local newBody = models.DeadNpc:Clone()
		newBody.Parent = workspace
		newBody:PivotTo(npc.Instance:GetPivot())

		local body: Part = newBody.Body
		body.AssemblyLinearVelocity = body.CFrame.LookVector * -50

		local deathSoundList
		if npc.Instance:HasTag("Friendly") then
			deathSoundList = sounds[npc.Instance:GetAttribute("Gender") .. "_Death"]
		elseif npc.Instance:FindFirstChild("DeathSounds") then
			deathSoundList = npc.Instance.DeathSounds
		end

		local deathSound = util.getRandomChild(deathSoundList)
		local bloodSound = util.getRandomChild(sounds.Blood)

		util.PlaySound(deathSound, nil, 0.05, 0.2)
		util.PlaySound(bloodSound, nil, 0.15)
	end,

	SearchForTarget = function(npc: Npc, maxDistance: number, maxSightAngle: number?)
		local target = Players.LocalPlayer.Character
		local distance = 0

		if target then
			distance = (target:GetPivot().Position - npc.Instance:GetPivot().Position).Magnitude
		end

		if
			npc:GetState() == "Dead"
			or not target and (distance > maxDistance or not checkSightLine(npc, target, maxSightAngle))
		then
			target = nil
		end

		target = checkEarshot(npc, distance)
		npc.MindTarget.Value = target

		if target ~= nil then
			npc.MindData["LastTarget"] = target
		end

		return target, distance
	end,

	LookAtTarget = function(npc: Npc, doLerp, lerpAlpha)
		local target = npc.MindTarget.Value

		if not target then
			return
		end

		local position = target:GetPivot().Position

		lookAtPostition(npc, position, doLerp, lerpAlpha)
	end,

	ChangeWalkVelocity = function(npc: Npc, goal: Vector3, lerpAlpha: number?)
		if npc.MindData["CantMove"] and goal.Magnitude > 0 then
			return
		end

		local walkVelocity: LinearVelocity = npc.Instance.WalkVelocity
		walkVelocity.VectorVelocity = walkVelocity.VectorVelocity:Lerp(goal, lerpAlpha or 1)
	end,

	MoveTowardsPoint = function(npc: Npc, position: Vector3, lerpAlpha: number?)
		npc.Heartbeat["MovingToPoint"] = function()
			local positionDifference: Vector3 = position - npc.Instance:GetPivot().Position

			if positionDifference.Magnitude <= 0.25 then -- stop when point is reached
				module.actions.ChangeWalkVelocity(npc, Vector3.zero, lerpAlpha)
				npc.Heartbeat["MovingToPoint"] = nil
				return
			end

			local moveUnit: Vector3 = positionDifference.Unit

			module.actions.ChangeWalkVelocity(npc, moveUnit * npc.Instance:GetAttribute("Walkspeed"), lerpAlpha)
		end
	end,

	MoveForwards = function(npc: Npc, lerpAlpha: number?)
		module.actions.ChangeWalkVelocity(
			npc,
			npc.Instance:GetPivot().LookVector * npc.Instance:GetAttribute("Walkspeed"),
			lerpAlpha
		)
	end,

	StopMoving = function(npc: Npc, lerpAlpha: number?)
		module.actions.ChangeWalkVelocity(npc, Vector3.zero, lerpAlpha)
	end,

	MoveTowardsTarget = function(npc: Npc, lerpAlpha: number?)
		local target = npc:GetTarget()
		if not target then
			return
		end

		module.actions.MoveTowardsPoint(npc, target:GetPivot().Position, lerpAlpha)
	end,

	MeleeAttack = function(npc: Npc, damage: number, cooldown: number, damageFrame: number?, stopMotion: boolean?)
		if npc:IsState("Attacking") then
			return
		end
		npc.MindState.Value = "Attacking"
		local attackAnimation = module.actions.PlayAnimation(npc, "Animation_Attack", 0.05, false, true)

		if damageFrame then
			attackAnimation:OnFrameRached(damageFrame):Connect(function()
				createDamageHitbox(npc, Vector2.new(1, 2), damage, "Melee")
			end)
		else
			createDamageHitbox(npc, Vector2.new(1, 2), damage, "Melee")
		end

		if stopMotion then
			npc.MindData["CantMove"] = true
			module.actions.StopMoving(npc)
		end

		task.delay(cooldown, function()
			if npc:IsState("Attacking") then
				module.actions.SwitchToState(npc, "Chasing")
			end

			if stopMotion then
				npc.MindData["CantMove"] = false
			end
		end)
	end,

	Emit = function(npc: Npc, particleName: string, count: number, useEnable: boolean?)
		local particle: ParticleEmitter = npc.Instance:FindFirstChild(particleName, true)
		if not particle then
			return
		end

		if useEnable then
			particle.Enabled = true
			task.delay(count, function()
				particle.Enabled = false
			end)
		else
			particle:Emit(count)
		end
	end,

	Custom = function(npc: Npc, func, ...)
		local result = func(npc, ...)

		if not result then
			return
		end

		module.doActions(npc, result)
	end,
}

function module.RunNpc(Npc: Npc)
	for eventName, actions in pairs(Npc.Personality) do
		if not module.events[eventName] then
			warn("There is no NPC event by the name of ", eventName)
			continue
		end

		local params
		if actions["Parameters"] then
			params = table.unpack(actions["Parameters"])
		end

		local result = module.events[eventName](Npc, actions, params)
		if not result then
			continue
		end

		Npc.Janitor:Add(result, "Disconnect")
	end
end

RunService.Heartbeat:Connect(function()
	if acts:checkAct("Paused") then
		return
	end

	local inCombat = false

	for _, npc: Npc in ipairs(module.npcs) do
		if npc:IsState("Dead") then
			continue
		end

		for _, heartbeatFunction in pairs(npc.Heartbeat) do
			heartbeatFunction()
		end

		if npc:GetTarget() == Players.LocalPlayer.Character then
			inCombat = true
		end
	end

	workspace:SetAttribute("InCombat", inCombat)
end)

return module
