local module = {}

local cs = game:GetService("CollectionService")
local players = game:GetService("Players")
local rs = game:GetService("RunService")
local player = players.LocalPlayer

local camera = workspace.CurrentCamera

local RANGE = 200
local LIGHT_TWEEN_INFO = TweenInfo.new(0.5)
local PROCESS_INTERVAL = 0.25

local CastTo = require(script.Parent.CastTo)
local Util = require(script.Parent.Util)
local lights = cs:GetTagged("Light")

local lastLightCheck = os.clock()

local function turnLightOn(lightObject, fadeGoal)
	local brightnessGoal = lightObject:GetAttribute("DefaultBrightness") * math.abs(fadeGoal - 1)
	if lightObject.Brightness == brightnessGoal then
		return
	end

	lightObject.Enabled = true
	Util.tween(lightObject, LIGHT_TWEEN_INFO, { Brightness = brightnessGoal })
end

local function turnLightOff(lightObject)
	if not lightObject.Enabled then
		return
	end

	Util.tween(lightObject, LIGHT_TWEEN_INFO, { Brightness = 0 }, false, function()
		lightObject.Enabled = false
	end)
end

local function fadeLight(light, goal)
	local lightObject = light:FindFirstChild("Light")
	if lightObject and light:GetAttribute("LightType") == "Dynamic" then
		if goal == 1 then
			turnLightOff(lightObject)
		else
			turnLightOn(lightObject, goal)
		end
	end

	local lensflare = light:FindFirstChild("LensFlare")
	if not lensflare then
		return
	end

	Util.tween(lensflare.FlareTexture, LIGHT_TWEEN_INFO, { ImageTransparency = math.clamp(goal, 0.5, 1) })
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

		if distance > RANGE then
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

		fadeLight(light, 0)
	end
end

getLightBrightness()
--GlobalEvents.React.AreaEntered:Connect(checkLights)

rs.Heartbeat:Connect(function()
	if os.clock() - lastLightCheck > PROCESS_INTERVAL then
		lastLightCheck = os.clock()
		checkLights()
	end
end)

return module
