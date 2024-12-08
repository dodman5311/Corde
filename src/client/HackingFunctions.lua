local function setLightEnabled(object:Instance, value)
    local light = object:FindFirstChildOfClass("PointLight") or object:FindFirstChildOfClass("SurfaceLight") or object:FindFirstChildOfClass("SpotLight")

    if light then
        light.Enabled = value
    end

    local flare = object:FindFirstChild("LensFlare")
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
        if object:HasTag("Light") then
            setLightEnabled(object, false)
            object:SetAttribute("HackAction", "Enable")
        end
    end,

    Enable = function(object : Instance, point)
        if object:HasTag("Light") then
            setLightEnabled(object, true)
            object:SetAttribute("HackAction", "Disable")
        end
    end,
}



return module