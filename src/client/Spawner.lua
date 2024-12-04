local CollectionService = game:GetService("CollectionService")
local module = {}

local client = script.Parent
local NpcService = require(client.NpcService)

function module:SpawnFromSpawner(spawner : Part)
    if spawner:GetAttribute("SpawnType") == "Enemy" then
        NpcService.new(spawner:GetAttribute("ToSpawn"))
    end
end

function module.Init()
    for _,spawner : Part in ipairs(CollectionService:GetTagged("Spawner")) do
        local gui = spawner:FindFirstChildOfClass("SurfaceGui")
        if gui then
            gui:Destroy()
        end

        spawner.Transparency = 1

        module:SpawnFromSpawner(spawner)
    end
end


return module