local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local rejoinPlace = {}

local net = require(ReplicatedStorage.Packages.Net)

net:Connect("RejoinPlace", function(player)
	local privateServerCode = TeleportService:ReserveServer(game.PlaceId)
	TeleportService:TeleportToPrivateServer(
		game.PlaceId,
		privateServerCode,
		{ player },
		"",
		nil,
		ReplicatedFirst.LoadingScreen
	)
end)

return rejoinPlace
