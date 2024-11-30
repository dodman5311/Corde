local module = {}

local players = game:GetService("Players")
local rs = game:GetService("RunService")
local cs = game:GetService("CollectionService")
local player = players.LocalPlayer

local camera = workspace.CurrentCamera

local range = 20
local fadeSpeed = 0.1

local function Lerp(num, goal, i)
	return num + (goal-num)*i
end

local function fadeLight(image, goal, iteration)
	image.ImageTransparency = math.clamp(goal, 0.5, 1) --Lerp(image.ImageTransparency, math.clamp(goal, 0.5, 1), iteration)
end

local function checkLights()
	local character =  player.Character
	if not character then return end
	
	local ignore = cs:GetTagged("Ignore")
	local lights = cs:GetTagged("Light")
	
	for _,light in ipairs(lights) do
		if not light:FindFirstAncestor("Workspace") then continue end
		
		local lensflare = light:FindFirstChild("LensFlare")
		if not lensflare then continue end
		
		lensflare.AlwaysOnTop = true
		
		local vector, inViewport = camera:WorldToViewportPoint(light.Position)
		if not inViewport then
			fadeLight(lensflare.FlareTexture, 1, fadeSpeed)
			continue 
		end
		
		local cameraPosition = camera.CFrame.Position
        local playerPosition = character:GetPivot().Position
		local distance = (playerPosition - light.Position).Magnitude
		
		if distance > range then 
			fadeLight(lensflare.FlareTexture, 1, fadeSpeed)
			continue 
		end
		
		table.insert(ignore, light)
		table.insert(ignore, character)
		
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Exclude
		rp.FilterDescendantsInstances = ignore
	
		local rayCast = workspace:Raycast(cameraPosition,light.Position - cameraPosition, rp)
		
		if rayCast then 
			fadeLight(lensflare.FlareTexture, 1, fadeSpeed)
			continue 
		end
		
		fadeLight(lensflare.FlareTexture, (distance/range), fadeSpeed)
	end
end

rs.RenderStepped:Connect(function(dt)
	checkLights()
end)

return module
