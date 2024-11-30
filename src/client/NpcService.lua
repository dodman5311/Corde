local ReplicatedStorage = game:GetService("ReplicatedStorage")

local client = script.Parent
local personalities = client.NpcPersonalities
local timer = require(client.Timer)
local janitor = require(ReplicatedStorage.Packages.Janitor)
local acts = require(client.Acts)
local npcFunctions = require(client.NpcFunctions)
local signal = require(ReplicatedStorage.Packages.Signal)

export type Npc = {
    Name : string,
    Instance : Instance,
    Personality : {},
	MindData : {}, -- extra data the npc might need
    MindState : string,
    MindTarget : ObjectValue,

	Timer : {new : (self : any) -> nil}?,
	Timers : {},
	Acts : {},
	Janitor : any,
    OnDied : any?,

    Spawn : (Npc : Npc, Position : Vector3) -> Instance,
    
    IsState : (Npc : Npc, State : string) -> boolean,
    GetState : (Npc : Npc) -> string,
    GetTarget : (Npc : Npc) -> any?,
	GetTimer : (Npc : Npc, TimerName : string) -> {},

    Exists : (Npc : Npc) -> boolean,

    Place : (Npc : Npc, Position : Vector3) -> Instance,
    Run : (Npc : Npc) -> nil,
    LoadPersonality : (Npc : Npc) -> nil,
}

local NpcService = {}

--// Values
local NpcEvents = {}
local onBeat = {}
local Npcs = {}

local rng = Random.new()

function NpcService.new(npcName : string) : Npc
   

    local npcModel = ReplicatedStorage.Assets.Npcs:FindFirstChild(npcName, true)
    if not npcModel then
        warn(`No NPC model by the name of {npcName} was found.`)
        return
    end

    local targetValue = Instance.new("ObjectValue")
    targetValue.Parent = npcModel
    targetValue.Name = "Target"

    local newNpcModel = npcModel:Clone()
    local Npc : Npc = {
        Name = npcName,
        Instance = npcModel,
        Personality = require(personalities:FindFirstChild(npcName)),
        MindData = {},
        MindState = "Idle",
        MindTarget = targetValue,
       
        Timer = timer:newQueue(),
        Timers = {},
        Acts = acts:new(),
        Janitor = janitor.new(),
		
		OnDied = signal.new(),
		
        IsState = function(self : Npc, state : string)
            return self.Instance:GetAttribute("State") == state
        end,

        GetState = function(self : Npc)
            return self.Instance:GetAttribute("State")
        end,

        GetTarget = function(self : Npc)
            local targetValue = self.Instance:FindFirstChild("Target")
		    if not targetValue then
		    	return
		    end

		    local target = targetValue.Value

		    return target
        end,

        GetTimer = function(self : Npc, timerName : string)
            local foundTimer = self.Timers[timerName]

	    	if not foundTimer then
		    	self.Timers[timerName] = self.Timer:new(timerName)
		    	return self.Timers[timerName]
		    end

		    return foundTimer
        end,
       
        Exists = function(self : Npc)
            local subject = self.Instance
		    return subject and subject.Parent and subject.PrimaryPart and subject.PrimaryPart.Parent
        end,

        LoadPersonality = function(self : Npc)
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

        Place = function(self : Npc, position : Vector3)
            self.Instance.Parent = workspace

            if typeof(position) == "Vector3" then
                self.Instance:PivotTo(CFrame.new(position + Vector3.new(0, 2.5, 0)))
            else
                self.Instance:PivotTo(position * CFrame.new(0, 2.5, 0))
            end

		    return self.Instance
        end,

        Run = function(self : Npc)
            npcFunctions.RunNpc(self)
        end,

        Spawn = function(self : Npc, position : Vector3)
            self:Place(position)
            self:Run()

            return self.Instance
        end,
    }

    return Npc
end

function NpcService:GetNpcFromModel(model)
	for _, npc in ipairs(Npcs) do
		if npc.Instance == model then
			return npc
		end
	end
end

return NpcService