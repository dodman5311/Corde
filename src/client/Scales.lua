local ReplicatedStorage = game:GetService("ReplicatedStorage")
local signal = require(ReplicatedStorage.Packages.Signal)

export type Scale = {
	Contents: {},
	Threshold: number, -- 1 Default
	Check: (self: Scale) -> boolean,
	Add: (self: Scale, index: string | number?, value: any?) -> boolean,
	Remove: (self: Scale, index: string | number?) -> boolean,
	Gained: signal.Signal,
	Lost: signal.Signal,
}

local scales = {
	activeScales = {},
}

local function getSize(list: {})
	local count = 0
	for _, _ in pairs(list) do
		count += 1
	end
	return count
end

local function checkForSignal(scale: Scale)
	local isOverThreshold = scale:Check()
	if isOverThreshold then
		scale.Gained:Fire()
	else
		scale.Lost:Fire()
	end

	return isOverThreshold
end

function scales.new(index: string?): Scale
	local scale: Scale = {
		Contents = {},
		Threshold = 1,
		Check = function(self: Scale)
			local weight = getSize(self.Contents)
			local isOverThreshold = weight >= self.Threshold

			return isOverThreshold
		end,
		Add = function(self: Scale, index: string | number?, value: any?)
			if index then
				self.Contents[index] = value or true
			else
				table.insert(self.Contents, value or true)
			end

			return checkForSignal(self)
		end,
		Remove = function(self: Scale, index: string | number)
			if tonumber(index) then
				table.remove(self.Contents, index)
			else
				self.Contents[index] = nil
			end

			return checkForSignal(self)
		end,

		Gained = signal.new(),
		Lost = signal.new(),
	}

	if index then
		scales.activeScales[index] = scale
	end

	return scale
end

return scales
