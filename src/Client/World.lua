local module = {}

local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

local Client = player.PlayerScripts.Client

local Types = require(ReplicatedStorage.Shared.Types)
local interact = require(Client.Interact)
local pausedScale = require(Client.Scales).new("GamePaused")

function module:pause(pauseIndex: string?)
	workspace:SetAttribute("Paused", pausedScale:Add(pauseIndex))
end

function module:resume(pauseIndex: string?)
	workspace:SetAttribute("Paused", pausedScale:Remove(pauseIndex))
end

local function pauseToggled()
	local isPaused = workspace:GetAttribute("Paused")

	if isPaused then
		for _, object in ipairs(workspace:GetDescendants()) do
			if object:IsA("ParticleEmitter") then
				object.TimeScale = 0
			end

			if object:IsA("BasePart") and not object.Anchored then
				object.Anchored = true
				object:SetAttribute("ToBeUnanchored", true)
			end
		end
	else
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
end

workspace:GetAttributeChangedSignal("Paused"):Connect(pauseToggled)

local function loadContainers(layer: Types.LayerData)
	for _, container in ipairs(CollectionService:GetTagged("Container")) do
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

local function loadObjects(layer: Types.LayerData)
	for _, object: Model in ipairs(CollectionService:GetTagged("Interactable")) do
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

local function loadLayer(layer: Types.LayerData)
	print("AttemptLoad")
	if not layer then
		return
	end

	loadContainers(layer)
	loadObjects(layer)
end

function module.StartGame(saveData: Types.GameState?)
	workspace:SetAttribute("CurrentLayerIndex", saveData and saveData.CurrentLayerIndex or "Demo")

	for _, shadowPart: BasePart in ipairs(CollectionService:GetTagged("ShadowPart")) do
		shadowPart.Transparency = -math.huge
		shadowPart.Material = Enum.Material.ForceField
	end

	loadLayer(saveData and saveData.Layers[saveData.CurrentLayerIndex])

	workspace:SetAttribute("StartTime", os.clock())

	if saveData then
		workspace:SetAttribute("PlayTime", saveData.PlayTime)
	end
end

function module.Init()
	Lighting.Ambient = Color3.new()
end

RunService.Heartbeat:Connect(function()
	if workspace:GetAttribute("Paused") then
		return
	end

	for _, item in ipairs(CollectionService:GetTagged("PhysicsItem")) do -- Process Physics
		item.Orientation = Vector3.new(0, item.Orientation.Y, 0)

		if
			item.AssemblyLinearVelocity == Vector3.new(0, 0, 0)
			and item.AssemblyAngularVelocity == Vector3.new(0, 0, 0)
		then
			continue
		end

		item.AssemblyLinearVelocity /= 1 + item.Mass
		item.AssemblyAngularVelocity /= 1 + item.Mass

		if item.AssemblyLinearVelocity.Magnitude <= 0.25 then
			item.AssemblyLinearVelocity = Vector3.zero
		end

		if item.AssemblyAngularVelocity.Magnitude <= 0.25 then
			item.AssemblyAngularVelocity = Vector3.zero
		end
	end
end)

GuiService.MenuOpened:Connect(function()
	StarterGui:SetCore("ResetButtonCallback", false)

	module:pause("RobloxMenu")
end)

GuiService.MenuClosed:Connect(function()
	module:resume("RobloxMenu")
end)

return module
