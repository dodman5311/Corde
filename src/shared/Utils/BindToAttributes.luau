return function(instance: Instance): { [string]: any }
	-- Just wraps the attributes on this instance into a type so
	-- you dont have to write GetAttribute/SetAttribute over and over.
	local t = {}
	setmetatable(t, {
		__index = function(t, key)
			return instance:GetAttribute(key)
		end,
		__newindex = function(t, key, value)
			instance:SetAttribute(key, value)
		end,
	})
	return t :: any
end
