local module = {
    Unlock = function(object : Model, point)
        object:SetAttribute("Locked", false)
        object:RemoveTag("Hackable")
    end
        
}

return module