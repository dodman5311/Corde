local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local rng = Random.new()

local client = script.Parent
local acts = require(client.Acts)
local animationService = require(client.UIAnimationService)
local util = require(client.Util)

local assets = ReplicatedStorage.Assets
local sounds = assets.Sounds
local models = assets.Models
export type Npc = {
	Name: string,
	Instance: Instance,
	Personality: {},
	MindData: {}, -- extra data the npc might need
	MindState: string,
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

local function checkSightLine(npc, target)
	local rp = RaycastParams.new()

	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { workspace.Map }

	local npcCFrame = npc.Instance:GetPivot()
	local targetCFrame = target:GetPivot()

	local position = npcCFrame.Position
	local targetPosition = targetCFrame.Position

	local npcDirection = npcCFrame.LookVector
	local targetDirection = CFrame.lookAt(position, targetPosition).LookVector

	local directionDifference = (npcDirection - targetDirection).Magnitude

	if directionDifference >= 0.5 then
		return
	end

	return not workspace:Raycast(position, targetPosition - position, rp)
end

local function getObject(class, parent)
	local foundInstance = parent:FindFirstChildOfClass(class)
	if not foundInstance then
		foundInstance = Instance.new(class)
		foundInstance.Parent = parent
	end
	return foundInstance
end

local function lookAtPostition(npc, position: Vector3, doLerp: boolean, lerpAlpha: number)
	local subject = npc.Instance
	local subjectPos = subject:GetPivot().Position
	local newVector = Vector3.new(position.X, subjectPos.Y, position.Z)

	local goal = CFrame.lookAt(subjectPos, newVector)

	local Align = getObject("AlignOrientation", subject.PrimaryPart)
	Align.Mode = Enum.OrientationAlignmentMode.OneAttachment
	Align.RigidityEnabled = true
	Align.AlignType = Enum.AlignType.Parallel

	Align.Attachment0 = getObject("Attachment", subject.PrimaryPart)

	if doLerp then
		Align.CFrame = Align.CFrame:Lerp(goal, lerpAlpha)
	else
		Align.CFrame = goal
	end
end

local function doAction(npc, action, ...)
	local result = module.actions[action.Function](npc, ...)
	if not action.ReturnEvent then
		return
	end

	module.actions[action.ReturnEvent](npc, npc.Behavior[action.ReturnEvent], result)
end

function module.doActions(npc, actions, ...)
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

		task.spawn(doAction, npc, action, table.unpack(parameters))
	end
end

module.events = {
	OnStep = function(npc: Npc, actions)
		npc.Heartbeat["OnStep"] = function()
			module.doActions(npc, actions)
		end

		return npc.Heartbeat["OnStep"]
	end,

	OnMoved = function(npc: Npc, actions)
		npc.Heartbeat["OnMoved"] = function()
			module.doActions(npc, actions)
		end

		return npc.Heartbeat["OnMoved"]
	end,

	OnSpawn = function(npc: Npc, actions)
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
}

module.actions = {
	PlayAnimation = function(npc: Npc, animaitonName: string, ...)
		local animationFrame = npc.Instance:FindFirstChild(animaitonName, true)

		for _, frame in ipairs(animationFrame.Parent:GetChildren()) do
			if frame:IsA("Frame") or frame == animationFrame then
				continue
			end

			frame.Visible = false
			animationService.StopAnimation(frame)
		end

		animationFrame.Visible = true
		return animationService.PlayAnimation(animationFrame, ...)
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

	Destroy = function(npc: Npc)
		npc:Destroy()
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

		util.PlaySound(deathSound, script, 0.05, 0.2)
		util.PlaySound(bloodSound, script, 0.15)
	end,

	SearchForTarget = function(npc: Npc, maxDistance: number)
		local target = Players.LocalPlayer.Character
		local distance = 0

		if target then
			distance = (target:GetPivot().Position - npc.Instance:GetPivot().Position).Magnitude
		end

		if not target or not checkSightLine(npc, target) or distance > maxDistance then
			target = nil
		end

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

	Custom = function(npc: Npc, func, ...)
		local result = func(...)

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

	--for i,v in ipairs()
end)

return module
