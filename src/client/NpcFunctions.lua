local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local rng = Random.new()

local client = script.Parent
local acts = require(client.Acts)
local signal = require(ReplicatedStorage.Packages.Signal)

local heartbeat = signal.new()

local module = {
    events = {
        OnStep = function(npc, actions)
            local func = function()
                doActions(npc, actions)
            end
        
            local onBeat = heartbeat:Connect(func)
            npc.Janitor:Add(onBeat, "Disconnect")
        
            return onBeat
        end
    },
    actions = {},
}

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

		local function doAction(...)
			local result = module.actions[action.Function](npc, ...)
			if not action.ReturnEvent then
				return
			end

			module.actions[action.ReturnEvent](npc, npc.Behavior[action.ReturnEvent], result)
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

		task.spawn(doAction, table.unpack(parameters))
	end
end

RunService.Heartbeat:Connect(function()
    if acts:checkAct("Paused") then
        return
    end

	heartbeat:Fire()
end)

return module