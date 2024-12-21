local module = {}

local players = game:GetService("Players")
local rs = game:GetService("RunService")
local cs = game:GetService("CollectionService")
local player = players.LocalPlayer

local camera = workspace.CurrentCamera

local range = 20

local function Lerp(num, goal, i)
	return num + (goal - num) * i
end

local function fadeLight(light, goal)
	local lightObject = light:FindFirstChild("Light")
	if lightObject and light:GetAttribute("LightType") == "Dynamic" then
		lightObject.Brightness =
			Lerp(lightObject.Brightness, lightObject:GetAttribute("DefaultBrightness") * math.abs(goal - 1), 0.01)
	end

	local lensflare = light:FindFirstChild("LensFlare")
	if not lensflare then
		return
	end

	lensflare.FlareTexture.ImageTransparency = math.clamp(goal, 0.5, 1)
	lensflare.AlwaysOnTop = true
end

local function getLightBrightness()
	local lights = cs:GetTagged("Light")

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

	local ignore = cs:GetTagged("Ignore")
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

		if
			light:GetAttribute("LightType") == "Dynamic"
			and workspace:Raycast(playerPosition, light.Position - playerPosition, rp)
		then
			fadeLight(light, 1)
			continue
		end

		fadeLight(light, (distance / range))
	end
end

getLightBrightness()

rs.RenderStepped:Connect(function()
	checkLights()
end)

return module
