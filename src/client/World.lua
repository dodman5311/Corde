local module = {}

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local Client = player.PlayerScripts.Client
local Layers = ReplicatedStorage.Layers

local NpcService = require(script.Parent.NpcService)
local Spawners = require(script.Parent.Spawners)
local Types = require(ReplicatedStorage.Shared.Types)
local acts = require(Client.Acts)
local interact = require(Client.Interact)

function module:pause()
	if acts:checkAct("Paused") then
		return
	end

	acts:createAct("Paused")

	for _, object in ipairs(workspace:GetDescendants()) do
		if object:IsA("ParticleEmitter") then
			object.TimeScale = 0
		end

		if object:IsA("BasePart") and not object.Anchored then
			object.Anchored = true
			object:SetAttribute("ToBeUnanchored", true)
		end
	end
end

function module:resume()
	if not acts:checkAct("Paused") then
		return
	end

	acts:removeAct("Paused")

	for _, object in ipairs(workspace:GetDescendants()) do
		if object:IsA("ParticleEmitter") then
			object.TimeScale = 1
		end

		if object:IsA("BasePart") and object:GetAttribute("ToBeUnanchored") then
			object.Anchored = false
			object:SetAttribute("ToBeUnanchored", false)
		end
	end
end

local function checkInLayer(object, layerKey)
	if layerKey == workspace:GetAttribute("CurrentLayerKey") then
		return object:FindFirstAncestor("Map")
	else
		return object:FindFirstAncestor(layerKey)
	end
end

local function loadContainers(layer: Types.LayerData, key: string)
	for _, container in ipairs(CollectionService:GetTagged("Container")) do
		if not checkInLayer(container, key) then
			continue
		end

		local foundMatch = false
		for _, containerData in ipairs(layer.Containers) do
			if containerData.Position == container:GetPivot().Position then
				foundMatch = true
			else
				continue
			end

			local containerContents = require(container.Container)

			table.clear(containerContents)
			for _, item in ipairs(containerData.Contents) do
				table.insert(containerContents, item)
			end
		end

		if not foundMatch then
			container:Destroy()
		end
	end
end

local function loadObjects(layer: Types.LayerData, key: string)
	for _, object: Model in ipairs(CollectionService:GetTagged("Interactable")) do
		if not checkInLayer(object, key) then
			continue
		end

		for _, objectData in ipairs(layer.Objects) do
			if (objectData.Position - object:GetPivot().Position).Magnitude > 0.05 then
				continue
			end

			object:SetAttribute("Locked", objectData.Locked)

			for _, tag in ipairs(object:GetTags()) do
				object:RemoveTag(tag)
			end

			for _, tag in ipairs(objectData.Tags) do
				object:AddTag(tag)
			end

			if objectData.Used then
				interact.UseObject(object, true)
			end
		end
	end
end

local function loadLayerAssets()
	local layerKey = workspace:GetAttribute("CurrentLayerKey") or ""
	local layerFolder = Layers:FindFirstChild(layerKey)
	if not layerFolder then
		return
	end

	for _, layerAsset in ipairs(layerFolder:GetChildren()) do
		layerAsset.Parent = workspace.Map
	end
end

local function storeCurrentLayer()
	local layerKey = workspace:GetAttribute("CurrentLayerKey") or ""
	local layerFolder = Layers:FindFirstChild(layerKey)
	if not layerFolder then
		return
	end

	for _, layerAsset in ipairs(workspace.Map:GetChildren()) do
		layerAsset.Parent = layerFolder
	end
end

function module.LoadLayer(layerKey: string)
	print("AttemptLoad")

	NpcService:StopAll() -- stop npcs from processing

	storeCurrentLayer()
	workspace:SetAttribute("CurrentLayerKey", layerKey)

	Spawners:SpawnLayerNpcs(layerKey)

	loadLayerAssets() -- load the layer then run the Npcs
	NpcService:RunInWorkspace()
end

local function loadLayersFromData(layers)
	if not layers then
		return
	end

	for key, layerData: Types.LayerData in pairs(layers) do
		loadContainers(layerData, key)
		loadObjects(layerData, key)
	end
end

function module.StartGame(saveData: Types.GameState?)
	for _, shadowPart: BasePart in ipairs(CollectionService:GetTagged("ShadowPart")) do
		shadowPart.Transparency = -math.huge
		shadowPart.Material = Enum.Material.ForceField
	end

	local layerKey = saveData and saveData.CurrentLayerKey or "Demo"
	local layers = saveData and saveData.Layers
	loadLayersFromData(layers)
	module.LoadLayer(layerKey)

	workspace:SetAttribute("StartTime", os.clock())

	if saveData then
		workspace:SetAttribute("PlayTime", saveData.PlayTime)
	end
end

function module.Init()
	Lighting.Ambient = Color3.new()
end

RunService.Heartbeat:Connect(function()
	if acts:checkAct("Paused") then
		return
	end

	for _, itemObject in ipairs(CollectionService:GetTagged("PhysicsItem")) do -- Process Physics
		itemObject.Orientation = Vector3.new(0, itemObject.Orientation.Y, 0)

		if
			itemObject.AssemblyLinearVelocity == Vector3.new(0, 0, 0)
			and itemObject.AssemblyAngularVelocity == Vector3.new(0, 0, 0)
		then
			continue
		end

		itemObject.AssemblyLinearVelocity /= 1 + itemObject.Mass
		itemObject.AssemblyAngularVelocity /= 1 + itemObject.Mass

		if itemObject.AssemblyLinearVelocity.Magnitude <= 0.25 then
			itemObject.AssemblyLinearVelocity = Vector3.zero
		end

		if itemObject.AssemblyAngularVelocity.Magnitude <= 0.25 then
			itemObject.AssemblyAngularVelocity = Vector3.zero
		end
	end
end)

-- globalInputService.CreateInputAction("PauseGame", function(state)
-- 	if state ~= Enum.UserInputState.Begin then
-- 		return
-- 	end

-- 	if acts:checkAct("Paused") then
-- 		module:resume()
-- 	else
-- 		module:pause()
-- 	end
-- end, Enum.KeyCode.P)

return module
