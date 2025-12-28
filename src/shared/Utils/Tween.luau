local tweenSystem = {}

local TweenService = game:GetService("TweenService")

local function tween(instance, tweenInfo, propertyTable)
	local newTween = TweenService:Create(instance, tweenInfo, propertyTable)
	newTween:Play()
	newTween.Completed:Connect(function()
		task.wait()
		newTween:Destroy()
	end)

	return newTween
end

function tweenSystem.Create(
	instance: Instance | {},
	tweenInfo: TweenInfo,
	propertyTable: {},
	yield: boolean?,
	endingFunction: any?,
	endingState: Enum.PlaybackState?
)
	local createdTween

	if typeof(instance) == "table" then
		for _, v in pairs(instance) do
			createdTween = tween(v, tweenInfo, propertyTable)
		end
	else
		createdTween = tween(instance, tweenInfo, propertyTable)
	end

	if yield then
		createdTween.Completed:Wait()
		if not endingFunction then
			return createdTween
		end

		local state = createdTween.PlaybackState
		if state ~= (endingState or Enum.PlaybackState.Completed) then
			return
		end
		endingFunction()
	elseif endingFunction then
		createdTween.Completed:Connect(function(state)
			if state ~= (endingState or Enum.PlaybackState.Completed) then
				return
			end

			endingFunction()
		end)
	end

	return createdTween
end

return tweenSystem
