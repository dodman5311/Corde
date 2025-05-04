local ReplicatedStorage = game:GetService("ReplicatedStorage")

local client = script.Parent
local personalities = client.NpcPersonalities
local timer = require(client.Timer)
local janitor = require(ReplicatedStorage.Packages.Janitor)
local acts = require(client.Acts)
local npcFunctions = require(client.NpcFunctions)
local signal = require(ReplicatedStorage.Packages.Signal)
local simplePath = require(ReplicatedStorage.Packages.SimplePath)
local Types = require(ReplicatedStorage.Shared.Types)

type Npc = Types.Npc

local NpcService = {}

--// Values

function NpcService.new(npcName: string): Npc
	local npcModel = ReplicatedStorage.Assets.Npcs:FindFirstChild(npcName, true)
	if not npcModel then
		warn(`No NPC model by the name of {npcName} was found.`)
		return
	end

	local newNpcModel = npcModel:Clone()
	local targetValue = Instance.new("ObjectValue")
	targetValue.Parent = newNpcModel
	targetValue.Name = "Target"
	local stateValue = Instance.new("StringValue")
	stateValue.Parent = newNpcModel
	stateValue.Name = "State"

	local Npc: Npc = {
		Name = npcName,
		Instance = newNpcModel,
		Personality = require(personalities:FindFirstChild(npcName)),
		MindData = {},
		MindState = stateValue,
		MindTarget = targetValue,

		Heartbeat = {},

		Path = simplePath.new(newNpcModel),
		Timer = timer:newQueue(),
		Timers = {},
		Acts = acts:new(),
		Janitor = janitor.new(),

		OnDied = signal.new(),

		IsState = function(self: Npc, state: string)
			return self.MindState.Value == state
		end,

		GetState = function(self: Npc)
			return self.MindState.Value
		end,

		GetTarget = function(self: Npc)
			return self.MindTarget.Value or false
		end,

		GetTimer = function(self: Npc, timerName: string)
			local foundTimer = self.Timers[timerName]

			if not foundTimer then
				self.Timers[timerName] = self.Timer:new(timerName)
				return self.Timers[timerName]
			end

			return foundTimer
		end,

		Exists = function(self: Npc)
			local subject = self.Instance
			return subject and subject.Parent and subject.PrimaryPart and subject.PrimaryPart.Parent
		end,

		LoadPersonality = function(self: Npc)
			local personality = personalities:FindFirstChild(self.Type)
			if not personality then
				return
			end

			self.Personality = require(personality)

			for _, foundModule in ipairs(self.Instance:GetDescendants()) do -- run misc modules
				if not foundModule:IsA("ModuleScript") then
					continue
				end

				local required = require(foundModule)
				required.npc = self

				if not required["OnSpawned"] then
					continue
				end
				required.OnSpawned()
			end

			return self.Personality
		end,

		Place = function(self: Npc, position: Vector3 | CFrame)
			self.Instance.Parent = workspace

			if typeof(position) == "Vector3" then
				self.Instance:PivotTo(CFrame.new(position + Vector3.new(0, 2.5, 0)))
			else
				self.Instance:PivotTo(position * CFrame.new(0, 2.5, 0))
			end

			return self.Instance
		end,

		Run = function(self: Npc)
			npcFunctions.RunNpc(self)
		end,

		Spawn = function(self: Npc, position: Vector3 | CFrame)
			self:Place(position)
			self:Run()

			return self.Instance
		end,

		Destroy = function(self: Npc)
			self.Heartbeat = {}
			self.Janitor:Cleanup()
			self.Instance:Destroy()
			table.remove(npcFunctions.npcs, table.find(npcFunctions.npcs, self))
		end,
	}

	table.insert(npcFunctions.npcs, Npc)

	return Npc
end

return NpcService
