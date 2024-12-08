local function setLightEnabled(object:Instance, value)
    local lightPart = object.LightPart
    local light = lightPart:FindFirstChildOfClass("PointLight") or lightPart:FindFirstChildOfClass("SurfaceLight") or lightPart:FindFirstChildOfClass("SpotLight")

    if light then
        light.Enabled = value
    end

    local flare = lightPart:FindFirstChild("LensFlare")
    if flare then
        flare.Enabled = value
    end
end

local module = {
    Unlock = function(object : Instance, point)
        object:SetAttribute("Locked", false)
        object:RemoveTag("Hackable")
    end,

    Disable = function(object : Instance, point)
        if object:FindFirstChild("LightPart") then
            setLightEnabled(object, false)
            object:SetAttribute("HackAction", "Enable")
        end
    end,

    Enable = function(object : Instance, point)
        if object:FindFirstChild("LightPart") then
            setLightEnabled(object, true)
            object:SetAttribute("HackAction", "Disable")
        end
    end,
}



return module