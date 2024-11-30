local ReplicatedStorage = game:GetService("ReplicatedStorage")

local client = script.Parent
local personalities = client.NpcPersonalities
local timer = require(client.Timer)
local janito = require(ReplicatedStorage.Packages.Janitor)

export type Npc = {
    Name : string,
    Instance : Instance,
    Personality : table,
    MindData : table, -- extra data the npc might need
    MindState : string,
    MindTarget : any,

    Timer :table,
    Timers : table,
    Acts : table,
    Janitor : table,


}

local NpcService = {}

--// Values
local NpcEvents = {}
local onBeat = {}
local Npcs = {}

local rng = Random.new()

function NpcService.new(npcName : string)
    local npcModel = ReplicatedStorage.Assets.Npcs:FindFirstChild(npcName, true)
    if not npcModel then
        warn(`No NPC model by the name of {npcName} was found.`)
        return
    end

    local newNpcModel = npcModel:Clone()
    local Npc : Npc = {
        Name = npcName,
        Instance = npcModel,
        Personality = require(personalities:FindFirstChild(npcName)),
        MindData = {},
        MindState = "Idle",
       
        Timer = timer:newQueue(),
        Janitor = 
    }

    
end

return NpcService