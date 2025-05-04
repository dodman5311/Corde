local module = {}

function module:GetData(assetName: string)
	local childData: ModuleScript = script:FindFirstChild(assetName)
	if not childData then
		return warn("no stored data by the name of " .. assetName)
	end
	return require(childData)
end

return module
