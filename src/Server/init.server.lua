local modules = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(ReplicatedStorage.Packages.Promise)

local function InitModules()
	local inits = {}

	for _, module in script:GetDescendants() do
		if not module:IsA("ModuleScript") then
			continue
		end

		table.insert(
			inits,
			Promise.try(function()
				return require(module)
			end)
				:andThen(function(mod)
					if typeof(mod) ~= "table" then
						return
					end
					if mod.Init then
						mod:Init()
					end

					table.insert(modules, mod)
				end)
				:catch(function(e)
					warn(module.Name .. " Failed to load")
					warn(e)
				end)
		)
	end

	return Promise.allSettled(inits)
end

local function StartModules()
	local starts = {}

	for _, mod in modules do
		if mod.StartGame then
			table.insert(
				starts,
				Promise.try(function()
					mod:StartGame()
				end):catch(warn)
			)
		end
	end

	return Promise.allSettled(starts)
end

Promise.try(InitModules):andThenCall(StartModules):catch(warn)
