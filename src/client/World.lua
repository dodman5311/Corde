local module = {}

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local Client = player.PlayerScripts.Client

local acts = require(Client.Acts)
local globalInputService = require(Client.GlobalInputService)

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

function module.StartGame()
	for _, shadowPart: BasePart in ipairs(CollectionService:GetTagged("ShadowPart")) do
		shadowPart.Transparency = 0.747
		shadowPart.Material = Enum.Material.ForceField
	end
end

function module.Init()
	Lighting.Ambient = Color3.new()
end

RunService.Heartbeat:Connect(function()
	if acts:checkAct("Paused") then
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

globalInputService.CreateNewInput("PauseGame", function(state)
	if state ~= Enum.UserInputState.Begin then
		return
	end

	if acts:checkAct("Paused") then
		module:resume()
	else
		module:pause()
	end
end, Enum.KeyCode.P)

return module
