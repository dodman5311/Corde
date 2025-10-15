local module = {}

local cs = game:GetService("CollectionService")
local players = game:GetService("Players")
local rs = game:GetService("RunService")
local player = players.LocalPlayer

local camera = workspace.CurrentCamera

local range = 200

local CastTo = require(script.Parent.CastTo)
local lights = cs:GetTagged("Light")

local function Lerp(num, goal, i)
	return num + (goal - num) * i
end

local function fadeLight(light, goal)
	local lightObject = light:FindFirstChild("Light")
	if lightObject and light:GetAttribute("LightType") == "Dynamic" then
		lightObject.Brightness =
			Lerp(lightObject.Brightness, lightObject:GetAttribute("DefaultBrightness") * math.abs(goal - 1), 0.02)
	end

	local lensflare = light:FindFirstChild("LensFlare")
	if not lensflare then
		return
	end

	lensflare.FlareTexture.ImageTransparency = math.clamp(goal, 0.5, 1)
	lensflare.AlwaysOnTop = true
end

local function getLightBrightness()
	for _, light in ipairs(lights) do
		local lightObject = light:FindFirstChild("Light")
		if not lightObject then
			continue
		end

		lightObject:SetAttribute("DefaultBrightness", lightObject.Brightness)
	end
end

local function checkLights()
	local character = player.Character
	if not character then
		return
	end

	local lights = cs:GetTagged("Light")

	for _, light in ipairs(lights) do
		if not light:FindFirstAncestor("Workspace") then
			continue
		end

		local _, inViewport = camera:WorldToViewportPoint(light.Position)
		if not inViewport then
			fadeLight(light, 1)
			continue
		end

		local playerPosition = player.Character:GetPivot().Position
		local v2PlayerPosition = Vector2.new(playerPosition.X, playerPosition.Z)
		local v2LightPosition = Vector2.new(light.Position.X, light.Position.Z)
		local distance = (v2PlayerPosition - v2LightPosition).Magnitude

		if distance > range then
			fadeLight(light, 1)
			continue
		end

		local rp = RaycastParams.new()
		rp.CollisionGroup = "Light"

		if light:GetAttribute("LightType") == "RotatingStatic" then
			light.CFrame *= CFrame.Angles(0, 0, math.rad(-2))
		end

		if light:GetAttribute("LightType") == "Dynamic" and CastTo.checkCast(playerPosition, light.Position, rp) then
			fadeLight(light, 1)
			continue
		end

		fadeLight(light, (distance / range))
	end
end

getLightBrightness()

rs.Heartbeat:Connect(function()
	checkLights()
end)

return module
