local interact = require(script.Parent.Interact)

local function setLightEnabled(object: Instance, value)
	local lightPart = object.LightPart
	local light = lightPart:FindFirstChildOfClass("PointLight")
		or lightPart:FindFirstChildOfClass("SurfaceLight")
		or lightPart:FindFirstChildOfClass("SpotLight")

	if light then
		light.Enabled = value
	end

	local flare = lightPart:FindFirstChild("LensFlare")
	if flare then
		flare.Enabled = value
	end
end

local module = {
	Unlock = function(object: Instance)
		object:SetAttribute("Locked", false)
		object:RemoveTag("Hackable")
	end,

	Disable = function(object: Instance)
		if object:FindFirstChild("LightPart") then
			setLightEnabled(object, false)
			object:SetAttribute("HackAction", "Enable")
		end
	end,

	Enable = function(object: Instance)
		if object:FindFirstChild("LightPart") then
			setLightEnabled(object, true)
			object:SetAttribute("HackAction", "Disable")
		end
	end,

	Memory_Wipe = function(object: Model)
		local data = require(object.Data)

		data.Dialogue.StartGame = data.StartGame
	end,

	Activate = interact.UseObject,
}

return module
